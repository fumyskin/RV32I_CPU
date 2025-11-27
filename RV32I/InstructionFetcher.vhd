library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- TODO - test the new control-flow blocks :)

entity InstructionFetcher is
port (
    clock: in std_logic;
    reset: in std_logic;
    enable_fetch: in std_logic;
    branch_misprediction: in std_logic;
    branch_offset: in std_logic_vector(31 downto 0);
    jump_jalr_pc: in std_logic_vector(31 downto 0);
    branch_prediction: out std_logic;
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
    signal s_mem_addr: std_logic_vector(10 downto 0) := (others => '0');
    signal s_curr_instruction: std_logic_vector(31 downto 0) := (others => '0');
    signal s_pc: std_logic_vector(31 downto 0) := (others => '0');
    
    signal s_branch_prediction: std_logic := '0';
    signal s_branch_prediction_offset: std_logic_vector(31 downto 0) := (others => '0');
    signal s_branch_pending: std_logic_vector(1 downto 0) := (others => '0');
    signal s_jump_pending: std_logic_vector(1 downto 0) := (others => '0'); -- the numbers of cycles to wait for the jump (normal instructions = "00", JAL = "01", JALR = "11" at first bubble and "10" at second bubble)
    signal s_jump_jal_offset: std_logic_vector(31 downto 0) := (others => '0');
begin
    
    s_mem_addr <= s_pc(12 downto 2);                                -- each instruction is 4 byte -> can ignore the 2 LSB
    instructionFetch: process(clock, reset)
        variable v_pc: std_logic_vector(31 downto 0) := (others => '0');
        variable v_next_pc: std_logic_vector(31 downto 0) := (others => '0');
        variable v_curr_instruction: std_logic_vector(31 downto 0) := (others => '0');
        variable v_curr_opcode: std_logic_vector(6 downto 0) := (others => '0');
        variable v_immediate_13bits: std_logic_vector(12 downto 0) := (others => '0');
        variable v_immediate_21bits: std_logic_vector(20 downto 0) := (others => '0');
        variable v_branch_prediction_taken: std_logic := '0';
        variable v_branch_pending: std_logic_vector(1 downto 0) := (others => '0');
        variable v_mask_instruction: std_logic := '0';
        variable v_pc_offset: std_logic_vector(31 downto 0) := (others => '0');
    begin
        if reset = '1' then
            s_curr_instruction <= (others => '0');
            s_pc <= (others => '0');
            curr_instruction <= (others => '0');
            reg_pc <= (others => '0');
            s_jump_pending <= (others => '0');
            s_jump_jal_offset <= (others => '0');
            s_branch_prediction <= '0';
        elsif rising_edge(clock) then
            if enable_fetch = '1' then
                case (s_jump_pending) is
                    when "01" =>
                        s_jump_pending <= "00";
                        v_pc_offset := std_logic_vector(signed(s_jump_jal_offset) - to_signed(4, 32));

                        -- v_pc_offset :=  (signed(s_jump_jal_offset) - unsigned(4)); -- JAL: PC += imm (-4 to get back to the jump address)
                    when "11" =>
                        s_jump_pending <= "10";
                        v_mask_instruction := '1';
                    when "10" =>                                    -- JALR executed by ID, new PC
                        v_mask_instruction := '0';
                        v_pc_offset := (others => '0');
                        v_pc := jump_jalr_pc;                       -- JALR: PC = rs1+imm
                    when "00" =>
                        v_pc_offset := (others => '0');
                        v_pc := s_pc;
                    when others =>
                        v_pc_offset := (others => '0');
                        null;
                end case;
                case (s_branch_pending) is
                    when "11" =>                                    -- there has been a branch prediction
                        if s_branch_prediction = '1' then           -- the prediction is branch_taken = '1'
                            v_pc_offset := std_logic_vector(signed(s_branch_prediction_offset) - to_signed(4, 32)); -- predicted instruction
                        elsif s_branch_prediction = '0' then        -- expected a regular flow
                            v_pc_offset := (others => '0');
                            v_pc := s_pc;                           -- simply use the next pc
                        end if;
                        s_branch_pending <= "10";                   -- check at the next cycle if the prediction was correct
                    when "10" =>
                        s_branch_pending <= "00";
                        if branch_misprediction = '1' then          -- use directly the offset computed by ID
                            v_pc_offset := branch_offset;           -- take the input offset as it's prepared for any rollback (from next_pc or from branch-pointed_pc)
                        end if;
                    when others =>
                        v_pc_offset := (others => '0');
                        null;
                end case;

                v_pc := std_logic_vector(unsigned(v_pc) + unsigned(v_pc_offset));
                v_next_pc := std_logic_vector(signed(v_pc) + to_signed(4, 32));
                v_curr_instruction := bram(to_integer(unsigned(v_pc(12 downto 2))));
                v_curr_opcode := v_curr_instruction(6 downto 0);
                
                if v_mask_instruction = '1' then
                    v_curr_instruction(6 downto 0) := "0000000";    -- opcode for NOP instruction
                end if;

                case(v_curr_opcode) is
                    when "1101111" => -- JAL
                        v_immediate_21bits := v_curr_instruction(31) & -- imm[20]
                            v_curr_instruction(19 downto 12) &      -- imm[19:12]
                            v_curr_instruction(20) &                -- imm[11]
                            v_curr_instruction(30 downto 21) &      -- imm[10:1]
                            '0';                                    -- imm[0]
                        s_jump_jal_offset <= std_logic_vector(resize(signed(v_curr_instruction), 32)); -- sign-extension for possible negative offsets
                        s_jump_pending <= "01";
                    when "1100111" => -- JALR
                        s_jump_pending <= "11";
                    when "1100011" => -- BR
                        v_branch_pending:= "11";
                        v_branch_prediction_taken := v_curr_instruction(31);  -- negative offset -> branch prediction = taken
                        if v_branch_prediction_taken then                      
                            v_immediate_13bits := v_curr_instruction(31) & -- imm[12]
                                v_curr_instruction(7) &                 -- imm[11]
                                v_curr_instruction(30 downto 25) &      -- imm[10:5]
                                v_curr_instruction(11 downto 8) &       -- imm[4:1]
                                '0';                                    -- imm[0]
                            s_branch_prediction_offset <= std_logic_vector(resize(signed(v_immediate_13bits), 32));
                        end if;
                    when others =>
                        null;
                end case;

                s_pc <= v_next_pc;
                s_branch_pending <= v_branch_pending;
                s_branch_prediction <= v_branch_prediction_taken;
                branch_prediction <= s_branch_prediction;
                curr_instruction <= v_curr_instruction;
                reg_pc <= v_next_pc;
            end if;
        end if;
    end process;
end architecture;