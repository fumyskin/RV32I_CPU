library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.common.ALL;

entity InstructionExecution is
    port(
        clock: in std_logic;
        reset: in std_logic;

        next_pc: in std_logic_vector(31 downto 0);
        rs1_addr: in std_logic_vector(4 downto 0);
        rs1_value: in std_logic_vector(31 downto 0);
        rs2_addr: in std_logic_vector(4 downto 0);
        rs2_value: in std_logic_vector(31 downto 0);
        rd_addr: in std_logic_vector(4 downto 0);
        immediate: in std_logic_vector(31 downto 0);
        instruction_class: in INST_CLASS_T;
        ALU_OP: in ALU_OP_T;
        MEM_OP: in MEM_OP_T;
        MEM_OP_SIZE: in MEM_OP_SIZE_T;
        OP_SIGN: in OP_SIGN_T;
        BRANCH_OP_COND: in BRANCH_OP_COND_T;
        usage_jump: in std_logic;
        usage_alu: in std_logic;
        usage_mem: in std_logic;
        usage_writeback: in std_logic;
        pipe_pc_changer: in std_logic;

        rs1_addr_out: out std_logic_vector(4 downto 0);
        rs1_value_out: out std_logic_vector(31 downto 0);
        rs2_addr_out: out std_logic_vector(4 downto 0);
        rs2_value_out: out std_logic_vector(31 downto 0);
        rd_addr_out: out std_logic_vector(4 downto 0);
        rd_value_out: out std_logic_vector(31 downto 0);
        mem_addr_out: out std_logic_vector(31 downto 0);
        MEM_OP_out: out MEM_OP_T;
        MEM_OP_SIZE_out: out MEM_OP_SIZE_T;
        OP_SIGN_out: out OP_SIGN_T;
        usage_mem_out: out std_logic;
        usage_writeback_out: out std_logic;
        
        pipe_async_alu_result: out std_logic_vector(31 downto 0);
        pipe_use_new_pc: out std_logic;
        pipe_new_pc: out std_logic_vector(31 downto 0)
    );
end entity InstructionExecution;

architecture behaviour of InstructionExecution is
    signal s_alu_result: std_logic_vector(31 downto 0);
    signal s_rd_value: std_logic_vector(31 downto 0); 
    signal s_branch_taken: std_logic;
    signal s_new_pc: std_logic_vector(31 downto 0);
