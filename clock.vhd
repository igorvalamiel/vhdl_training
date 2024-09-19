----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:54:14 09/17/2024 
-- Design Name: 
-- Module Name:    clk - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clk is
    Port ( clock : in  STD_LOGIC;
           leds : out  STD_LOGIC_VECTOR (3 downto 0));
end clk;

architecture Behavioral of clk is

signal state: std_logic_vector(1 downto 0) := "11";
signal intern_clk: std_logic := '0';
signal num: std_logic_vector(3 downto 0) := "0001";

begin
process(clock)
	begin
	if rising_edge(clock) then
		leds <= num;
		if state = "00" then
			state <= "01";
			num <= "0001";
		elsif state = "01" then
			state <= "10";
			num <= "0010";
		elsif state = "11" then
			state <= "11";
			num <= "0100";
		else
			state <= "00";
			num <= "1000";
		end if;
	end if;

end process;


end Behavioral;

 