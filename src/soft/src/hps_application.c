/*****************************************************************************************
 * HEIG-VD
 * Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
 * School of Business and Engineering in Canton de Vaud
 *****************************************************************************************
 * REDS Institute
 * Reconfigurable Embedded Digital Systems
 *****************************************************************************************
 *
 * File                 : hps_application.c
  * Author              : Guillaume Gonin, Urs Behrmann
 * Date                 : 5.11.2024
 *
 * Context              : ARE lab
 *
 *****************************************************************************************
 * Brief: Conception d'une interface simple sur le bus Avalon avec la carte DE1-SoC
 *
 *****************************************************************************************
 * Modifications :
 * Ver    Date        Student      Comments
 * 1      5.11.2024   GoninG       Starter routine done (not tested)
 * 2      5.11.2024   GoninG       Loop routine done (not tested)
 * 3      8.11.2024   GoninG       Updated the way we use lp36_wr and read lp36_status (not tested)
 * 4      8.11.2024   GoninG       Removed some bugs after test
 * 5      9.11.2024   GoninG       Code refactored with macro
 * 6      11.11.2024  GoninG       Debuging and testing, Bugs fixed
 * 7      12.11.2024  GoninG       Shifting working the right way (hopefully)
 * 8      12.11.2024  BehrmannU    Refactoring after validation
*****************************************************************************************/
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include "axi_lw.h"

int __auto_semihosting;

// Base address
#define INTERFACE_BASE_ADD            ((AXI_LW_HPS_FPGA_BASE_ADD) + 0x010000)

// ACCESS MACROS
#define INTERFACE_REG(_x_)            (*(volatile uint32_t *)(INTERFACE_BASE_ADD + _x_)) // _x_ is an offset with respect to the base address

// Address Plan
#define CONST_AXI_LW_OFF               0x0
#define CONST_AXI_LW_MASK              0xFFFFFFFF //32 bits

#define CONST_INT_OFF                  0x0
#define CONST_INT_MASK                 0xFFFFFFFF //32 bits
#define LEDS_OFF                       0x4
#define LEDS_MASK                      0x3FF //10 bits
#define SWITCHS_OFF                    0x8
#define SWITCHS_MASK                   0x3FF //10 bits
#define KEYS_OFF                       0xC
#define KEYS_MASK                      0xF //4 bits
#define LP36_STATUS_OFF                0x10
#define LP36_STATUS_MASK               0x1 //2 bits
#define LP36_WR_OFF                    0x10
#define LP36_WR_MASK                   0x2 //1 bits
#define LP36_SEL_OFF                   0x14
#define LP36_SEL_MASK                  0x3 //2 bits, technically 4 bits but only 2 used
#define LP36_DATA_OFF                  0x18
#define LP36_DATA_SEC1_MASK            0x3FFFFFFF //30 bits
#define LP36_DATA_SEC2_MASK            0x3FFFFFFF //30 bits
#define LP36_DATA_LINE_MASK            0xFFFFFFFF //32 bits
#define LP36_DATA_SQUA_MASK            0x1FFFFFF //25 bits

#define LEDS_PATTERN_A               0b10101010101010101010101010101010
#define LEDS_PATTERN_B               0b01010101010101010101010101010101
#define LEDS_PATTERN_C               0b11111111111111111111111111111111

// READ / WRITE Macros
#define READ_CONST_AXI_LW()            (AXI_LW_REG(CONST_AXI_LW_OFF) & CONST_AXI_LW_MASK) //using mask isn't useful because our interface do it aswell but it stay a good habit
#define READ_CONST_INT()               (INTERFACE_REG(CONST_INT_OFF) & CONST_INT_MASK)
#define READ_KEYS()                    (~(INTERFACE_REG(KEYS_OFF) & KEYS_MASK)) //inverse keys value because active low
#define READ_SWITCHS()                 (INTERFACE_REG(SWITCHS_OFF) & SWITCHS_MASK)
#define READ_LP36_STATUS()             (INTERFACE_REG(LP36_STATUS_OFF) & LP36_STATUS_MASK)
#define READ_LP36_WR()                 ((INTERFACE_REG(LP36_WR_OFF) & LP36_WR_MASK) >> ((int)(LP36_WR_MASK/2))) // SHR to get the bit on bit 0
#define READ_LP36_DATA()               (INTERFACE_REG(LP36_DATA_OFF) & 0xFFFFFFFF)
#define WRITE_LEDS(_x_)                (INTERFACE_REG(LEDS_OFF) = ((_x_) & LEDS_MASK)) // _x_is an 32 bits value
#define WRITE_LP36_SEL(_x_)            (INTERFACE_REG(LP36_SEL_OFF) = ((_x_) & LP36_SEL_MASK))
#define WRITE_LP36_DATA(_x_, _MASK_)   (INTERFACE_REG(LP36_DATA_OFF) = ((_x_) & _MASK_)) // _MASK_ is the mask to apply, depends on lp36_sel

