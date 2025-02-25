-----------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : avalon_slv_tb.vhd
-- Description  : testbench pour interface avalon slave
--
-- Auteur       : S. Masle
-- Date         : 11.07.2022
--
-- Utilise      : 
--
--| Modifications |-----------------------------------------------------------
-- Ver   Auteur Date         Description
-- 1.0   SMS    11.07.2022   Version initiale
------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.uniform;

entity avalon_console_sim is
end avalon_console_sim;

architecture Behavioral of avalon_console_sim is

    component avl_user_interface
        port(
            -- Avalon bus
            avl_clk_i           : in  std_logic;
            avl_reset_i         : in  std_logic;
            avl_address_i       : in  std_logic_vector(13 downto 0);
            avl_byteenable_i    : in  std_logic_vector(3 downto 0);
            avl_write_i         : in  std_logic;
            avl_writedata_i     : in  std_logic_vector(31 downto 0);
            avl_read_i          : in  std_logic;
            avl_readdatavalid_o : out std_logic;
            avl_readdata_o      : out std_logic_vector(31 downto 0);
            avl_waitrequest_o   : out std_logic;
            -- User interface
            boutton_i           : in  std_logic_vector(3 downto 0);
            switch_i            : in  std_logic_vector(9 downto 0);
            led_o               : out std_logic_vector(9 downto 0);
            lp36_we_o           : out std_logic;
            lp36_sel_o          : out std_logic_vector(3 downto 0);
            lp36_data_o         : out std_logic_vector(31 downto 0);
            lp36_status_i       : in  std_logic_vector(1 downto 0)
        );
    end component;

    constant ClockPeriod : TIME := 20 ns;
    constant pulse_c     : time := 4 ns;

    signal clock_sti : std_logic;
    signal reset_sti : std_logic;

    signal address_sti         : std_logic_vector(13 downto 0);
    signal byteenable_sti      : std_logic_vector(3 downto 0);
    signal read_sti            : std_logic;
    signal read_data_valid_obs : std_logic;
    signal read_data_obs       : std_logic_vector(31 downto 0);
    signal write_sti           : std_logic;
    signal write_data_sti      : std_logic_vector(31 downto 0);
    signal waitrequest_obs     : std_logic;
    signal button_n_s          : std_logic_vector(3 downto 0);
    signal button_sti          : std_logic_vector(31 downto 0);
    signal switch_sti          : std_logic_vector(31 downto 0);
    signal lp36_status_sti     : std_logic_vector(31 downto 0);
    signal led_obs             : std_logic_vector(31 downto 0) := (others => '0');
    signal lp36_we_obs         : std_logic;
    signal lp36_sel_obs        : std_logic_vector(31 downto 0) := (others => '0');
    signal lp36_data_obs       : std_logic_vector(31 downto 0) := (others => '0');
    
begin

    DUT: entity work.avl_user_interface
        port map (
            -- Avalon bus
            avl_clk_i           => clock_sti,
            avl_reset_i         => reset_sti,
            avl_address_i       => address_sti,
            avl_byteenable_i    => byteenable_sti,
            avl_write_i         => write_sti,
            avl_writedata_i     => write_data_sti,
            avl_read_i          => read_sti,
            avl_readdatavalid_o => read_data_valid_obs,
            avl_readdata_o      => read_data_obs,
            avl_waitrequest_o   => waitrequest_obs,
    
            -- User input-output
            boutton_i           => button_n_s,
            switch_i            => switch_sti(9 downto 0),
            led_o               => led_obs(9 downto 0),
            lp36_we_o           => lp36_we_obs,
            lp36_sel_o          => lp36_sel_obs(3 downto 0),
            lp36_data_o         => lp36_data_obs(31 downto 0),
            lp36_status_i       => lp36_status_sti(1 downto 0)
        );
        
    button_n_s <= not button_sti(3 downto 0);   -- boutton_i (key) is active low

    -- Generate clock signal
    GENERATE_REFCLOCK : process
    begin
 
        while true loop
            clock_sti <= '1',
                         '0' after ClockPeriod/2;
            wait for ClockPeriod;
        end loop;
        wait;
    end process;

end Behavioral;
