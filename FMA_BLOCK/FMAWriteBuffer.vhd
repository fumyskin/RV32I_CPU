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
    fma_out: in std_logic_vector();
    fma_valid_out: in std_logic_vector();


);
end FMAWriteBuffer;

architecture Behavioral of FMAWriteBuffer is

    -- function to define the line WRITE_BUFFER_OUTPUT
    --
    function WRITE_BUFFER_OUTPUT(
        FMA_ID  : integer;
        PHRASE  : integer;
        FMA_NUM : integer;
        WORD_LENGTH : integer
    ) return integer is
    begin
        return (PHRASE * FMA_NUM * WORD_LENGTH) + (FMA_ID * WORD_LENGTH);
    end function;



    begin

end Behavioral;
