
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity paridade is
    Port (
        keys    : in bit_vector (3 downto 0);
      	count 	: out integrer;
    );
end paridade;

architecture Behavioral of paridade is
  process(keys)
  variable count2: INTEGER := 0;
  begin
       for i in 0 to 3 loop
         if	keys(i) = '1' then count2:= count2 + 1;
  		end if;            
  end loop;  
  count <= count2;
end Behavioral;
  
  
 
