library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


-- FMA module: takes in from FMA buffer and computes a * b + c
entity FMA is
    generic (
        LENGTH: integer := 16;  -- width of floating point numbers coming in
        EXPONENT: int3eger := 10 -- width of exponent
    );
    port(
        clk: in std_logic;
        rst: in std_logic;

        abc_input: in std_logic_vector(3*LENGTH-1 downto 0);
        valid_in: in std_logic;  -- to verify valid input
        c_valid_in: in std_logic;
        output_can_be_valid_in: in std_logic;
        out_val: out std_logic_vector(LENGTH-1 downto 0);
        valid_out: out std_logic

    );

end FMA;

architecture Behavioral of FMA is 

    constant INTEGER_ARITHMETIC: std_logic :=  '0'; -- '1' = integer mode, '0' = fixed point
    -- internal signals
    signal a_internal, b_internal: signed(LENGTH-1 downto 0) := (others => '0');
    signal mult_full_precision: signed(2*LENGTH-1 downto 0);

    signal a, b, c: signed(LENGTH-1 downto 0);
    signal chosen_a: signed(LENGTH-1 downto 0);
    signal chosen_b: signed(LENGTH-1 downto 0);
    signal chosen_c: signed(LENGTH-1 downto 0);

    signal out_reg: signed(LENGTH-1 downto 0) := (others => '0');
    signal valid_reg: std_logic := '0';


    begin
        -- split abc into a, b, c
        a <= signed(abc_input(3*LENGTH-1 downto 2*LENGTH));
        b <= signed(abc_input(2*LENGTH-1 downto 1*LENGTH));
        c <= signed(abc_input(1*LENGTH-1 downto 0));

        -- choose current or stored inputs
        chosen_a <= a when valid_in = '1' else a_internal;
        chosen_b <= b when valid_in = '1' else b_internal;
        chosen_c <= c when c_valid_in = '1' else out_reg;

        -- Multiply a*b
        mult_full_precision <= chosen_a * chosen_b;

        process(clk)
        -- To multiply two floating point number we first convert them into integers and then 
        -- we shift as many decimal places as the EXPONENT variable
        -- eg: 
        --  a * b = (a*2^f) * (b*2^f) * 2^(-2f)    [equivalent rewriting of operation in integer form]
        --  = a' * b' * 2^(-2f)                    [ a' and b' are integers now]
        --  = a' * b' * 2^(-f)                     [ a', b' get multiplied by the fixed point ]
        --
        -- hence:
        -- out <= (a_internal * b_internal ) >> FIXED_POINT + c


        begin
            if rising_edge(clk) then
                if rst = '1' then
                    a_internal <= (others => '0');
                    b_internal <= (others => '0');

                    out_reg <= (others => '0');
                    valid_reg <= '0';
                else
                    if valid_in = '1' then 
                        if INTEGER_ARITHMETIC = '1' then 
                            out_reg <= resize(mult_full_precision(LENGTH-1 downto 0), LENGTH) + chosen_c;
                        else 
                            out_reg <= resize(shift_right(mult_full_precision, EXPONENT), LENGTH) + chosen_c;
                        end if;
                    end if;
                
                    -- Store inputs when valid
                    if valid_in = '1' then
                        a_internal <= a;
                        b_internal <= b;
                    end if;

                    -- Output valid only when new inputs are accepted and external output is allowed
                    if (valid_in = '1') and (output_can_be_valid_in = '1') then
                        valid_reg <= '1';
                    else
                        valid_reg <= '0';
                    end if;
                end if;
            end if;
        end process;

        -- Assign outputs
        out_val <= std_logic_vector(out_reg);
        valid_out <= valid_reg;


end architecture;