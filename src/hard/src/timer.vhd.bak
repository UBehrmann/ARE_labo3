-------------------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenierie et de Gestion du canton de Vaud
-- Institut REDS, Reconfigurable & Embedded Digital Systems
--
-- Fichier      : timer.vhd
-- Auteur       : Etienne Messerli, le 05.05.2016
-- 
-- Description  : Detection d'un clic et double clic
--                Projet repris du labo Det_Clic_DblClic 2012
-- 
-- Utilise      : Labo SysLog2 2016
--| Modifications |------------------------------------------------------------
-- Ver   Date      Qui         Description
-- 1.0   05.05.16  EMI         version initiale
-- 1.1   19.11.20  SMS         remplacement des constantes par des g�n�riques
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
    generic (
        T1_g : natural range 1 to 1023 := 2;
    port (
        clock_i    : in  std_logic;
        reset_i    : in  std_logic;
        start_i    : in  std_logic;
        trigger_o : out std_logic
        );
end timer;

architecture comport of timer is

	signal timer_pres : std_logic_vector(8 downto 0);
	signal timer_fut : std_logic_vector(8 downto 0);

	signal t1 : std_logic_vector(8 downto 0);

begin

	t1 <= std_logic_vector(to_unsigned(T1_g, 9));
	
	timer_fut <=  (others => '0') when (start_i = '1') else
                std_logic_vector(unsigned(timer_pres) + 1);

  process(reset_i, clock_i)
  begin
		if reset_i = '1' then
			timer_pres <= (others => '0');
		elsif rising_edge(clock_i) then
			timer_pres <= timer_fut;
		end if;
  end process;

  trigger_o <= '0' when (timer_pres < t1) else '1';

end comport;
