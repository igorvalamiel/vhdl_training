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

entity machine is
    Port ( keys : in  std_logic_vector (3 downto 0);
           leds : out  std_logic_vector (3 downto 0);
           clock : in  bit;
           flag_zero : out  bit;
           flag_sign : out  bit;
           flag_overf : out  bit;
           flag_cout : out  bit);
end machine;

architecture main of machine is
	 
	 -- declaring variables
        signal state: std_logic_vector(1 downto 0) := "00";
        signal operation: std_logic_vector(3 downto 0) := "0000";
        signal val1: std_logic_vector(3 downto 0) := "0000";
        signal val2: std_logic_vector(3 downto 0) := "0000";
        signal trash_4: std_logic_vector(3 downto 0) := "0000";
        signal trash_5: std_logic_vector(4 downto 0) := "00000";
		  signal num1: integer;
begin	 
	 
	 process (clock)
	 
    begin
        --Input operation
        if state = "00" then
            operation <= keys;
            state <= "01";

        --Input value 1
        elsif state = "01" then
            val1 <= keys;
			  --One value only operation execution
			  --inverter
			  if operation = "0001" then
					val1 <= not val1;
					if val1 = "0000" then flag_zero <= '1'; end if;
					leds <= val1;
			  
			  --shift
			  elsif operation = "0100" then
					if val1(3) = '0' then
						 flag_overf <= '1';
					elsif val1(3) = '1' then
						 flag_cout <= '1';
					end if;
					--num1 <= to_integer(val1) + 2;
					leds <= std_logic_vector(unsigned(val1) + 2);
					if val1 = "0000" then 
							 flag_zero <= '1';
					end if;
                state <= "11";
					else state <= "10";
				end if;
            
        --Input value 2
        elsif state = "10" then
            val2 <= keys;
            state <= "11";

                -- Addition
                --if operation = "0010" then
                
                -- Subtraction
                --if operation = "0011" then
                    
                
                -- Greater
                if operation = "0110" then
                    if (val1 > val2) then
                        leds <= val1;
                    else
                        leds <= val2;
                    end if;
                
                -- Smaller
                elsif operation = "0111" then
                    if (val1 < val2) then
                        leds <= val1;
                    else
                        leds <= val2;
                    end if;
					end if;
        
        --clear state
        else
            leds <= "0000";
            state <= "00";
            operation <= "0000";
        end if;
    end process;
end main;


