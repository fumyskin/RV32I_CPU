library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionFetcher is
port (
    clock: in std_logic;
    reset: in std_logic;
    curr_pc: in std_logic_vector(10 downto 0);
    enable_next_pc: in std_logic;
    curr_instruction: out std_logic_vector(31 downto 0);
    reg_pc: out std_logic_vector(10 downto 0)
);
end entity InstructionFetcher;

architecture Behavioral of InstructionFetcher is
    signal s_curr_pc: std_logic_vector(10 downto 0);
begin
    BRAMInstance : InstructionMemory
    port map(
        clock => clock,
        read_enable => enable_next_pc,
        address => s_curr_pc,
        data_out => curr_instruction
    );

    process(clock, reset)
    begin
        if rising_edge(clock) and enable_next_pc = '1' then
            s_curr_pc <= curr_pc;
        elsif reset = '1' then
            s_curr_pc <= (others => '0');
        end if;
    end process;
    reg_pc <= s_curr_pc;
end Behavioral;
