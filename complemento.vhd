library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity complemento is
    Port(
        keys : in bit_vector (3 downto 0);
        leds : out bit_vector (3 downto 0);
        cout : out integer;
    );
    end complemento;

architecture behavorial of paridade is 
    process(keys)
    if keys = '0000' then leds <= '0000';
    cout <= '1';
    else
        C <= not keys;
        if C(0) and '1' = 1 then
            C <= C(0) or '1';
            if C(1) and '1' = 1 then
                C <= C(1) or '1';
                if C(2) and '1' = 1 then
                    C <= C(2) or '1';
                    if C(3) and '1' then
                        C <=C(3) or '1';
                        leds <= C;
                    else
                        leds <= C;
                else
                    leds <= C;
            else
            leds <= C;
        else
        leds <= C;
        cout <= '0';