----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:24:43 09/10/2024 
-- Design Name: 
-- Module Name:    machine - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ula is
    -- configurando estradas e saídas da placa
    port(keys : in  std_logic_vector (3 downto 0);
    leds : out  std_logic_vector (3 downto 0);
    clock : in  std_logic;
    reset : in std_logic;
    flag_zero : out  std_logic;
    flag_sign : out  std_logic;
    flag_overf : out  std_logic;
    flag_cout : out  std_logic);
end ula;

architecture main of ula is

    --chamando o debounce
    component debounce is
        port(
            clk     : in  std_logic;
            reset_n : in  std_logic;
            button  : in  std_logic;
            result  : OUT std_logic);
    end component debounce;

    --declarando sinais para funcionamento do clock, da mudança de estados e dos valores à receber
    signal state: std_logic_vector(1 downto 0) := "11";
    signal operation: std_logic_vector(3 downto 0) := "0000";
    signal val1: std_logic_vector(3 downto 0) := "0000";
    signal val2: std_logic_vector(3 downto 0) := "0000";
    signal clock_out: std_logic;

    begin
        --declarando o debounce
        dbc : debounce port map (clock, reset, '1', clock_out);

        -- testando clock+debounce
        process(clock_out)
        begin
            if rising_edge(clock_out) then
                leds <= val1;
                if state = "00" then
                    state <= "01";
                    val1 <= "0001";
                elsif state = "01" then
                    state <= "10";
                    val1 <= "0010";
                elsif state = "11" then
                    state <= "11";
                    val1 <= "0100";
                else
                    state <= "00";
                    val1 <= "1000";
                end if;
            end if;
        end process;

end main;
