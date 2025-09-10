library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionFetcher_tb is
end entity InstructionFetcher_tb;

architecture behaviour of InstructionFetcher_tb is
    constant CLOCK_PERIOD : time := 10 ns;z
    constant TEST_CYCLES : integer := 6;

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
    signal s_enable_fetch: std_logic := '0';
    signal s_curr_pc: std_logic_vector(31 downto 0) := (others => '0');
    signal s_curr_instruction: std_logic_vector(31 downto 0);       -- (no def values for entity-driven signals!)
    signal s_reg_pc: std_logic_vector(31 downto 0);
begin

    clockGenerator:process
    begin
        loop
            clock <= '0';
            wait for CLOCK_PERIOD / 2;
            clock <= '1';
            wait for CLOCK_PERIOD / 2;
        end loop;
    end process;

    instructionFetcherEntity: entity work.InstructionFetcher
    port map(
        clock => clock,
        reset => reset,
        enable_fetch => s_enable_fetch,
        curr_pc => s_curr_pc,
        curr_instruction => s_curr_instruction,
        reg_pc => s_reg_pc
    );

    instructionFetchTest:process
    begin
        reset <= '1';
        s_enable_fetch <= '0';
        wait until rising_edge(clock);
        wait until rising_edge(clock);                              -- double wait as clock starts to 1 (1 wasn't enough)
        
        reset <= '0';
        s_enable_fetch <= '1';
        wait until rising_edge(clock);
        
        for i in 1 to TEST_CYCLES loop                              -- just keep going while pc is updated linearly (+4 per loop) inside InstructionFetcher
            wait until rising_edge(clock);
        end loop;
        
        s_enable_fetch <= '0';
        wait;
    end process;
    s_curr_pc <= s_reg_pc;                                          -- map reg_pc back to curr_pc as the control unit would do (but without checks for branches/jumps)

end architecture;