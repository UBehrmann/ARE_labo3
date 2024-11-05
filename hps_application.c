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
  * Author              : Guillaume Gonin
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
 *
*****************************************************************************************/
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include "axi_lw.h"

int __auto_semihosting;

// Base address
#define INTERFACE_BASE_ADD   ((AXI_LW_HPS_FPGA_BASE_ADD) + 0x01000000)

// ACCESS MACROS
#define INTERFACE_REG(_x_)   *(volatile uint32_t *)(INTERFACE_BASE_ADD + _x_) // _x_ is an offset with respect to the base address

// Address Plan
#define CONST_AXI_LW_OFF      0x0
#define CONST_AXI_LW_MASK     0xFFFFFFFF //32 bits

#define CONST_INT_OFF         0x0
#define CONST_INT_MASK        0xFFFFFFFF //32 bits
#define LEDS_OFF              0x4
#define LEDS_MASK             0x3FF //10 bits
#define SWITCHS_OFF           0x8
#define SWITCHS_MASK          0x3FF //10 bits
#define KEYS_OFF              0xC
#define KEYS_MASK             0xF //4 bits
#define LP36_STATUS_OFF       0x10
#define LP36_STATUS_MASK      0x3 //2 bits
#define LP36_SEL_OFF          0x14
#define LP36_SEL_MASK         0x3 //2 bits, technically 4 bits but only 2 used
#define LP36_SEL_SECOND1      0x0
#define LP36_SEL_SECOND2      0x1
#define LP36_SEL_2LINE        0x2
#define LP36_SEL_SQUARE       0x3
#define LP36_DATA_OFF         0x18
#define LP36_DATA_SEC1_MASK   0x3FFFFFFF //30 bits
#define LP36_DATA_SEC2_MASK   0x3FFFFFFF //30 bits
#define LP36_DATA_LINE_MASK   0xFFFFFFFF //32 bits
#define LP36_DATA_SQUA_MASK   0x1FFFFFF //25 bits
#define LP36_WR_OFF           0x1C
#define LP36_WR_MASK          0x1 //1 bits

