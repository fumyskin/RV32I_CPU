library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.common.ALL;

entity InstructionExecution is
    port(
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

        usage_mem_out: out std_logic;
        mem_addr_out: out std_logic_vector(31 downto 0);
        MEM_OP_out: out MEM_OP_T;
        MEM_OP_SIZE_out: out MEM_OP_SIZE_T;
        OP_SIGN_out: out OP_SIGN_T;
        usage_writeback_out: out std_logic;

        pipe_alu_result: out std_logic_vector(31 downto 0);
        pipe_use_new_pc: out std_logic;
        pipe_new_pc: out std_logic_vector(31 downto 0);
        reg_pc: out std_logic_vector(31 downto 0)
    );
end entity InstructionExecution;

architecture behaviour of InstructionExecution is
    signal s_rd_value: std_logic_vector(31 downto 0);
    signal s_pipe_branch_taken: std_logic;
    signal s_pipe_use_new_pc: std_logic;
    signal s_pipe_new_pc: std_logic_vector(31 downto 0);
    signal s_mem_addr: std_logic_vector(31 downto 0);
begin
    --  it needs to:
    --      recognize and check for any branch/jump operations [DONE]
    --      recognize and apply the ALU operation [DONE]
    --      define the memory address to be used for load/store operations [DONE]
    --      pass down the registers values [DONE]

    flowControlExecution:process(instruction_class, pipe_pc_changer) is
        variable v_pipe_branch_taken: std_logic;
        variable v_rd_value: std_logic_vector(31 downto 0);
        variable v_pipe_new_pc: std_logic_vector(31 downto 0);
        variable v_pipe_use_new_pc: std_logic;
    begin
        if pipe_pc_changer = '1' then
            v_pipe_use_new_pc := '1';
            if instruction_class = B then
                v_pipe_branch_taken := '0';
                case(BRANCH_OP_COND) is
                    when OP_BRANCH_EQ =>
                        v_pipe_branch_taken := (rs1_value xnor rs2_value);
                    when OP_BRANCH_NE =>
                        v_pipe_branch_taken := (rs1_value xor rs2_value);
                    when OP_BRANCH_LT =>
                        if OP_SIGN = OP_SIGNED then
                            v_pipe_branch_taken := (signed(rs1_value) < signed(rs2_value));
                        else
                            v_pipe_branch_taken := (unsigned(rs1_value) < unsigned(rs2_value));
                        end if;
                    when OP_BRANCH_GE =>
                        if OP_SIGN = OP_SIGNED then
                            v_pipe_branch_taken := (signed(rs1_value) >= signed(rs2_value));
                        else
                            v_pipe_branch_taken := (unsigned(rs1_value) >= unsigned(rs2_value));
                        end if;
                end case;
                if v_pipe_branch_taken = '1' then
                    v_pipe_new_pc := resize((unsigned(immediate) + resize(unsigned(next_pc), 32)), 11);
                else
                    v_pipe_use_new_pc := '0';
                end if;

            elsif instruction_class = J then
                v_rd_value:= next_pc;
                v_pipe_new_pc := resize((unsigned(immediate) + resize(unsigned(next_pc), 32)), 11);

            elsif instruction_class = I then                        -- JALR -> I class but pipe_pc_changer = 1
                v_rd_value:= next_pc;
                v_pipe_new_pc:= resize((unsigned(immediate) + unsigned(rs1_value)), 11);
            end if;

            s_rd_value <= v_rd_value;
            s_pipe_new_pc <= v_pipe_new_pc;
            s_pipe_branch_taken <= v_pipe_branch_taken;
            s_pipe_use_new_pc <= v_pipe_use_new_pc;
        end if;
    end process flowControlExecution;

    aluInstructionExecution:process(instruction_class, usage_alu, ALU_OP) is
        variable v_rs1_signed_value: signed(31 downto 0);
        variable v_rs1_unsigned_value: unsigned(31 downto 0);
        variable v_rs2_signed_value: signed(31 downto 0);
        variable v_rs2_unsigned_value: unsigned(31 downto 0);
        variable v_rd_value: unsigned(31 downto 0);
        variable v_shift_amount: integer range 0 to 32;
    begin
        if usage_alu = '1' then
            v_rs1_signed_value:= signed(rs1_value);
            v_rs1_unsigned_value:= unsigned(rs1_value);
            if instruction_class = I then
                v_rs2_signed_value:= signed(immediate);
                v_rs2_unsigned_value:= unsigned(immediate);
            elsif instruction_class = R then
                v_rs2_signed_value:= signed(rs2_value);
                v_rs2_unsigned_value:= unsigned(rs2_value);
            end if;
            v_shift_amount:= to_integer(v_rs2_unsigned_value(4 downto 0));

            case(ALU_OP) is
                when OP_ADD =>
                    v_rd_value:= v_rs1_signed_value + v_rs2_signed_value;
                when OP_SUB =>
                    v_rd_value:= v_rs1_signed_value - v_rs2_signed_value;
                when OP_AND =>
                    v_rd_value:= v_rs1_unsigned_value and v_rs2_unsigned_value;
                when OP_OR =>
                    v_rd_value:= v_rs1_unsigned_value or v_rs2_unsigned_value;
                when OP_XOR =>
                    v_rd_value:= v_rs1_unsigned_value xor v_rs2_unsigned_value;
                when OP_SLL =>
                    v_rd_value:= std_logic_vector(v_rs1_unsigned_value sll v_shift_amount);
                when OP_SRL =>
                    v_rd_value:= std_logic_vector(v_rs1_unsigned_value srl v_shift_amount);
                when OP_SRA =>
                    v_rd_value:= std_logic_vector(v_rs1_signed_value sra v_shift_amount);
                when OP_SLT =>
                    if (v_rs1_signed_value < v_rs2_signed_value) then
                        v_rd_value := (others => '0');
                    else
                        v_rd_value := (others => '0') & '1';
                    end if;
                when OP_SLTU =>
                    if (v_rs1_unsigned_value < v_rs2_unsigned_value) then
                        v_rd_value := (others => '0');
                    else
                        v_rd_value := (others => '0') & '1';
                    end if;
                when OP_LUI =>
                    v_rd_value:= (immediate sll 12);
                when OP_AUIPC =>
                    v_rd_value:= std_logic_vector((next_pc-4) + (immediate sll 12));
                when others => null;
            end case;
        s_rd_value <= v_rd_value;
        end if;
    end process aluInstructionExecution;

    memoryAccessDefinition:process(usage_mem) is
    begin
        if usage_mem = '1' then
            s_mem_addr <= std_logic_vector(unsigned(rs1_value)+unsigned(immediate));
        end if;
    end process memoryAccessDefinition;

    rs1_addr_out <= rs1_addr;
    rs1_value_out <= rs1_value;
    rs2_addr_out <= rs2_addr;
    rs2_value_out <= rs2_value;
    rd_addr_out <= rd_addr;
    rd_value_out <= s_rd_value;

    usage_mem_out <= usage_mem;
    mem_addr_out <= s_mem_addr;
    MEM_OP_out <= MEM_OP;
    MEM_OP_SIZE_out <= MEM_OP_SIZE;
    OP_SIGN_out <= OP_SIGN;
    usage_writeback_out <= usage_writeback;

    pipe_alu_result <= s_rd_value;
    pipe_use_new_pc <= s_pipe_use_new_pc;
    pipe_new_pc <= s_pipe_new_pc;
    reg_pc <= next_pc;
end behaviour;