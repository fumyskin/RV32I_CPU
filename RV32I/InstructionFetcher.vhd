library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionFetcher is
port (
    clock: in std_logic;
    reset: in std_logic;
    enable_fetch: in std_logic;
    is_pc_changer: in std_logic;                                    -- decode returned a "possible" Branch (or Jump) instruction
    pipe_pc_changer_done: in std_logic;
    pipe_use_new_pc: in std_logic;
    pipe_new_pc: in std_logic_vector(31 downto 0);
    -- when a Jump or Branch instruction is fetched the pipe is stalled (doesn't fetch anything)
    --  Jump case: 
    --      the pipe will wait until the MEM stage ends (3 wait cycles expected) to get the new PC as the writeback is used (check for possible bypass)
    --  Branch case:
    --      the pipe will wait only for the async process in IE to finish (2 wait cycles expected)
    curr_instruction: out std_logic_vector(31 downto 0);
    reg_pc: out std_logic_vector(31 downto 0)
);
end entity InstructionFetcher;

architecture behaviour of InstructionFetcher is
    type bram_t is array (0 to 2047) of std_logic_vector(31 downto 0);
    signal bram : bram_t := (                                       -- define some random words to be able to test the entities
        0 => x"00700093",                                           -- x1 = 7
        1 => x"00800113",                                           -- x2 = 8
        2 => x"00900193",                                           -- x3 = 9
        3 => x"00A00213",                                           -- x4 = A
        4 => x"00B00293",                                           -- x5 = B
        5 => x"0020a4b3",                                           -- x9 = (x1<x2)?1:0
        6 => x"04302023",                                           -- mem[0x40] = x3
        7 => x"00C00313",                                           -- x6 = C
        8 => x"0020A3B3",                                           -- x7 = (x1<x2)?1:0
        9 => x"00C00313",                                           -- x6 = C
        10 => x"04002083",                                          -- x1 = mem[0x40]
        11 => x"0080056F",                                          -- (x10 = PC) & (PC = PC+12)    [instruction address: 0x2c]
        12 => x"FFFFFFFF",
        13 => x"FFFFFFFF",
        14 => x"00C00093",                                          -- x1 = C                       [instruction address: 0x38]
        15 => x"00B00113",                                          -- x2 = B
        16 => x"00A00193",                                          -- x3 = A
        17 => x"00900213",                                          -- x4 = 9
        18 => x"00800293",                                          -- x5 = 8
        others => (others => '0')                                   -- keep the other cells to 0
    );
    signal s_mem_addr: std_logic_vector(10 downto 0);
    
    signal s_curr_instruction: std_logic_vector(31 downto 0);
    signal s_pc: std_logic_vector(31 downto 0) := (others => '0');
begin
    
    s_mem_addr <= s_pc(12 downto 2);                                -- each instruction is 4 byte -> can ignore the 2 LSB
    instructionFetch: process(clock, reset)
        variable  v_pc: std_logic_vector(31 downto 0) := (others => '0');
        variable  v_next_pc: std_logic_vector(31 downto 0) := (others => '0');
        variable  v_curr_instruction: std_logic_vector(31 downto 0) := (others => '0');
    begin
        if reset = '1' then
            s_curr_instruction <= (others => '0');
            s_pc <= (others => '0');
            curr_instruction <= (others => '0');
            reg_pc <= (others => '0');
        elsif rising_edge(clock) then
            -- check if a custom PC is specified
            -- use that (new) one or the one from s_pc (previous one)
            -- fetch the instruction from the bram
            -- output the new instruction with the next_pc ([custom pc | previous pc] + 4)
            if enable_fetch = '1' then
                if pipe_pc_changer_done = '1' and pipe_use_new_pc = '1' then
                    v_pc := pipe_new_pc;
                else
                    -- if pipe_pc_changer_done = '1' and pipe_use_new_pc = '0' then
                    v_pc := s_pc;
                end if;
                if is_pc_changer = '0' then
                    v_next_pc := std_logic_vector(unsigned(v_pc) + 4);
                    v_curr_instruction := bram(to_integer(unsigned(v_pc(12 downto 2))));
                    curr_instruction <= v_curr_instruction;
                    s_pc <= v_next_pc;
                    reg_pc <= v_next_pc;
                else
                    -- just wait
                    null;
                end if;
            end if;
        end if;
    end process;
end architecture;