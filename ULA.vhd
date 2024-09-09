entity ULA is
    Port (
        keys    : in bit_vector (3 downto 0);
        clock   :   in bit;
        leds  :   out bit_vector (3 downto 0);
        flag_zero   :   out std_logic;
        flag_sign   :   out std_logic;
        flag_overf  :   out std_logic;
        flag_cout   :   out std_logic
        );
end ULA;

architecture main of ULA is

    component inversor
    end component inversor;

    component sum
    end component sum;

    component subtraction
    end component subtraction;

    component shift
    end component shift;

    component compl2
    end component compl2;
    
    component max
    end component max;
    
    component min
    end component min;

    component parity
    end component parity;