begin
    --  it needs to:
    --      recognize and check for any branch/jump operations [DONE]
    --      recognize and apply the ALU operation [DONE]
    --      define the memory address to be used for load/store operations [DONE]
    --      pass down the registers values [DONE]

    synchronousExecutionLogic: process(clock, reset)
        variable v_rs1_signed_value: signed(31 downto 0);
        variable v_rs1_unsigned_value: unsigned(31 downto 0);
        variable v_rs2_signed_value: signed(31 downto 0);
        variable v_rs2_unsigned_value: unsigned(31 downto 0);
        variable v_shift_amount: integer range 0 to 31;
        variable v_immediate_signed: signed(31 downto 0);
        variable v_immediate_unsigned: unsigned(31 downto 0);
        variable v_next_pc_unsigned: unsigned(31 downto 0);
        variable v_branch_taken: std_logic;
    begin
        if reset = '1' then
            rs1_addr_out <= (others => '0');
            rs1_value_out <= (others => '0');
            rs2_addr_out <= (others => '0');
            rs2_value_out <= (others => '0');
            rd_addr_out <= (others => '0');
            s_rd_value <= (others => '0');
            s_alu_result <= (others => '0');
            mem_addr_out <= (others => '0');
            MEM_OP_out <= OP_LOAD;
            MEM_OP_SIZE_out <= OP_SIZE_WORD;
            OP_SIGN_out <= OP_UNSIGNED;
            usage_mem_out <= '0';
            s_new_pc <= (others => '0');
            usage_writeback_out <= '0';
            pipe_use_new_pc <= '0';

        elsif rising_edge(clock) then
            rs1_addr_out <= rs1_addr;
            rs1_value_out <= rs1_value;
            rs2_addr_out <= rs2_addr;
            rs2_value_out <= rs2_value;
            rd_addr_out <= rd_addr;
            usage_mem_out <= usage_mem;
            MEM_OP_out <= MEM_OP;
            MEM_OP_SIZE_out <= MEM_OP_SIZE;
            OP_SIGN_out <= OP_SIGN;
            usage_writeback_out <= usage_writeback;

            v_rs1_signed_value := signed(rs1_value);
            v_rs1_unsigned_value := unsigned(rs1_value);
            v_rs2_signed_value := signed(rs2_value);
            v_rs2_unsigned_value := unsigned(rs2_value);
            v_immediate_signed := signed(immediate);
            v_immediate_unsigned := unsigned(immediate);
            v_next_pc_unsigned := unsigned(next_pc);
            if usage_alu = '1' then                
                if instruction_class = INST_CLASS_I or instruction_class = INST_CLASS_U then
                    v_rs2_signed_value := v_immediate_signed;
                    v_rs2_unsigned_value := v_immediate_unsigned;
                end if;
                
                v_shift_amount := to_integer(v_rs2_unsigned_value(4 downto 0));
                               
                case ALU_OP is
                    when OP_ADD => 
                        s_alu_result <= std_logic_vector(v_rs1_unsigned_value + v_rs2_unsigned_value);
                    when OP_SUB => 
                        s_alu_result <= std_logic_vector(v_rs1_unsigned_value - v_rs2_unsigned_value);
                    when OP_AND => 
                        s_alu_result <= std_logic_vector(v_rs1_unsigned_value and v_rs2_unsigned_value);
                    when OP_OR => 
                        s_alu_result <= std_logic_vector(v_rs1_unsigned_value or v_rs2_unsigned_value);
                    when OP_XOR => 
                        s_alu_result <= std_logic_vector(v_rs1_unsigned_value xor v_rs2_unsigned_value);
                    when OP_SLL => 
                        s_alu_result <= std_logic_vector(v_rs1_unsigned_value sll v_shift_amount);
                    when OP_SRL => 
                        s_alu_result <= std_logic_vector(v_rs1_unsigned_value srl v_shift_amount);
                    when OP_SRA => 
                        s_alu_result <= std_logic_vector(v_rs1_signed_value sra v_shift_amount);
                    when OP_SLT => 
                        if (v_rs1_signed_value < v_rs2_signed_value) then
                            s_alu_result <= (others => '0');
                        else
                            s_alu_result <= x"00000001";
                        end if;
                    when OP_SLTU => 
                        if (v_rs1_unsigned_value < v_rs2_unsigned_value) then
                            s_alu_result <= (others => '0');
                        else
                            s_alu_result <= x"00000001";
                        end if;
                    when OP_LUI => 
                        s_alu_result <= std_logic_vector((v_rs2_unsigned_value sll 12));
                    when OP_AUIPC => 
                        s_alu_result <= AdderFunction(UNSIGNED_UNSIGNED, next_pc, std_logic_vector(rs2_value sll 12));
                    when OP_MEM =>
                        s_alu_result <= AdderFunction(UNSIGNED_SIGNED, std_logic_vector(v_rs1_unsigned_value), std_logic_vector(v_immediate_signed));
                        mem_addr_out <= s_alu_result;
                    when others => 
                        s_alu_result <= (others => '0');
                end case;
                s_rd_value <= s_alu_result;
            end if;

            pipe_use_new_pc <= '0';
            if pipe_pc_changer = '1' then
                s_new_pc <= (others => '0');
                v_branch_taken := '0';
                if instruction_class = INST_CLASS_R then
                    v_branch_taken := '0';
                    case BRANCH_OP_COND is
                        when OP_BRANCH_EQ => 
                            v_branch_taken := '1' when rs1_value = rs2_value else '0';
                        when OP_BRANCH_NE => 
                            v_branch_taken := '1' when rs1_value /= rs2_value else '0';
                        when OP_BRANCH_LT => 
                            v_branch_taken := '1' when v_rs1_signed_value < v_rs2_signed_value else '0';
                        when OP_BRANCH_GE => 
                            v_branch_taken := '1' when v_rs1_signed_value >= v_rs2_signed_value else '0';
                        when OP_BRANCH_LTU => 
                            v_branch_taken := '1' when v_rs1_unsigned_value < v_rs2_unsigned_value else '0';
                        when OP_BRANCH_GEU => 
                            v_branch_taken := '1' when v_rs1_unsigned_value >= v_rs2_unsigned_value else '0';
                        when others => 
                            v_branch_taken := '0';
                    end case;

                    if v_branch_taken = '1' then
                        pipe_use_new_pc <= '1';
                        s_new_pc <= AdderFunction(UNSIGNED_SIGNED, next_pc, immediate);
                    end if;
                
                elsif instruction_class = INST_CLASS_J and (ALU_OP = OP_JAL) then
                    pipe_use_new_pc <= '1';
                    s_new_pc <= AdderFunction(UNSIGNED_SIGNED, next_pc, immediate);
                    s_rd_value <= next_pc;                                  -- rd = (PC+4)
                    
                elsif instruction_class = INST_CLASS_I and (ALU_OP = OP_JALR) then
                    pipe_use_new_pc <= '1';
                    s_new_pc <= AdderFunction(UNSIGNED_SIGNED, rs1_value, immediate);
                    s_new_pc(0) <= '0';                                     -- address alignment
                    s_rd_value <= next_pc;
                end if;
            end if;
        end if;
    end process;

    pipe_async_alu_result <= s_alu_result;
    pipe_new_pc <= s_new_pc;
    rd_value_out <= s_rd_value;
end behaviour;