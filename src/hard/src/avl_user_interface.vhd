------------------------------------------------------------------------------------------
-- HEIG-VD ///////////////////////////////////////////////////////////////////////////////
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
------------------------------------------------------------------------------------------
-- REDS Institute ////////////////////////////////////////////////////////////////////////
-- Reconfigurable Embedded Digital Systems
------------------------------------------------------------------------------------------
--
-- File                 : avl_user_interface.vhd
-- Author               : Urs Behrmann
-- Date                 : 06.11.2024
--
-- Context              : Avalon user interface
--
------------------------------------------------------------------------------------------
-- Description : 
--   
------------------------------------------------------------------------------------------
-- Dependencies : None
--   
------------------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.0    See header  UB          Initial version

------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY avl_user_interface IS
  PORT (
    -- Avalon bus
    avl_clk_i : IN STD_LOGIC;
    avl_reset_i : IN STD_LOGIC;
    avl_address_i : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    avl_byteenable_i : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    avl_write_i : IN STD_LOGIC;
    avl_writedata_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    avl_read_i : IN STD_LOGIC;
    avl_readdatavalid_o : OUT STD_LOGIC;
    avl_readdata_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    avl_waitrequest_o : OUT STD_LOGIC;
    -- User interface
    boutton_i : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    switch_i : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    led_o : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    lp36_we_o : OUT STD_LOGIC;
    lp36_sel_o : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    lp36_data_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    lp36_status_i : IN STD_LOGIC_VECTOR(1 DOWNTO 0)
  );
END avl_user_interface;

ARCHITECTURE rtl OF avl_user_interface IS

  --| Components declaration |--------------------------------------------------------------
  --| Constants declarations |--------------------------------------------------------------
  CONSTANT INTERFACE_ID_C : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"12345678";
  CONSTANT LEDS_ADDR_C : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000004";
  CONSTANT SWITCHES_ADDR_C : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000008";
  CONSTANT KEY_ADDR_C : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"0000000C";
  CONSTANT LP36_STATUS_ADDR_C : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000010";
  CONSTANT LP36_SEL_ADDR_C : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000014";
  CONSTANT LP36_DATA_ADDR_C : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000018";
  CONSTANT OTHERS_VAL_C : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";

  --| Signals declarations   |--------------------------------------------------------------   
  SIGNAL led_reg_s : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL lp36_data_reg_s : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL lp36_sel_reg_s : STD_LOGIC_VECTOR(3 DOWNTO 0);

  SIGNAL boutton_s : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL switches_s : STD_LOGIC_VECTOR(9 DOWNTO 0);

  SIGNAL lp36_status_s : STD_LOGIC_VECTOR(1 DOWNTO 0);

  --| Types |----------------------------------------------------------------
  TYPE state_t IS (
    --General state
    ATT,
    GET_DATA,
    WAIT1US,
    -- Error
    ERR
  );

