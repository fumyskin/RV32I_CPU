library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity FMAWriteBuffer is 
generic(
    FMA_NUM: integer := 3;
    WORD_LENGTH: integer := 16; -- length of words 
    LINE_LENGTH: integer := 96; -- ie, 6 words that the line can accept (for 3 FMA blocks, line is flushed once every 2 cycles )
);

port(
    clk: in std_logic;
    rst: in std_logic;
    -- inputs
    -- fma_out: a string of length WORD_LENGTH*FMA_NUM that contains the result of product
    -- fma_valid_out: a FMA_NUM of booleans that defines 
    fma_out: in std_logic_vector(WORD_LENGTH*FMA_NUM-1 downto 0); -- is -1 cprrect? to check
    fma_valid_out: in std_logic_vector(FMA_NUM-1 downto 0);

    --outputs
    line_out: out std_logic_vector(3*WORD_LENGTH*FMA_NUM - 1 downto 0);
    line_valid: out std_logic;

);
end FMAWriteBuffer;

architecture Behavioral of FMAWriteBuffer is

    
    -- function to define the line WRITE_BUFFER_OUTPUT
    function WRITE_BUFFER_OUTPUT(
        FMA_ID  : integer;
        PHRASE  : integer;
        FMA_NUM : integer;
        WORD_LENGTH : integer
    ) return integer is
    begin
        return (PHRASE * FMA_NUM * WORD_LENGTH) + (FMA_ID * WORD_LENGTH);
    end function;

    signal phrase_in        : integer range 0 to 3 := 0;
    signal increment_phrase : std_logic;
    signal line_out_reg     : std_logic_vector(3*WORD_LENGTH*FMA_NUM - 1 downto 0) := (others => '0');
    signal line_valid_reg   : std_logic := '0';

    -- main idea: we get the fma_output data and 
    
    begin
        process(clk)
        begin
            if(rst == '1') then
                line_valid <= '0';
                phrase_in <= '0';
                line_out <= '0';
            else 
                if (phrase_in != 4) then
                    if(increment_phrase == '1') then
                        phrase_in <= phrase_in + 1;
                        line_valid <= (phrase_in := 2); -- When the module has just finished collecting the third phrase (phrases 0, 1, and 2), sets lined_valid
                        for i in 0 to FMA_NUM-1 loop
                            WRITE_BUFFER_OUTPUT(i, phrase_in) <= fma_out(i*WORD_LENGTH downto WORD_LENGTH);
                        end loop;
                    end if;
                end if;
            end if;

            line_valid <= '0';
            phrase_in <= '0';
            line_out <= '0';
        end process;

end Behavioral;
