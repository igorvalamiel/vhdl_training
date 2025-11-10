-- Listing 8.4
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity key2hex is
	port (
	key_code: in std_logic_vector(7 downto 0);
	ascii_code: out std_logic_vector(9 downto 0)
	);
end key2hex;

architecture arch of key2ascii is
	begin
        with key_code select
        ascii_code <=
            "00"&X"41" when "01000001", -- A
            "00"&X"41" when "01100001", -- a
            "00"&X"42" when "01000010", -- B
            "00"&X"42" when "01100010", -- b
            "00"&X"43" when "01000011", -- C
            "00"&X"43" when "01100011", -- c
            "00"&X"44" when "01000100", -- D
            "00"&X"44" when "01100100", -- d
            "00"&X"45" when "01000101", -- E
            "00"&X"45" when "01100101", -- e
            "00"&X"46" when "01000110", -- F
            "00"&X"46" when "01100110", -- f
            "00"&X"47" when "01000111", -- G
            "00"&X"47" when "01100111", -- g
            "00"&X"48" when "01001000", -- H
            "00"&X"48" when "01101000", -- h
            "00"&X"49" when "01001001", -- I
            "00"&X"49" when "01101001", -- i
            "00"&X"4A" when "01001010", -- J
            "00"&X"4A" when "01101010", -- j
            "00"&X"4B" when "01001011", -- K
            "00"&X"4B" when "01101011", -- k
            "00"&X"4C" when "01001100", -- L
            "00"&X"4C" when "01101100", -- l
            "00"&X"4D" when "01001101", -- M
            "00"&X"4D" when "01101101", -- m
            "00"&X"4E" when "01001110", -- N
            "00"&X"4E" when "01101110", -- n
            "00"&X"4F" when "01001111", -- O
            "00"&X"4F" when "01101111", -- o
            "00"&X"50" when "01010000", -- P
            "00"&X"50" when "01110000", -- p
            "00"&X"51" when "01010001", -- Q
            "00"&X"51" when "01110001", -- q
            "00"&X"52" when "01010010", -- R
            "00"&X"52" when "01110010", -- r
            "00"&X"53" when "01010011", -- S
            "00"&X"53" when "01110011", -- s
            "00"&X"54" when "01010100", -- T
            "00"&X"54" when "01110100", -- t
            "00"&X"55" when "01010101", -- U
            "00"&X"55" when "01110101", -- u
            "00"&X"56" when "01010110", -- V
            "00"&X"56" when "01110110", -- v
            "00"&X"57" when "01010111", -- W
            "00"&X"57" when "01110111", -- w
            "00"&X"58" when "01011000", -- X
            "00"&X"58" when "01111000", -- x
            "00"&X"59" when "01011001", -- Y
            "00"&X"59" when "01111001", -- y
            "00"&X"5A" when "01011010", -- Z  
            "00"&X"5A" when "01111010", -- z   
            "00"&X"23" when others; -- #
end arch;