//Local use
#define VALID_CONFIG_STATUS   0x01
#define SW7_0_MASK            0xFF
#define KEY1_0_MASK           0x3
#define KEY2_MASK             0x4
#define KEY3_MASK             0x8
#define SQUARE_LINE_SIZE      5

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
        
    //1.
    int val, buf, maskToUse;
    val = INTERFACE_REG(LP36_STATUS_OFF) & LP36_STATUS_MASK; //using mask isn't useful because our interface do it aswell but it stay a good habit
    if(val != VALID_CONFIG_STATUS) {
        printf("MAX10 Config status:%x\n", val);
        return -1;
    }

    //2.
    INTERFACE_REG(LEDS_OFF) = 0 & LEDS_MASK;

    //3
    INTERFACE_REG(LP36_SEL_OFF) = LP36_SEL_SECOND1 & LP36_SEL_MASK;
    INTERFACE_REG(LP36_DATA_OFF) = 0 & LP36_DATA_SEC1_MASK;
    INTERFACE_REG(LP36_WR_OFF) = LP36_WR_MASK;

    INTERFACE_REG(LP36_SEL_OFF) = LP36_SEL_SECOND2 & LP36_SEL_MASK;
    INTERFACE_REG(LP36_DATA_OFF) = 0 & LP36_DATA_SEC2_MASK;
    INTERFACE_REG(LP36_WR_OFF) = LP36_WR_MASK;

    INTERFACE_REG(LP36_SEL_OFF) = LP36_SEL_2LINE & LP36_SEL_MASK;
    INTERFACE_REG(LP36_DATA_OFF) = 0 & LP36_DATA_LINE_MASK;
    INTERFACE_REG(LP36_WR_OFF) = LP36_WR_MASK;

    INTERFACE_REG(LP36_SEL_OFF) = LP36_SEL_SQUARE & LP36_SEL_MASK;
    INTERFACE_REG(LP36_DATA_OFF) = 0 & LP36_DATA_SQUA_MASK;
    INTERFACE_REG(LP36_WR_OFF) = LP36_WR_MASK;

    //4
    val = AXI_LW_REG(CONST_AXI_LW_OFF) & CONST_AXI_LW_MASK;
    printf("AXI LW Const32:%x\n", val);

    //5
    val = INTERFACE_REG(CONST_INT_OFF) & CONST_INT_MASK;
    printf("Our interface Const32:%x\n", val);
    
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

        //1
        val = INTERFACE_REG(SWITCHS_OFF) & SWITCHS_MASK;
        INTERFACE_REG(LEDS_OFF) = val & LEDS_MASK;

        //2
        val = (val >> 9); //slide SW8 on bit 0
        switch (val)
        {
        case 0:
            maskToUse = LP36_DATA_SEC1_MASK;
            buf = 0;
            break;
        case 1:
            maskToUse = LP36_DATA_SEC2_MASK;
            buf = 1;
        case 2:
            maskToUse = LP36_DATA_LINE_MASK;
            buf = 2;
        case 3:
            maskToUse = LP36_DATA_SQUA_MASK;
            buf = 3;
        }
        INTERFACE_REG(LP36_SEL_OFF) = buf & LP36_SEL_MASK;

        //3
        val = (INTERFACE_REG(KEYS_OFF) & KEYS_MASK) & KEY1_0_MASK;
        buf = (INTERFACE_REG(SWITCHS_OFF) & SWITCHS_MASK) & SW7_0_MASK;
        if(val == 0) INTERFACE_REG(LP36_DATA_OFF) = (INTERFACE_REG(LP36_DATA_OFF) & (~SW7_0_MASK)) | (buf & maskToUse); //to keep shifted values and change only the 8 relevant bits
        else if (val == 1) INTERFACE_REG(LP36_DATA_OFF) = 0b10101010101010101010101010101010 & maskToUse;
        else if (val == 2) INTERFACE_REG(LP36_DATA_OFF) = 0b01010101010101010101010101010101 & maskToUse;
        else if (val == 3) INTERFACE_REG(LP36_DATA_OFF) = 0b11111111111111111111111111111111 & maskToUse;

        INTERFACE_REG(LP36_WR_OFF) = LP36_WR_OFF;

        //4
        buf = (INTERFACE_REG(KEYS_OFF) & KEYS_MASK) & KEY2_MASK;
        if((buf != 0) && (val == 0) && (maskToUse == LP36_DATA_SQUA_MASK)) { //if copy switch mode and square mode
            INTERFACE_REG(LP36_DATA_OFF) = INTERFACE_REG(LP36_DATA_OFF) << SQUARE_LINE_SIZE;
            INTERFACE_REG(LP36_WR_OFF) = LP36_WR_OFF;
        }

        //5
        val = (INTERFACE_REG(KEYS_OFF) & KEYS_MASK) & KEY3_MASK;
        if(val != 0){
            INTERFACE_REG(LP36_SEL_OFF) = 0 & LP36_SEL_MASK;
            INTERFACE_REG(LP36_DATA_OFF) = 0 & LP36_DATA_SEC1_MASK;
            INTERFACE_REG(LP36_WR_OFF) = LP36_WR_OFF;

            INTERFACE_REG(LP36_SEL_OFF) = 1 & LP36_SEL_MASK;
            INTERFACE_REG(LP36_DATA_OFF) = 0 & LP36_DATA_SEC2_MASK;
            INTERFACE_REG(LP36_WR_OFF) = LP36_WR_OFF;

            INTERFACE_REG(LP36_SEL_OFF) = 2 & LP36_SEL_MASK;
            INTERFACE_REG(LP36_DATA_OFF) = 0 & LP36_DATA_LINE_MASK;
            INTERFACE_REG(LP36_WR_OFF) = LP36_WR_OFF;

            INTERFACE_REG(LP36_SEL_OFF) = 3 & LP36_SEL_MASK;
            INTERFACE_REG(LP36_DATA_OFF) = 0 & LP36_DATA_SQUA_MASK;
            INTERFACE_REG(LP36_WR_OFF) = LP36_WR_OFF;
        }
    }

    return 0;
}
