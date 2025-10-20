library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FMAWriteBuffer_tb is
end FMAWriteBuffer_tb;

architecture sim of FMAWriteBuffer_tb is
    generic(
        FMA_NUM: integer := 3;
        WORD_LENGTH: integer := 16; -- length of words 
        LINE_LENGTH: integer := 96; -- ie, 6 words that the line can accept (for 3 FMA blocks, line is flushed once every 2 cycles )
    );

    -- Clock period
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz

    -- DUT signals
    signal clk: std_logic := '0';
    signal rst: std_logic := '0';

    signal fma_out: std_logic_vector(WORD_LENGTH-1 downto 0) := (others => '0');
    signal fma_valid_out: std_logic_vector(WORD_LENGTH*FMA_NUM - 1 downto 0 ) := (others => '0');

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
            line_out => lined_out,
            line_valid => line_valid,
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
        -- Send a COMMAND byte 0xA5
        SPI_DATA   <= x"A5";     -- allow SPI_DATA to be inserted in register in IDLE state
        SPI_EN     <= '1';       -- Then enable SPI
        wait for 50 ns;
        SPI_EN     <= '0';
        wait for 10 us;

        -- Send a DATA byte 0x3C 
        SPI_DATA   <= x"3C";
        SPI_EN     <= '1';       -- Then enable SPI
        wait for 50 ns;
        SPI_EN     <= '0';
        wait for 5 us;

        -- End simulation
        wait;
    end process;

end sim;

