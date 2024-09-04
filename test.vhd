-- estudo baseado no site https://balbertini.github.io/
-- testando vhdl
-- data: 02/09/2024

-- Libraries

-- Entity
entity mux2to1 is
    port(
        s:  in bit; --selector
        a, b: in bit_vector(1 downto 0); -- inputs of 2 bits
        o: out bit_vector(1 downto 0) -- output of 2 bits
    );
end mux2to1;

-- Architecture
architecture whenelse of mux2to1 is
begin
    o <= b when s='1' else a;
end whenelse;

architecture struct of mux2to1 is
begin
    o(0) <= (a(0) and not(s)) or (b(0) and s);
    o(1) <= (a(1) and not(s)) or (b(1) and s);
end struct;