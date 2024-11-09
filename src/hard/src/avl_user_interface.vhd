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

  COMPONENT timer IS
    GENERIC (
      T1_g : NATURAL RANGE 1 TO 1023 := 50);
    PORT (
      clock_i : IN STD_LOGIC;
      reset_i : IN STD_LOGIC;
      start_i : IN STD_LOGIC;
      trigger_o : OUT STD_LOGIC
    );
  END COMPONENT;
  FOR ALL : timer USE ENTITY work.timer;

  --| Constants declarations |--------------------------------------------------------------
  CONSTANT INTERFACE_ID_C : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"12345678";
  CONSTANT OTHERS_VAL_C : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";

  --| Signals declarations   |--------------------------------------------------------------   
  SIGNAL led_reg_s : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL lp36_data_reg_s : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL lp36_sel_reg_s : STD_LOGIC_VECTOR(3 DOWNTO 0);

  SIGNAL boutton_s : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL switches_s : STD_LOGIC_VECTOR(9 DOWNTO 0);
  
  signal readdatavalid_next_s : std_logic;
  signal readdatavalid_reg_s : std_logic;
  signal readdata_next_s : std_logic_vector(31 downto 0);
  signal readdata_reg_s : std_logic_vector(31 downto 0);

  SIGNAL cs_wr_lp36_data_s : STD_LOGIC;
  SIGNAL lp36_valide_s : STD_LOGIC;
  SIGNAL us_done_s : STD_LOGIC;
  SIGNAL start_timer_s : STD_LOGIC;
  SIGNAL lp36_we_s : STD_LOGIC;

  --| Types |----------------------------------------------------------------
  TYPE state_t IS (
    --General state
    ATT,
    GET_DATA,
    WAIT1US,
    -- Error
    ERR
  );
  signal e_pres, e_fut_s : state_t;

BEGIN

  -- Input signals

  boutton_s <= boutton_i;
  switches_s <= switch_i;

  cs_wr_lp36_data_s <= '1' when (avl_write_i = '1') AND (to_integer(unsigned(avl_address_i)) = 6) else '0';
    
  lp36_valide_s <= '1' when lp36_status_i = "01" else '0';

  -- Output signals

  avl_readdatavalid_o <= readdatavalid_reg_s;
  avl_readdata_o <= readdata_reg_s;

  led_o <= led_reg_s;

  lp36_sel_o <= lp36_sel_reg_s;
  lp36_data_o <= lp36_data_reg_s;
  lp36_we_o <= lp36_we_s;

  -- Read access part
  -- Read register process

  read_decoder_p : PROCESS (ALL)
  BEGIN
    readdatavalid_next_s <= '0'; --valeur par defaut
    readdata_next_s <= (OTHERS => '0'); --valeur par defaut

    IF avl_read_i = '1' THEN
      readdatavalid_next_s <= '1';

      CASE (to_integer(unsigned(avl_address_i))) IS

        WHEN 0 =>
          readdata_next_s <= INTERFACE_ID_C;

        WHEN 2 =>
          readdata_next_s(9 DOWNTO 0) <= switch_i;
			 
        WHEN 3 =>
          readdata_next_s(3 DOWNTO 0) <= boutton_s;

        WHEN 4 =>
          readdata_next_s(0) <= lp36_valide_s;
          readdata_next_s(1) <= lp36_we_s;
			 
		  WHEN 6 =>
          readdata_next_s <= lp36_data_reg_s;
				  
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

  write_register_p : PROCESS (
    avl_reset_i,
    avl_clk_i,
	 avl_write_i,
	 avl_writedata_i,
    led_reg_s,
    lp36_data_reg_s,
    lp36_sel_reg_s,
	 cs_wr_lp36_data_s
    )
  BEGIN
	 
    IF avl_reset_i = '1' THEN

      led_reg_s <= (OTHERS => '0');
      lp36_data_reg_s <= (OTHERS => '0');
      lp36_sel_reg_s <= (OTHERS => '0');

    ELSIF rising_edge(avl_clk_i) THEN

      IF avl_write_i = '1' THEN

        CASE (to_integer(unsigned(avl_address_i))) IS

          WHEN 1 =>
            led_reg_s <= avl_writedata_i(9 DOWNTO 0);

          WHEN 5 =>
			   -- Write only if not in transfering mode
			   IF lp36_we_s = '0' THEN
              lp36_sel_reg_s <= avl_writedata_i(3 DOWNTO 0);
				END IF;

          WHEN 6 =>
            -- Write only if not in transfering mode
            IF lp36_we_s = '0' THEN
              lp36_data_reg_s <= avl_writedata_i;
            END IF;

          WHEN OTHERS =>
            NULL;

        END CASE;
      END IF;
    END IF;
  END PROCESS;

  -- Interface management
  
  -- Timer management

  timer_boutton : timer
  GENERIC MAP(T1_g => 50)
  PORT MAP(
    clock_i => avl_clk_i,
    reset_i => avl_reset_i,
    start_i => start_timer_s,
    trigger_o => us_done_s
  );

  -- State machine
  -- This process update the state of the state machine
  fsm_reg : PROCESS (avl_reset_i, avl_clk_i) IS
  BEGIN
    IF (avl_reset_i = '1') THEN
      e_pres <= ATT;
    ELSIF (rising_edge(avl_clk_i)) THEN
      e_pres <= e_fut_s;
    END IF;
  END PROCESS fsm_reg;

  dec_fut_sort : PROCESS (
    e_pres,
    cs_wr_lp36_data_s,
    lp36_valide_s,
    us_done_s,
    start_timer_s,
    lp36_we_s
    ) IS
  BEGIN
    -- Default values for generated signal
    start_timer_s <= '0';
    lp36_we_s <= '0';

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
          start_timer_s <= '1';
        END IF;
      WHEN WAIT1US =>
        IF us_done_s = '0' THEN
          e_fut_s <= WAIT1US;
          lp36_we_s <= '1';
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