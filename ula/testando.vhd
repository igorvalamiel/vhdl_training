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

entity tst3 is
    Port (keys : in  std_logic_vector (3 downto 0);
        leds : out  std_logic_vector (3 downto 0);
        clock : in  std_logic;
        glb_clock : in std_logic;
        flag_zero : out  std_logic;
        flag_sign : out  std_logic;
        flag_overf : out  std_logic;
        flag_cout : out  std_logic);
end tst3;

architecture main of tst3 is
    
    -- declaring variables
        signal state: std_logic_vector(1 downto 0) := "11";
        signal operation: std_logic_vector(3 downto 0) := "0000";
        signal val1: std_logic_vector(3 downto 0) := "0000";
        signal val2: std_logic_vector(3 downto 0) := "0000";
        signal count: integer := 0;
        signal c0: std_logic;
        signal c1: std_logic;
        signal c2: std_logic;
        signal c3: std_logic;
        signal fiveb: std_logic_vector(4 downto 0);
        signal fourb: std_logic_vector(3 downto 0);
        signal clock_out: std_logic;
        signal reset_value: std_logic := '0';
	signal op_keys: std_logic_vector(3 downto 0);
        signal v1_keys: std_logic_vector(3 downto 0);
        signal v2_keys: std_logic_vector(3 downto 0);
        
    component debounce is
        generic(
            clk_freq    : integer := 50_000_000;
            stable_time : integer := 25);
        port(
            clk     : in  std_logic;
            reset_n : in  std_logic;
            button  : in  std_logic;
            result  : OUT std_logic);
    end component debounce;

    component ffmem is
        port(
            clk     : in  std_logic;
            reset : in  std_logic;
            state : in std_logic_vector (1 downto 0);
            val  : in  std_logic_vector (3 downto 0);
            result  : out std_logic_vector (3 downto 0)
        );
    end component ffmem;

begin	 
    
    dbc : debounce port map (glb_clock, reset_value, clock, clock_out); 
    ffop: ffmem port map(clock_out, reset_value, state, keys, op_keys);
    ffv1: ffmem port map(clock_out, reset_value, state, keys, v1_keys);
    ffv2: ffmem port map(clock_out, reset_value, state, keys, v2_keys);
    
    process(clock_out)
    
    begin
        if rising_edge(clock_out) then
            --Input operation
            if state = "00" then
                operation <= op_keys;
                state <= "01";
                reset_value <= '1';

            --Input value 1
            elsif state = "01" then
                val1 <= v1_keys;
                    --One value only operation execution
                    --inverter
                    if operation = "0001" then
                        val1 <= not val1;
                        if val1 = "0000" then flag_zero <= '1';
                        end if;
                        leds <= val1;
                            state <= "11";
                    
                    --shift
                    elsif operation = "0100" then
                        if val1(3) = '0' then
                            flag_overf <= '1';
                        elsif val1(3) = '1' then
                            flag_cout <= '1';
                        end if;
                        leds <= std_logic_vector(unsigned(val1) + 2);
                        if val1 = "0000" then 
                            flag_zero <= '1';
                        end if;
                            state <= "11";

                    --comp. de 2
                    elsif operation = "0101" then
                        if val1 = "0000" then
                            leds <= val1;
                            flag_zero <= '1';
                        else
                            val1 <= not val1;
                            val1 <= std_logic_vector(signed(val1) + 1);
                        end if;
                        state <= "11";

                    --Paridade
                    elsif operation = "1000" then
                        for i in 0 to 3 loop
                            if val1(i) = '1' then count <= count + 1;
                            end if;
                        end loop;
                        leds <= std_logic_vector(to_unsigned(count, 4));
                            state <= "11";
                    
                    --more than one value operation
                    else state <= "10";
                    end if;

                
            --Input value 2
            elsif state = "10" then
                val2 <= v2_keys;
                state <= "11";

                    -- Addition
                    if operation = "0010" then
                        c0 <= val1(0) and val2(0);
                        fourb(0) <= (val1(0) xor val2(0));
                        c1 <= (c0 and val1(1)) or (c0 and val2(1)) or (val1(1) and val2(1));
                        fourb(1) <= (c0 xor val1(1) xor val2(1));
                        c2 <= (c1 and val1(2)) or (c1 and val2(2)) or (val1(2) and val2(2));
                        fourb(2) <= (c1 xor val1(2) xor val2(2));
                        c3 <= (c2 and val1(3)) or (c2 and val2(3)) or (val1(3) and val2(3));
                        fourb(3) <= (c2 xor val1(3) xor val2(3));
                        fiveb <= std_logic_vector(signed(val1) + signed(val2));

                        flag_overf <= c3;
                        flag_sign <= fiveb(3);
                        flag_cout <= fiveb(4);
                        if fiveb(3 downto 0) = "0000" then flag_zero <= '1'; end if;

                        leds <= fiveb(3 downto 0);
                    
                    -- Subtraction
                    elsif operation = "0011" then
                        val2 <= std_logic_vector(signed(not val2) + 1);

                        c0 <= val1(0) and val2(0);
                        fourb(0) <= (val1(0) xor val2(0));
                        c1 <= (c0 and val1(1)) or (c0 and val2(1)) or (val1(1) and val2(1));
                        fourb(1) <= (c0 xor val1(1) xor val2(1));
                        c2 <= (c1 and val1(2)) or (c1 and val2(2)) or (val1(2) and val2(2));
                        fourb(2) <= (c1 xor val1(2) xor val2(2));
                        c3 <= (c2 and val1(3)) or (c2 and val2(3)) or (val1(3) and val2(3));
                        fourb(3) <= (c2 xor val1(3) xor val2(3));
                        fiveb <= std_logic_vector(signed(val1) - signed(val2));

                        flag_overf <= c3;
                        flag_sign <= fiveb(3);
                        flag_cout <= fiveb(4);
                        if fiveb(3 downto 0) = "0000" then flag_zero <= '1'; end if;

                        leds <= fiveb(3 downto 0);
                    
                    -- Greater
                    elsif operation = "0110" then
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
                reset_value <= '0';
                flag_zero <= '0';
                flag_sign <= '0';
                flag_overf <= '0';
                flag_cout <= '0';
            end if;
        end if;
    end process;
end main;
