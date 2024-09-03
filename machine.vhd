-- tentando adiantar o código para o lab de SD

entity machine is
    port(
        entry   :   in bit_vector 3 downto 0;
        keys    :   in bit_vector 7 downto 4;
        outleds  :   out bit_vector 3 downto 0;
        extra   :   out bit_vector 7 downto 4
    );
end entity;

architecture inverter of machine is
    begin
        outleds <= not entry;
end inverter;

architecture compl2 of machine is
    begin
        outleds <= (not entry) + 1
end compl2;

