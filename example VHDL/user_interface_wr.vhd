------------------------------------------------------------------------------------------
-- HEIG-VD ///////////////////////////////////////////////////////////////////////////////
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
------------------------------------------------------------------------------------------
-- REDS Institute ////////////////////////////////////////////////////////////////////////
-- Reconfigurable Embedded Digital Systems
------------------------------------------------------------------------------------------
--
-- File                 : user_interface_wr.vhd
-- Author               : Etienne Messerli
-- Date                 : 01.11.2024
--
-- Context              : Exemple dec adr + reg pour canal write
--
------------------------------------------------------------------------------------------
-- Description :
--
------------------------------------------------------------------------------------------
-- Dependencies :
--
------------------------------------------------------------------------------------------
-- Modifications :
-- Ver    Date        Engineer    Comments
-- 0.0    See header              Initial version

------------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    
entity user_interface_wr is
  port(
    -- Avalon bus
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    address_i       : in  std_logic_vector(3 downto 0);
    write_i         : in  std_logic;
    writedata_i     : in  std_logic_vector(15 downto 0);
    -- User interface
    led_o           : out std_logic_vector(9 downto 0);
    lp36_data_o     : out std_logic_vector(15 downto 0)
  );
end user_interface_wr;

architecture rtl of user_interface_wr is

    --| Components declaration |--------------------------------------------------------------
    --| Constants declarations |--------------------------------------------------------------
    constant IP_USER_ID_C : std_logic_vector(15 downto 0) := x"1234";
    constant OTHERS_VAL_C : std_logic_vector(15 downto 0) := x"cafe";
    
    --| Signals declarations   |--------------------------------------------------------------   
    signal led_reg_s        : std_logic_vector(9 downto 0);
    signal lp36_data_reg_s  : std_logic_vector(15 downto 0);

begin
    
    -- Input signals

    -- Output signals
    led_o <= led_reg_s;
    lp36_data_o <= lp36_data_reg_s;

    -- Write channel with register
    write_register_p : process(reset_i, clk_i)
    begin
        if reset_i='1' then
            led_reg_s <= (others => '0');
            lp36_data_reg_s <= (others => '0');
        elsif rising_edge(clk_i) then
            if write_i='1' then
                case (to_integer(unsigned(address_i))) is
                    --when 0 =>     -- read only
                    --    
                    --when 1 =>     -- read only
                    --    
                    --when 2 =>     -- read only
                    --    
                    when 3 =>
                        led_reg_s <= writedata_i(9 downto 0);
                    when 4 =>
                        lp36_data_reg_s <= writedata_i;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    
end rtl; 
