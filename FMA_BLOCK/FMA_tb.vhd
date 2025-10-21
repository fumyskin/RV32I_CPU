library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- TESTBENCH TO VERIFY WHETHER MULTIPLICATIONS USING FIXED SIZE ARE OK
entity FMA_tb is
end FMA_tb;

architecture sim of FMA_tb is

    constant LENGTH: integer := 16;  -- width of floating point numbers coming in
    constant EXPONENT: integer := 10; -- width of exponent

    -- Clock period
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz

    -- DUT signals
    signal clk: std_logic := '0';
    signal rst: std_logic := '0';

    signal abc_input: std_logic_vector(3*LENGTH-1 downto 0) := (others => '0');
    signal valid_in: std_logic := '0';
    signal c_valid_in: std_logic := '0';
    signal output_can_be_valid_in: std_logic := '0';
    signal out_val: std_logic_vector(LENGTH-1 downto 0) := (others => '0');
    signal valid_out: std_logic := '0';

begin
    -- Instantiate DUT
    FMAEntity: entity work.FMA
        port map (
            clk => clk,
            rst => rst,
            abc_input => abc_input,
            valid_in => valid_in,
            c_valid_in => c_valid_in,
            output_can_be_valid_in => output_can_be_valid_in,
            out_val => out_val,
            valid_out => valid_out
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

        -- idea: TEST FMA operation on a single FMA block
        -- send an abc string values to valid and see what happens 
        abc_input   <= x"BBBBB634CDDD";   -- first abc numbers
        valid_in <= '1';  
        c_valid_in <= '1';
        output_can_be_valid_in <= '1';
        wait for 20 ns;

        -- End simulation
        wait;
    end process;

end sim;

