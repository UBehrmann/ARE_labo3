------------------------------------------------------------------------------------------
-- HEIG-VD ///////////////////////////////////////////////////////////////////////////////
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
------------------------------------------------------------------------------------------
-- REDS Institute ////////////////////////////////////////////////////////////////////////
-- Reconfigurable Embedded Digital Systems
------------------------------------------------------------------------------------------
--
-- File                 : mux_reg_rd.vhd
-- Author               : Etienne Messerli
-- Date                 : 01.11.2024
--
-- Context              : Exemple mux + reg data_rd
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
    
entity mux_reg_rd is
  port(
    clk_i           : in  std_logic;
    reset_i         : in  std_logic;
    address_i       : in  std_logic_vector(3 downto 0);
    read_i          : in  std_logic;
    readdatavalid_o : out std_logic;
    readdata_o      : out std_logic_vector(15 downto 0);
    nBoutton_i      : in  std_logic_vector(3 downto 0);
    switch_i        : in  std_logic_vector(9 downto 0)
  );
end mux_reg_rd;

architecture rtl of mux_reg_rd is

    --| Components declaration |--------------------------------------------------------------
    --| Constants declarations |--------------------------------------------------------------
    constant IP_USER_ID_C : std_logic_vector(15 downto 0) := x"1234";
    constant OTHERS_VAL_C : std_logic_vector(15 downto 0) := x"cafe";
    
    --| Signals declarations   |--------------------------------------------------------------   
    signal boutton_s : std_logic_vector(3 downto 0);
    signal readdatavalid_next_s : std_logic;
    signal readdatavalid_reg_s : std_logic;
    signal readdata_next_s : std_logic_vector(15 downto 0);
    signal readdata_reg_s : std_logic_vector(15 downto 0);
    signal led_reg_s : std_logic_vector(9 downto 0);


begin
    
    -- Input signals
    boutton_s <= not nBoutton_i;     -- Boutton_i is active low
    
    -- Output signals
    readdata_o <= readdata_reg_s;
    readdatavalid_o <= readdatavalid_reg_s;
    

    -- affecte une valeur pour les led_reg_s
    led_reg_s <= "1101010011";

    -- Read decoder process
    read_decoder_p : process(all)
    begin
        readdatavalid_next_s <= '0';        --valeur par defaut
        readdata_next_s <= (others => '0'); --valeur par defaut
        if read_i='1' then
            readdatavalid_next_s <= '1';
            case (to_integer(unsigned(address_i))) is
                when 0 =>
                    readdata_next_s <= IP_USER_ID_C;
                when 1 =>
                    readdata_next_s(3 downto 0) <= boutton_s;
                when 2 =>
                    readdata_next_s(9 downto 0) <= switch_i;
                when 3 =>
                    readdata_next_s(9 downto 0) <= led_reg_s;
                when others =>
                    readdata_next_s <= OTHERS_VAL_C;
            end case;
        end if;
    end process;
    
    -- Read register process
    read_register_p : process(reset_i, clk_i)
    begin
        if reset_i='1' then
            readdatavalid_reg_s <= '0';
            readdata_reg_s <= (others => '0');
        elsif rising_edge(clk_i) then
            readdatavalid_reg_s <= readdatavalid_next_s;
            readdata_reg_s <= readdata_next_s;
        end if;
    end process;


end rtl; 
