library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FlagsChecker_testbench is
end entity FlagsChecker_testbench ;

architecture Behavioral of FlagsChecker_testbench is
    signal clk_tb: std_logic := '0';
    signal rst_tb: std_logic := '0';
    signal rs_tb: std_logic_vector(31 downto 0) := (others => '0');
    signal flags_tb: std_logic_vector(1 downto 0) := (others => '0');
begin 
    uut: entity work.FlagsChecker
    port map(
        clk => clk_tb,
        rst => rst_tb,
        r => rs_tb,
        flags => flags_tb        
    );

    clk_process: process is
        constant clk_period: time := 5 ns;
    begin
        while now < 1000 ns loop
            clk_tb <= not clk_tb after clk_period / 2;
            wait for clk_period / 2;
        end loop;
        wait;
    end process;
    
    stim_process: process
        variable test_num : integer := 1;
    begin
        rs_tb <= x"0000000A";           -- flags = "00"
        wait until rising_edge(clk_tb);
        rs_tb <= x"00000000";           -- flags = "01"
        wait until rising_edge(clk_tb);
        rs_tb <= x"80000000";           -- flags = "10"
        wait until rising_edge(clk_tb);
        rs_tb <= x"0000000A";           -- flags = "00"
        wait until rising_edge(clk_tb);
        wait;
    end process stim_process;
end architecture Behavioral;