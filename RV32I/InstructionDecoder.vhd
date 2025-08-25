library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.common.ALL;

entity InstructionDecoder is
    port(
        clock: in std_logic;                                        -- mapped directly to the register file (memory)
        curr_instruction: in std_logic_vector(31 downto 0);
        curr_pc: in std_logic_vector(10 downto 0);

        pipe_writeback_enable: in std_logic;                        -- register file, write access from next stages result
        pipe_writeback_addr: in std_logic_vector(4 downto 0);
        pipe_writeback_value: in std_logic_vector(31 downto 0);
        pipe_res_alu: in std_logic_vector(31 downto 0);             -- input needed for hazards in the pipeline 
        pipe_res_mem: in std_logic_vector(31 downto 0);
        pipe_res_selection: in std_logic(1 downto 0);
        -- 00: value from register file,    (use value read from register file)
        -- 01: value from alu result,       (ALU_OP result needed, skip register file)
        -- 10: value from memory result,    (OP_LOAD result needed, skip register file)
        
        
        
        rs1_addr: out std_logic_vector(4 downto 0);
        rs1_value: out std_logic_vector(31 downto 0);
        rs2_addr: out std_logic_vector(4 downto 0);
        rs2_value: out std_logic_vector(31 downto 0);
        rd_addr: out std_logic_vector(4 downto 0);
        immediate: out std_logic_vector(31 downto 0);

        instruction_class: out INST_CLASS_T;
        ALU_OP: out ALU_OP_T;
        MEM_OP: out MEM_OP_T;
        MEM_OP_SIZE: out MEM_OP_SIZE_T;
        OP_SIGN: out OP_SIGN_T;
        BRANCH_OP_COND: out BRANCH_OP_COND_T;

        usage_jump: out std_logic;
        usage_alu: out std_logic;
        usage_mem: out std_logic;
        usage_writeback: out std_logic;
        pipe_pc_changer: out std_logic;                             -- flag to signal the pipe controller that the instruction could change PC (branches and jumps)

        reg_pc: out std_logic_vector(10 downto 0)
    );
end entity InstructionDecoder;
architecture behaviour of InstructionDecoder is
    
    signal s_rs1_addr: std_logic_vector(4 downto 0);
    signal s_rs1_value: std_logic_vector(31 downto 0);
    signal s_rs2_addr: std_logic_vector(4 downto 0);
    signal s_rs2_value: std_logic_vector(31 downto 0);
    signal s_rd_addr: std_logic_vector(4 downto 0);
    signal s_immediate: std_logic_vector(31 downto 0);
    
    signal s_instruction_class: INST_CLASS_T;
    signal s_ALU_OP: ALU_OP_T;
    signal s_MEM_OP: MEM_OP_T;
    signal s_MEM_OP_SIZE: MEM_OP_SIZE_T;
    signal s_OP_SIGN: OP_SIGN_T;
    signal s_BRANCH_OP_COND: BRANCH_OP_COND_T;

    signal s_usage_jump: std_logic;
    signal s_usage_alu: std_logic;
    signal s_usage_mem: std_logic;
    signal s_usage_writeback: std_logic;
    signal s_pipe_pc_changer: std_logic;             

    signal regfile_rs1_addr: std_logic_vector(4 downto 0) := (others => '0');
    signal regfile_rs1_value: std_logic_vector(31 downto 0) := (others => '0');
    signal regfile_rs2_addr: std_logic_vector(4 downto 0) := (others => '0');
    signal regfile_rs2_value: std_logic_vector(31 downto 0) := (others => '0');
    signal regfile_rd_addr: std_logic_vector(4 downto 0) := (others => '0');
    signal regfile_rd_value: std_logic_vector(31 downto 0) := (others => '0');
    signal regfile_read_enable: std_logic := '0';
    signal regfile_write_enable: std_logic := '0';
