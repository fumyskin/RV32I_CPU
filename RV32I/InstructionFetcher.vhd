library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionFetcher is
port (
    clock: in std_logic;
    reset: in std_logic;
    enable_fetch: in std_logic;
    curr_pc: in std_logic_vector(31 downto 0);

    curr_instruction: out std_logic_vector(31 downto 0);
    reg_pc: out std_logic_vector(31 downto 0)
);
end entity InstructionFetcher;

architecture behaviour of InstructionFetcher is
    signal s_mem_addr: std_logic_vector(10 downto 0);
    signal s_mem_data: std_logic_vector(31 downto 0);
    
    signal s_curr_instruction: std_logic_vector(31 downto 0);
    signal s_reg_pc: std_logic_vector(31 downto 0);

begin
    
    s_mem_addr <= curr_pc(12 downto 2);                             -- each instruction is 4 byte -> can ignore the 2 LSB
    BRAMInstance: entity work.InstructionMemory
    port map(
        clock => clock,
        read_enable => enable_fetch,
        address => s_mem_addr,
        data_out => s_mem_data
    );

    instructionFetch: process(clock, reset)
    begin
        if reset = '1' then
            s_curr_instruction <= (others => '0');
            s_reg_pc <= (others => '0');
        elsif rising_edge(clock) then
            if enable_fetch = '1' then                              -- no pc checks for now
                s_curr_instruction <= s_mem_data;
                s_reg_pc <= std_logic_vector(unsigned(curr_pc) + 4);
            end if;
        end if;
    end process;
    
    curr_instruction <= s_curr_instruction;
    reg_pc <= s_reg_pc;
end architecture;