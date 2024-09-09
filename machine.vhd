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
            
        --Input value 2
        elsif state = "10" then
            val2 <= keys;
            state <= '11';
        
        --clear state
        else
            leds <= "0000";
            extra <= "0000";
            state <= "00";
            operation <= "0000";
        end if;
    end process;
end main;