BEGIN

  -- Input signals

  boutton_s <= boutton_i;
  switches_s <= switch_i;

  lp36_status_s <= lp36_status_i;

  -- Output signals

  avl_readdatavalid_o <= readdatavalid_reg_s;
  avl_readdata_o <= readdata_reg_s;

  led_o <= led_reg_s;

  lp36_sel_o <= lp36_sel_reg_s;
  lp36_data_o <= lp36_data_reg_s;

  -- Read access part
  -- Read register process

  read_decoder_p : PROCESS (ALL)
  BEGIN
    readdatavalid_next_s <= '0'; --valeur par defaut
    readdata_next_s <= (OTHERS => '0'); --valeur par defaut

    IF avl_read_i = '1' THEN
      readdatavalid_next_s <= '1';

      CASE (to_integer(unsigned(avl_address_i))) IS

        WHEN INTERFACE_ID_C =>
          readdata_next_s <= INTERFACE_ID_C;

        WHEN KEY_ADDR_C =>
          readdata_next_s(3 DOWNTO 0) <= boutton_s;

        WHEN SWITCHES_ADDR_C =>
          readdata_next_s(9 DOWNTO 0) <= switch_i;

        WHEN LP36_STATUS_ADDR_C =>
          readdata_next_s(9 DOWNTO 0) <= lp36_status_s;

        WHEN OTHERS =>
          readdata_next_s <= OTHERS_VAL_C;

      END CASE;
    END IF;
  END PROCESS;

  -- Read register process
  read_register_p : PROCESS (avl_reset_i, avl_clk_i)
  BEGIN
    IF avl_reset_i = '1' THEN

      readdatavalid_reg_s <= '0';
      readdata_reg_s <= (OTHERS => '0');

    ELSIF rising_edge(avl_clk_i) THEN

      readdatavalid_reg_s <= readdatavalid_next_s;
      readdata_reg_s <= readdata_next_s;

    END IF;
  END PROCESS;

  -- Write access part

  write_register_p : PROCESS (avl_reset_i, avl_clk_i)
  BEGIN
    IF reset_i = '1' THEN

      led_reg_s <= (OTHERS => '0');
      lp36_data_reg_s <= (OTHERS => '0');
      lp36_sel_reg_s <= (OTHERS => '0');

    ELSIF rising_edge(avl_clk_i) THEN

      IF write_i = '1' THEN

        CASE (to_integer(unsigned(avl_address_i))) IS

          WHEN LEDS_ADDR_C =>
            led_reg_s <= writedata_i(9 DOWNTO 0);

          WHEN LP36_SEL_ADDR_C =>
            lp36_sel_reg_s <= writedata_i(3 DOWNTO 0);

          WHEN LP36_DATA_ADDR_C =>
            lp36_data_reg_s <= writedata_i;

          WHEN OTHERS =>
            NULL;

        END CASE;
      END IF;
    END IF;
  END PROCESS;

  -- Interface management

  SIGNAL cs_wr_lp36_data_s : STD_LOGIC;
  SIGNAL lp36_valide_s : STD_LOGIC;
  SIGNAL 1us_done_s : STD_LOGIC;
  SIGNAL start_timer_s : STD_LOGIC;

  cs_wr_lp36_data_s <= avl_write_i AND (to_integer(unsigned(avl_address_i)) = LP36_DATA_ADDR_C);
  lp36_valide_s <= lp36_status_i = "01";
  
  -- This process update the state of the state machine
  fsm_reg : PROCESS (avl_reset_i, avl_clk_i) IS
  BEGIN
    IF (rst_i = '1') THEN
      e_pres <= ATT;
    ELSIF (rising_edge(avl_clk_i)) THEN
      e_pres <= e_fut_s;
    END IF;
  END PROCESS fsm_reg;

  dec_fut_sort : PROCESS (
    cs_wr_lp36_data_s,
    lp36_valide_s,
    1us_done_s,
    ) IS
  BEGIN
    -- Default values for generated signal
    CASE e_pres IS
      WHEN ATT =>
        IF cs_wr_lp36_data_s = '1' THEN
          e_fut_s <= GET_DATA;
        ELSE
          e_fut_s <= ATT;
        END IF;
      WHEN GET_DATA =>
        IF lp36_valide_s = '0' THEN
          e_fut_s <= ERR;
        ELSE
          e_fut_s <= WAIT1US;
        END IF;
      WHEN WAIT1US =>
        IF 1us_done_s = '0' THEN
          e_fut_s <= WAIT1US;
        ELSE
          e_fut_s <= ATT;
        END IF;
      WHEN ERR =>
        IF lp36_valide_s = '1' THEN
          e_fut_s <= ATT;
        ELSE
          e_fut_s <= ERR;
        END IF;
      WHEN OTHERS =>
        e_fut_s <= ATT;
    END CASE;
  END PROCESS dec_fut_sort;
END rtl;