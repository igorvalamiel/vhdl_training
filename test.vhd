-- testando vhdl
-- data: 02/09/2024

-- Libraries

-- Entity
entity test is
    port(
        a   :   in bit;
        b   :   out bit
    );
end entity;

-- Architecture
architecture main of test is
begin
    b <= a+1;
end architecture main;
