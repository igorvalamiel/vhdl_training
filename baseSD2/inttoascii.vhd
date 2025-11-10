-- Listing 8.4
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity key2ascii is
	port (
	ita_entry: in integer;
	ita_ascii: out std_logic_vector(9 downto 0)
	);
	end key2ascii;

architecture arch of key2ascii is
	begin
	with ita_key_code select
	ita_ascii <=
	"00110000" when 0, -- 0
	"00110001" when 1, -- 1
	"00110010" when 2, -- 2
	"00110011" when 3, -- 3
	"00110100" when 4, -- 4
	"00110101" when 5, -- 5
	"00110110" when 6, -- 6
	"00110111" when 7, -- 7
	"00111000" when 8, -- 8
	"00111001" when 9, -- 9
	"00101010" when others; -- *
end arch;
