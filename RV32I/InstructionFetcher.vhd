library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionFetcher is
port (
    clock: in std_logic;
    reset: in std_logic;
    enable_fetch: in std_logic;
    use_new_pc: in std_logic;
    new_pc: in std_logic_vector(31 downto 0);

    curr_instruction: out std_logic_vector(31 downto 0);
    reg_pc: out std_logic_vector(31 downto 0)
);
end entity InstructionFetcher;

architecture behaviour of InstructionFetcher is
    type bram_t is array (0 to 2047) of std_logic_vector(31 downto 0);
    signal bram : bram_t := (                                       -- define some random words to be able to test the entities
        0 => x"00700093",
        1 => x"00800113",
        2 => x"00900193",
        3 => x"00A00213",
        4 => x"00B00293",
        5 => x"0020a4b3",
        6 => x"04302023",
        7 => x"00C00313",
        8 => x"0020A3B3",
        9 => x"00C00313",
        10 => x"04002083",
        others => (others => '0')                                   -- keep the other cells to 0
    );
    signal s_mem_addr: std_logic_vector(10 downto 0);
    
    signal s_curr_instruction: std_logic_vector(31 downto 0);
    signal s_reg_pc: std_logic_vector(31 downto 0) := (others => '0');
    signal s_pc: std_logic_vector(31 downto 0) := (others => '0');
begin
    
    s_mem_addr <= s_pc(12 downto 2);                            -- each instruction is 4 byte -> can ignore the 2 LSB
    instructionFetch: process(clock, reset)
        variable  v_pc: std_logic_vector(31 downto 0) := (others => '0');
        variable  v_curr_instruction: std_logic_vector(31 downto 0) := (others => '0');
    begin
        if reset = '1' then
            s_curr_instruction <= (others => '0');
            s_reg_pc <= (others => '0');
            s_pc <= (others => '0');
            curr_instruction <= (others => '0');
            reg_pc <= (others => '0');
        elsif rising_edge(clock) then
            if enable_fetch = '1' then                              -- no pc checks for now
                if use_new_pc = '1' then
                    v_pc := new_pc; 
                else
                    v_pc := s_pc;
                end if;
                v_curr_instruction := bram(to_integer(unsigned(v_pc(12 downto 2))));
                v_pc := std_logic_vector(unsigned(v_pc) + 4);
                s_pc <= v_pc;
                s_reg_pc <= v_pc;
                reg_pc <= v_pc;

                reg_pc <= s_reg_pc;
                curr_instruction <= v_curr_instruction;
            end if;
        end if;
    end process;
end architecture;