// Local use
#define VALID_CONFIG_STATUS            0x1
#define SW7_0_MASK                     0xFF
#define KEY1_0_MASK                    0x3
#define KEY2_MASK                      0x4
#define KEY3_MASK                      0x8
#define SQUARE_LINE_SIZE               5
#define SQUARE_FIRST_LINE_MASK		   0x1F
#define SQUARE_SECOND_LINE_MASK		   0xE0

#define CANT_WRITE_SEL                 ((READ_LP36_WR() == 1) || (READ_LP36_STATUS() == 0)) //if lp36_wr == 1 or FPGA thrown an error we can't write

enum LP36Select {
    SECONDARY_1 = 0,
    SECONDARY_2 = 1,
    TWO_LINE = 2,
    SQUARE = 3
};

void all_max10_leds_off(void) {
    int select_vals[] = {
        SECONDARY_1,
        SECONDARY_2,
        TWO_LINE,
        SQUARE
        };

    int mask_vals[] = {
        LP36_DATA_SEC1_MASK,
        LP36_DATA_SEC2_MASK,
        LP36_DATA_LINE_MASK,
        LP36_DATA_SQUA_MASK
        };

    for (int i = 0; i < 4; ++i) {

    	while (CANT_WRITE_SEL);

    	WRITE_LP36_SEL(select_vals[i]);

        WRITE_LP36_DATA(CONST_INT_OFF, mask_vals[i]);
    }
}

