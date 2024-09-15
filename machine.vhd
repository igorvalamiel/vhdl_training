-- tentando adiantar o código para o lab de SD

entity machine is
    port(
        keys    : in bit_vector (3 downto 0);
        clock   :   in bit;
        leds  :   out bit_vector (3 downto 0);
        flag_zero   :   out bit;
        flag_sign   :   out bit;
        flag_overf  :   out bit;
        flag_cout   :   out bit
    );
end entity;

architecture main of machine is
    process
    begin
        -- declaring variables
        signal state: bit_vector(1 downto 0) := "00";
        signal operation: bit_vector(3 downto 0) := "0000";
        signal val1: bit_vector(3 downto 0) := "0000";
        signal val2: bit_vector(3 downto 0) := "0000";

        wait until clock'event and clock='1';
        --Input operation
        if state = "00" then
            operation <= keys;
            state <= "01";

        --Input value 1
        elsif state = "01" then
            val1 <= keys;
            --dealing with exceptions
            if (operation = "0001") or (operation = "0100") or (operation = "0101") or (operation = "1000") then 
                --One value only operation execution
<<<<<<< Updated upstream
                case operation is
                    when "0001" =>
                        val1 <= not val1;
                        if val1 = "0000" then flag_zero = '1'; end if;
                        leds <= val1;
                        --????? negative????
                    
                    when "0100" =>
                        if val1(3) = '0' then
                            flag_overf <= '1';
                        elsif val1(3) = '1' then
                            flag_cout <= '1';
                        end if;
                        val1 <= val1 + 2;
                        leds <= val1;
                        if val1 = "0000" then 
                            flag_zero <= '1';
                        end if;
                end case;
                state <= "11";
            else state <= "10";
            end if;
=======
                --inverter
                if operation = "0001" then
                    val1 <= not val1;
                    if val1 = "0000" then flag_zero <= '1';
                    end if;
                    leds <= val1;
                
                --shift
                elsif operation = "0100" then
                -- Verifying if has overflow or carryout    
                    if val1(3) = '0' then
                        flag_overf <= '1';
                    elsif val1(3) = '1' then
                        flag_cout <= '1';
                    end if;
                -- Shifting to left(Same as multiply by 2)
                    leds <= std_logic_vector(unsigned(val1) * 2);
                    if val1 = "0000" then 
                        flag_zero <= '1';
                -- Going to final state
                    end if;
                    state <= "11";

                --comp. de 2
                elsif operation = "0101" then
                --  Complementing 0 and flaging that is 0
                    if val1 = "0000" then
                        leds <= val1;
                        flag_zero <= '1';
                -- Complementing by 2 by inverting all bits and summing 1
                    else
                        val1 <= not val1;
                        val1 <= std_logic_vector(unsigned(val1) + 1);
                    state <= "11";
			        end if;

                --Paridade
                elsif operation = "1000" then
                    -- Verifying how much 1s the bit vector has
                    for i in 0 to 3 loop
                        if val1(i) = '1' then count <= count + 1;
                        end if;
                    end loop;
                    -- Returning that number
                    leds <= std_logic_vector(to_unsigned(count, 4));
                    state <= "11";
                
                --more than one value operation
                else state <= "10";
                end if;

>>>>>>> Stashed changes
            
        --Input value 2
        elsif state = "10" then
            val2 <= keys;
<<<<<<< Updated upstream
            state <= '11';
            leds <= val1 + val2;
            if val1 > "0100" and val2 > "0100" then
                flag_cout <= '1';
            end if;
=======
            state <= "11";

                -- Addition
                -- OBS: o número do input já esta em complento de dois, logo eu tenho que trasnformar ele de volta ou é só somar??? -> perguntar p pedro
                if operation = "0010" then
                    -- Converting to integer and summing
                    num1 <= to_integer(val1) + to_integer(val2);
                    -- Treating the result
                    if num1 > 15 or num1 < -15 then
                        flag_overf = '1';
                        flag_cout = '1';
                        leds <= "1111";
                    else leds <= std_logic_vector(num1);
                    end if;
                    -- Showing the singal of the result, if 0 is positive, if 1 is negative
                    if num11 < '0' then
                        flag_sign <= '1';
                    elsif num1 = '0' then
                        flag_zero <= '1';
                    end if;
                
                -- Subtraction
                elsif operation = "0011" then
                    -- Converting to integer and subtracting
                    num1 <= unsigned(val1) - unsigned(val2);
                    -- Treating the result
                    if num1 > 15 or num1 < -15 then
                        flag_overf = '1';
                        flag_cout = '1';
                        leds <= "1111";
                    else leds <= std_logic_vector(num1);
                    end if;
                    -- Showing the signal of the result, same as in the addition operation
                    if num1 < '0' then
                        flag_sign <= '1';
                    elsif num1 = '0' then
                        flag_zero <= '1';
                    end if;
                
                -- Greater
                elsif operation = "0110" then
                -- Verifying the greater value and returning it
                    if (val1 > val2) then
                        leds <= val1;
                    else
                        leds <= val2;
                    end if;
                
                -- Smaller
                elsif operation = "0111" then
                -- Verifying the smaller value and returning it
                    if (val1 < val2) then
                        leds <= val1;
                    else
                        leds <= val2;
                    end if;
				end if;
>>>>>>> Stashed changes
        
        --clear state
        else
            -- Cleaning all operations and values to recieve more
            leds <= "0000";
            extra <= "0000";
            state <= "00";
            operation <= "0000";
        end if;
    end process;
end main;



