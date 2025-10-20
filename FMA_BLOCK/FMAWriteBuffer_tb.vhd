library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FMAWriteBuffer_tb is
end FMAWriteBuffer_tb;

architecture sim of FMAWriteBuffer_tb is
    
    constant FMA_NUM: integer := 3;
    constant WORD_LENGTH: integer := 16; -- length of words 
    constant LINE_LENGTH: integer := 96; -- ie, 6 words that the line can accept (for 3 FMA blocks, line is flushed once every 2 cycles )

    -- Clock period
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz

    -- DUT signals
    signal clk: std_logic := '0';
    signal rst: std_logic := '0';

    signal fma_out: std_logic_vector(WORD_LENGTH*FMA_NUM-1 downto 0) := (others => '0');
    signal fma_valid_out: std_logic_vector(FMA_NUM-1 downto 0 ) := (others => '0');

    signal line_out: std_logic_vector(3*WORD_LENGTH*FMA_NUM - 1 downto 0);
    signal line_valid: std_logic := '0';

begin
    -- Instantiate DUT
    FMAWriteBufferEntity: entity work.FMAWriteBuffer
        port map (
            clk => clk,
            rst => rst,
            fma_out => fma_out,
            fma_valid_out => fma_valid_out,
            line_out => line_out,
            line_valid => line_valid
        );

    -- Clock generation
    clk_gen : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    -- Stimulus
    stim_proc : process
    begin
        -- Apply reset
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;

        -- idea: send fma_out array of results (send 3 as FMA_NUM)
        -- then define a temporary fma_valid_out array (actually, define 4 or 5 different types of valids to see what happens)
        -- see what happens on the linout

        -- FIRST TEST
        -- Define a random fma_out hypthetical result string
        -- first batch
        fma_out   <= x"5EAA5EAA5EAA";   -- initialize fma_out
        fma_valid_out <= "101";          -- define whether the fma_blocks are valid or not 
        wait for 50 ns;

        -- second batch 
        fma_out <= x"51AB5EBA2FAA";
        fma_valid_out <= "111";
        wait for 10 us;

        -- End simulation
        wait;
    end process;

end sim;

