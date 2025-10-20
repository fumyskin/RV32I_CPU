library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity FMAWriteBuffer is 
generic(
    FMA_NUM: integer := 3;
    WORD_LENGTH: integer := 16; -- length of words 
    LINE_LENGTH: integer := 96 -- ie, 6 words that the line can accept (for 3 FMA blocks, line is flushed once every 2 cycles )
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
    line_valid: out std_logic

);
end FMAWriteBuffer;

architecture Behavioral of FMAWriteBuffer is

    -- function to define the line WRITE_BUFFER_OUTPUT
    -- phrase = FMA_NUM * WORD_LENGTH (a long string of )
    function WRITE_BUFFER_OUTPUT(
        FMA_ID  : integer;
        PHRASE  : integer
    ) return integer is
    begin
        return (phrase * fma_num * word_length) + (fma_id * word_length);
    end function;

    signal phrase_in        : integer range 0 to 3 := 0;
    signal increment_phrase : std_logic;
    signal line_out_reg     : std_logic_vector(3*WORD_LENGTH*FMA_NUM - 1 downto 0) := (others => '0');
    signal line_valid_reg   : std_logic := '0';

    -- main idea: we get the fma_output data (results of fma blocks)
    -- and place them into the line out output as a single string of data to feed the frame buffer with
    begin

        -- MUX increment_phrase to correct default output
        increment_phrase <= '1' when unsigned(fma_valid_out)/= 0  else '0';

        process(clk)
        begin
            if rising_edge(clk) then
                if(rst = '1') then
                    line_valid <= '0';
                    phrase_in <= 0;
                    line_out <= (others => '0');
                else 
                    if (phrase_in /= 3) then
                        if(increment_phrase = '1') then
                            phrase_in <= phrase_in + 1;
                            if (phrase_in = 2) then
                                line_valid <= '1';
                            end if; -- When the module has just finished collecting the third phrase (phrases 0, 1, and 2), sets lined_valid
                            for i in 0 to FMA_NUM-1 loop
                                line_out(
                                        WRITE_BUFFER_OUTPUT(i, phrase_in) + WORD_LENGTH - 1 downto
                                        WRITE_BUFFER_OUTPUT(i, phrase_in)
                                ) <= fma_out((i+1)*WORD_LENGTH - 1 downto i*WORD_LENGTH);
                            end loop;
                        end if;
                    end if;
                end if;

                line_valid <= '0';
                phrase_in <= 0;
                line_out <= (others => '0');
            end if;
        end process;

end Behavioral;