int main(void){
    
    printf("Laboratoire: Conception d'une interface simple \n");
    
    /* Au démarrage, le programme doit remplir les conditions suivantes :
        1. Vérifier que le statut de la carte Max10_leds est une configuration valide. Sinon
            afficher un message d’erreur dans la console ARM-DS et quitter le programme.
        2. Les 10 leds DE1-SoC sont éteintes.
        3. Toutes les leds de la carte Max10_leds sont éteintes (leds secondes, 2 lignes
            de leds, carré de leds).
        4. Afficher la constante ID du bus AXI lightweight HPS-to-FPGA au format
            hexadécimal dans la console de ARM-DS.
        5. Afficher la constante ID de votre interface sur le bus Avalon au format
            hexadécimal dans la console de ARM-DS. */
        
    int config_status = READ_LP36_STATUS();
    if(config_status != VALID_CONFIG_STATUS) {
        printf("MAX10 Config status invalid: %x\n", config_status);
        return -1;
    }

    // Reset all leds of Cyclone V and Max10
    WRITE_LEDS(0);
    all_max10_leds_off();

    // Output the constant values of the Avalon bus and our interface
    printf("AXI LW Const32: %x\n", (unsigned)READ_CONST_AXI_LW());
    printf("Our interface Const32: %x\n", (unsigned)READ_CONST_INT());

	int offset = 0;
    int last_key2_val = 0;
    
    while (1) {
        /*  Ensuite pendant l’exécution du programme, à tout instant les actions suivantes doivent
        être respectées :
        1. Copie de la valeur des 10 interrupteurs (SW) sur les 10 leds de la DE1-SoC.
        2. L’état de SW9-8 permet de sélectionner les leds à mettre à jour sur la carte
            Max10_leds :
            - SW9-8 = 00 : Leds secondes DS30.. .1.
            - SW9-8 = 01 : Leds secondes DS60...31.
            - SW9-8 = 10 : Les 2 lignes de leds DL.
            - SW9-8 = 11 : Le carré des leds DM.
        3. L’état de KEY1-0 permet de définir la valeur affichée sur les leds sélectionnés
            de la carte Max10_leds :
            - KEY1-0 = 00 : Copie de la valeur des 8 interrupteurs (SW0 to SW7) sur
                les poids faibles. Les leds de poids forts sont éteintes.
            - KEY1-0 = 01 : Afficher la valeur 1010…1010.
            - KEY1-0 = 10 : Afficher la valeur 0101…0101.
            - KEY1-0 = 11 : Afficher la valeur 1111…1111.
        4. Pression sur KEY2 :
            Lors de la sélection du carré des leds DM ainsi que la copie de la
            valeur des 8 interrupteurs : Faire décaler d’une ligne vers le bas la
            valeur des 8 interrupteurs affichés sur le carré des leds DM.
        5. Pression sur KEY3 :
            Eteindre toutes les leds de la carte Max10_leds. */

		// check if the MAX10 is always connected and the good status
       	config_status = READ_LP36_STATUS();
		if(READ_LP36_STATUS() != VALID_CONFIG_STATUS) {
			printf("MAX10 Config status invalid: %x\n", config_status);
			return -1;
		}

        // Read the switches and keys
        int switches = READ_SWITCHS();
        int keys = READ_KEYS();

        // Copy the switches to the leds
        WRITE_LEDS(switches);

        // Check if we need to turn off all the leds
        if (keys & KEY3_MASK) {
        	all_max10_leds_off();
        	continue;
        }

        // Select the leds to update
        int select_mode = (switches >> 8) & 0x3;
        int mask_to_use, sel_value;

        switch (select_mode) {
            case 0:
                mask_to_use = LP36_DATA_SEC1_MASK;
                sel_value = SECONDARY_1;
                break;
            case 1:
                mask_to_use = LP36_DATA_SEC2_MASK;
                sel_value = SECONDARY_2;
                break;
            case 2:
                mask_to_use = LP36_DATA_LINE_MASK;
                sel_value = TWO_LINE;
                break;
            case 3:
                mask_to_use = LP36_DATA_SQUA_MASK;
                sel_value = SQUARE;
                break;
        }

        // Write the selected leds
        do {
            WRITE_LP36_SEL(sel_value);
        } while (CANT_WRITE_SEL);

        // Write the data to the leds
        int display_pattern = keys & KEY1_0_MASK;
        int switches_low = switches & SW7_0_MASK;
        int value_to_write = 0;

        if (display_pattern == 0) {
            if (mask_to_use == LP36_DATA_SQUA_MASK) {
                // Isolate the first and second line values from switches_low
                int first_line_value = switches_low & SQUARE_FIRST_LINE_MASK;    // Extracts bits for the first line (SW0 to SW4)
                int second_line_value = (switches_low & SQUARE_SECOND_LINE_MASK) >> 5; // Extracts bits for the second line (SW5 to SW9)

                // Shift the isolated values to their correct positions based on offset
                int shifted_first_line = first_line_value << (SQUARE_LINE_SIZE * offset); // Shift first line to correct position
                int shifted_second_line = second_line_value << (SQUARE_LINE_SIZE * ((offset + 1) % SQUARE_LINE_SIZE)); // Shift second line to next position

                // Combine both shifted values into square_shifted_value
                value_to_write = shifted_first_line | shifted_second_line;
            } else {
                value_to_write = switches_low;
            }
        } else if (display_pattern == 1) {
            value_to_write = LEDS_PATTERN_A;
        } else if (display_pattern == 2) {
            value_to_write = LEDS_PATTERN_B;
        } else if (display_pattern == 3) {
            value_to_write = LEDS_PATTERN_C;
        }

        // Write the value to the leds of the Max10
        WRITE_LP36_DATA(value_to_write, mask_to_use);

        // Check if we need to shift the square
        if ((keys & KEY2_MASK) && display_pattern == 0 && mask_to_use == LP36_DATA_SQUA_MASK && !last_key2_val) {
            offset = (offset + 1) % SQUARE_LINE_SIZE;
        }
        last_key2_val = keys & KEY2_MASK ? 1 : 0;
    }

    return 0;
}