begin
    RegisterFileInstance: RegisterFile
    port map(
        clock => clock,
        addr_A => regfile_rs1_addr,
        addr_B => regfile_rs2_addr,
        read_enable => regfile_read_enable,
        addr_C => regfile_rd_addr,
        write_C => regfile_rd_value,
        write_enable => regfile_write_enable,
        val_A => regfile_rs1_value,
        val_B => regfile_rs2_value
    );


    decodeInstruction:process(curr_instruction)
        variable v_funct3: std_logic_vector(2 downto 0);
        variable v_funct7: std_logic_vector(6 downto 0);
        variable v_rd_addr: std_logic_vector(4 downto 0);
        variable v_rs1_addr: std_logic_vector(4 downto 0);
        variable v_rs2_addr: std_logic_vector(4 downto 0);
        variable v_rd_value: std_logic_vector(31 downto 0);
        variable v_rs1_value: std_logic_vector(31 downto 0);
        variable v_rs2_value: std_logic_vector(31 downto 0);
        variable v_immediate: std_logic_vector(31 downto 0);
        
        variable v_instruction_class: INST_CLASS_T;
        variable v_ALU_OP: ALU_OP_T;        -- OP_ADD, OP_SUB, ...  (use INST_CLASS=I to check addi, subi, ...)
        variable v_MEM_OP: MEM_OP_T;        -- OP_LOAD, OP_STORE
        variable v_MEM_OP_SIZE: MEM_OP_SIZE_T; -- OP_SIZE_BYTE, OP_SIZE_HALFWORD, OP_SIZE_WORD
        variable v_OP_SIGN: OP_SIGN_T;      -- OP_SIGNED, OP_UNSIGNED (to get lbu, lhu, sltu, ...)
        variable v_BRANCH_OP_COND: BRANCH_OP_COND_T;
        
        variable v_pc_changer: std_logic;
        variable v_usage_jump: std_logic;
        variable v_usage_alu: std_logic;
        variable v_usage_mem: std_logic;
        variable v_usage_writeback: std_logic;
    begin
        -- it needs to do:
        --      recognize the instruction class [DONE]
        --      assign the new aluop type [DONE]
        --      set stages usage (mem_access, alu_usage, write_back) [DONE]
        --      immediate mapping [DONE]
        --      fetch rs1 and rs2 from memory [DONE]
        --      write back rd value [DONE]
        --      map output values [DONE]

        v_rd_addr := curr_instruction(11 downto 7);                 -- pre-map static values (same position in different instruction classes)
        v_funct3 := curr_instruction(14 downto 12);                 -- they are overwritten according to the instruction type
        v_funct7 := curr_instruction(31 downto 25);
        v_rs1_addr := curr_instruction(19 downto 15);
        v_rs2_addr := curr_instruction(24 downto 20);
        
        v_usage_alu := '1';                                         -- set default values (overwritten in some case)
        v_usage_writeback := '1';
        v_usage_mem := '0';
        v_pc_changer := '0';
        v_OP_SIGN := OP_SIGNED;

        case(curr_instruction(6 downto 0)) is                       -- instruction class definition
            when "0110011" =>
                v_instruction_class := R;
            when "0010011" | "0000011" | "1110011" | "1100111"=> 
                v_instruction_class := I;
            when "0100011" =>
                v_instruction_class := S;
            when "1100011" =>
                v_instruction_class := B;
            when "1101111" =>
                v_instruction_class := J;
            when "0110111" | "0010111" =>
                v_instruction_class := U;
            when others =>
                v_instruction_class := ERR
        end case;
        
        case(curr_instruction(6 downto 0)) is                       -- instruction definition
            when "0110011" | "0010011" =>
                v_usage_jump := '0';
                v_usage_alu := '1';
                v_usage_mem := '0';
                v_usage_writeback := '1';  
                case(v_funct3) is
                    when "000" =>
                        if v_instruction_class = R then
                            if v_funct7 = "0000000" then
                                v_ALU_OP:= OP_ADD;
                            elsif v_funct7 = "0010100" then
                                v_ALU_OP:= OP_SUB;
                            end if;
                        elsif v_instruction_class = I then
                            v_ALU_OP:= OP_ADD;
                        end if;
                    when "001" =>
                        v_ALU_OP:= OP_SLL;
                    when "010" =>
                        v_ALU_OP:= OP_SLT;
                    when "011" =>
                        v_ALU_OP:= OP_SLT;
                        v_OP_SIGN:= OP_UNSIGNED;
                    when "100" =>
                        v_ALU_OP:= OP_XOR;
                    when "101" =>
                        if v_instruction_class = R then
                            if v_funct7 = "0000000" then
                                v_ALU_OP:= OP_SRL;
                            elsif v_funct7 = "0010100" then
                                v_ALU_OP:= OP_SRA;
                            end if;
                        elsif v_instruction_class = I then
                            if curr_instruction(31 downto 25) = "0000000" then  -- usage of immediate bits (11 downto 5) as funct7
                                v_ALU_OP:= OP_SRL;
                            elsif curr_instruction(31 downto 25) = "0010100" then
                                v_ALU_OP:= OP_SRA;
                            end if;
                        end if;
                    when "110" =>
                        v_ALU_OP:= OP_OR;
                    when "111" =>
                        v_ALU_OP:= OP_AND;
                end case;
        
            when "0110111" =>
                v_usage_jump := '0';
                v_usage_alu := '1';
                v_usage_mem := '0';
                v_usage_writeback := '1';  
                v_ALU_OP:= OP_LUI;

            when "0010111" =>
                v_usage_jump := '0';
                v_usage_alu := '1';
                v_usage_mem := '0';
                v_usage_writeback := '1';  
                v_ALU_OP:= OP_AUIPC;

            when "0000011" => 
                v_usage_jump := '0';
                v_usage_alu := '0';
                v_usage_mem := '1';
                v_usage_writeback := '1';  
                v_MEM_OP:= OP_LOAD;
                case(v_funct3) is
                    when "000" =>
                        v_MEM_OP_SIZE:= OP_SIZE_BYTE;
                    when "001" =>
                        v_MEM_OP_SIZE:= OP_SIZE_HALFWORD;
                    when "010" =>
                        v_MEM_OP_SIZE:= OP_SIZE_WORD;
                    when "100" =>
                        v_MEM_OP_SIZE:= OP_SIZE_BYTE;
                        v_OP_SIGN:= OP_UNSIGNED;
                    when "101" =>
                        v_MEM_OP_SIZE:= OP_SIZE_HALFWORD;
                        v_OP_SIGN:= OP_UNSIGNED;
                end case;
        
            when "0100011" =>
                v_usage_jump := '0';
                v_usage_alu := '0';
                v_usage_mem := '1';
                v_usage_writeback := '0';  
                v_MEM_OP := OP_STORE;
                case(v_funct3) is
                    when "000" =>
                        v_MEM_OP_SIZE:= OP_SIZE_BYTE;
                    when "001" =>
                        v_MEM_OP_SIZE:= OP_SIZE_HALFWORD;
                    when "010" =>
                        v_MEM_OP_SIZE:= OP_SIZE_WORD;
                end case;
            
            when "1100011" =>
                v_pc_changer := '1';
                v_usage_jump := '0';                                -- there are no active flag for branch operations
                v_usage_alu := '0';
                v_usage_mem := '0';
                v_usage_writeback := '0';  
                case(v_funct3) is
                    when "000" =>
                        v_BRANCH_OP_COND := OP_BRANCH_EQ;
                    when "001" =>
                        v_BRANCH_OP_COND := OP_BRANCH_NE;
                    when "100" =>
                        v_BRANCH_OP_COND := OP_BRANCH_LT;
                    when "101" =>
                        v_BRANCH_OP_COND := OP_BRANCH_GE;
                    when "110" =>
                        v_BRANCH_OP_COND := OP_BRANCH_LT;
                        v_OP_SIGN:= OP_UNSIGNED;
                    when "111" =>
                        v_BRANCH_OP_COND := OP_BRANCH_GE;
                        v_OP_SIGN:= OP_UNSIGNED;
                end case;
            when "1101111" | "1100111" => -- JAL (class J) | JALR (class I)
                v_pc_changer := '1';
                v_usage_jump := '1';
                v_usage_alu := '0';
                v_usage_mem := '0';
                v_usage_writeback := '1';  

        -- when "1110011" =>                                        -- I class but for OS/debug (not yet implemented)
        --     case(v_funct3) is
        --         when "000" =>
        --             -- if imm = 0x0 -> ECALL
        --             -- elif imm = 0x1 -> EBREAK
        --     end case;
        end case;

        case(v_instruction_class) is                                -- immediate mapping
            when R =>
                null;                                               -- immediate not present in R instructions
            when I =>
                case(v_OP_SIGN) is
                    when OP_SIGNED =>
                        v_immediate := std_logic_vector(resize(signed(curr_instruction(31 downto 20)), 32));
                    when OP_UNSIGNED =>
                        v_immediate := std_logic_vector(resize(curr_instruction(31 downto 20)), 32);
                end case;
            when S =>
                case(v_OP_SIGN) is
                    when OP_SIGNED =>
                        v_immediate := std_logic_vector(resize(signed(
                            curr_instruction(31 downto 25) &
                            curr_instruction(11 downto 7)
                        ), 32));
                    when OP_UNSIGNED =>
                        v_immediate := std_logic_vector(resize(
                            curr_instruction(31 downto 25) &
                            curr_instruction(11 downto 7)
                        ), 32);
                end case;
            when B =>
                v_immediate := std_logic_vector(resize(
                    curr_instruction(31) &             -- imm[12]
                    curr_instruction(7) &              -- imm[11]
                    curr_instruction(30 downto 25) &   -- imm[10:5]
                    curr_instruction(11 downto 8) &    -- imm[4:1]
                    '0'                                -- imm[0]
                ), 32);
            when U =>
                v_immediate := std_logic_vector(resize(
                    curr_instruction(31 downto 12) &   -- imm[31:12]
                    x"000"                             -- imm[11:0]
                ), 32);
            when J =>
                v_immediate := std_logic_vector(resize(signed(
                    curr_instruction(31) &             -- imm[20]
                    curr_instruction(19 downto 12) &   -- imm[19:12]
                    curr_instruction(20) &             -- imm[11]
                    curr_instruction(30 downto 21) &   -- imm[10:1]
                    '0'                                -- imm[0]
                ), 32));
            when ERR =>
                v_immediate := (others => '0');
                v_usage_alu := '0';
                v_usage_mem := '0';
                v_usage_writeback := '0';
                v_ALU_OP := OP_ERR;                                 -- signal the invalid instruction
                v_MEM_OP := OP_LOAD;                                -- prevent unwanted store op due to errors
        end case;
        
        case(v_instruction_class) is                                -- asynchronous/immediate registers fetch
            when R | S | B =>
                regfile_rs1_addr <= v_rs1_addr;
                regfile_rs2_addr <= v_rs2_addr;
                regfile_read_enable <= '1';
            when  I =>
                regfile_rs1_addr <= v_rs1_addr;
                regfile_rs2_addr <= "00000";                        -- prevent unwanted readings
                regfile_read_enable <= '1';
            when U | J =>
                regfile_read_enable <= '0';
            when ERR =>
                regfile_rs1_addr <= "00000";
                regfile_rs2_addr <= "00000";
                regfile_read_enable <= '0';
        end case;

        s_instruction_class <= v_instruction_class;                 -- variables to signals mapping
        s_ALU_OP <= v_ALU_OP;
        s_MEM_OP <= v_MEM_OP;
        s_MEM_OP_SIZE <= v_MEM_OP_SIZE;
        s_OP_SIGN <= v_OP_SIGN;
        s_BRANCH_OP_COND <= v_BRANCH_OP_COND;
        s_usage_jump <= v_usage_jump;
        s_usage_alu <= v_usage_alu;
        s_usage_mem <= v_usage_mem;
        s_usage_writeback <= v_usage_writeback;
        s_pipe_pc_changer <= v_pc_changer;
        s_rs1_addr <= v_rs1_addr;
        s_rs1_value <= v_rs1_value;
        s_rs2_addr <= v_rs2_addr;
        s_rs2_value <= v_rs2_value;
        s_rd_addr <= v_rd_addr;
        s_immediate <= v_immediate;

    end process;

    writeBackValue:process(pipe_writeback_enable, pipe_writeback_addr, pipe_writeback_value) is
    begin
        if pipe_writeback_enable = '1' then
            regfile_rd_addr <= pipe_writeback_addr;
            regfile_rd_value <= pipe_writeback_value;
            regfile_write_enable <= '1';
        else
            regfile_rd_addr <= "00000";
            regfile_write_enable <= '0';
        end if;

    end process;

    rs1_addr <= s_rs1_addr;                                         -- output signals mapping
    rs1_value <= s_rs1_value;
    rs2_addr <= s_rs2_addr;
    rs2_value <= s_rs2_value;
    rd_addr <= s_rd_addr;
    immediate <= s_immediate;
    instruction_class <= s_instruction_class;
    ALU_OP <= s_ALU_OP;
    MEM_OP <= s_MEM_OP;
    MEM_OP_SIZE <= s_MEM_OP_SIZE;
    OP_SIGN <= s_OP_SIGN;
    BRANCH_OP_COND <= s_BRANCH_OP_COND;
    usage_jump <= s_usage_jump;
    usage_alu <= s_usage_alu;
    usage_mem <= s_usage_mem;
    usage_writeback <= s_usage_writeback;
    pipe_pc_changer <= s_pc_changer;

    reg_pc <= curr_pc;
end behaviour ;