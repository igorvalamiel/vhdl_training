
library ieee;
use ieee.std_logic_1164.all;

entity ffmem is
  port(
    clk     : in  std_logic;  --clock input
    reset : in  std_logic;  --reset
    state : in std_logic_vector (1 downto 0); --selecionando estado para durar a memoria dos ff
    val  : in  std_logic_vector (3 downto 0);  --valor de entrada para registro
    result  : out std_logic_vector (3 downto 0)); --saída do valor guardado
END ffmem;

architecture mem of ffmem is
  signal f3, f2, f1, f0 : std_logic; -- flipflops
begin
  
  process(clk, reset) -- processando o clock e o reset
  begin
    if(reset = '0') then                           -- verificando se reset esta ligado
      f3 <= '0'; f2 <= '0'; f1 <= '0'; f0 <= '0';    --resetando o valor dos ffs (00)
    elsif(clk'event and clk = '1' and state/="11") then       --verificando se o butão foi pressionado
      if val(3) = '1' then f3 <= '1'; else f3 <= '0'; end if;     --mudando o valor de f3
      if val(2) = '1' then f2 <= '1'; else f2 <= '0'; end if;     --mudando o valor de f2
      if val(1) = '1' then f1 <= '1'; else f1 <= '0'; end if;     --mudando o valor de f1
      if val(0) = '1' then f0 <= '1'; else f0 <= '0'; end if;     --mudando o valor de f0
    end if;
    result <= f3 & f2 & f1 & f0;
  end process;
  
end mem;