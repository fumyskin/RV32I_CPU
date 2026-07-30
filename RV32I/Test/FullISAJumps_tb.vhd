library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.common.all;

entity FullISAJumps_tb is
end entity FullISAJumps_tb;

architecture behaviour of FullISAJumps_tb is
    constant CLOCK_PERIOD : time := 10 ns;
    constant TEST_CYCLES : integer := 6;
    signal RV32I_OPERATION : string(1 to 22);

    signal clock: std_logic := '0';
    signal reset: std_logic := '1';

    signal s_tb_branch_misprediction: std_logic;
    signal s_tb_branch_offset: std_logic_vector(31 downto 0);
    signal s_tb_jump_jalr_pc: std_logic_vector(31 downto 0);
    signal s_tb_branch_prediction: std_logic;
    signal s_tb_curr_instruction: std_logic_vector(31 downto 0);
    signal s_tb_jump_jalr_value: std_logic_vector(31 downto 0);
    
    signal s_tb_next_pc_1: std_logic_vector(31 downto 0) := (others => '0');
    signal s_tb_next_pc_2: std_logic_vector(31 downto 0) := (others => '0');
    signal s_tb_next_pc_3: std_logic_vector(31 downto 0) := (others => '0');



    signal s_tb_rs1_addr: std_logic_vector(4 downto 0) := (others => '0');
    signal s_tb_rs1_value: std_logic_vector(31 downto 0);
    signal s_tb_rs2_addr: std_logic_vector(4 downto 0) := (others => '0');
    signal s_tb_rs2_value: std_logic_vector(31 downto 0);
    signal s_tb_rd_addr: std_logic_vector(4 downto 0) := (others => '0');
    signal s_tb_immediate: std_logic_vector(31 downto 0);
    signal s_tb_instruction_class: INST_CLASS_T;
    signal s_tb_ALU_OP: ALU_OP_T;
    signal s_tb_MEM_OP: MEM_OP_T;
    signal s_tb_MEM_OP_SIZE: MEM_OP_SIZE_T;
    signal s_tb_OP_SIGN: OP_SIGN_T;
    signal s_tb_BRANCH_OP_COND: BRANCH_OP_COND_T;
    signal s_tb_usage_mem: std_logic;
    signal s_tb_usage_writeback: std_logic;
    signal s_tb_regs_dump: REG_MEMORY_T;

    signal s_tb_ieout_rs1_addr_out: std_logic_vector(4 downto 0);
    signal s_tb_ieout_rs1_value_out: std_logic_vector(31 downto 0);
    signal s_tb_ieout_rs2_addr_out: std_logic_vector(4 downto 0);
    signal s_tb_ieout_rs2_value_out: std_logic_vector(31 downto 0);
    signal s_tb_ieout_rd_addr_out: std_logic_vector(4 downto 0);
    signal s_tb_ieout_rd_value_out: std_logic_vector(31 downto 0);
    signal s_tb_ieout_mem_addr_out: std_logic_vector(31 downto 0);
    signal s_tb_ieout_MEM_OP_out: MEM_OP_T;
    signal s_tb_ieout_MEM_OP_SIZE_out: MEM_OP_SIZE_T;
    signal s_tb_ieout_OP_SIGN_out: OP_SIGN_T;
    signal s_tb_ieout_usage_mem_out: std_logic;
    signal s_tb_ieout_usage_writeback_out: std_logic;

    signal s_tb_memout_pipe_writeback_enable_out: std_logic;
    signal s_tb_memout_pipe_writeback_addr_out: std_logic_vector(4 downto 0);
    signal s_tb_memout_pipe_writeback_value_out: std_logic_vector(31 downto 0);
    signal s_tb_memout_rs1_addr_out: std_logic_vector(4 downto 0);
    signal s_tb_memout_rs1_value_out: std_logic_vector(31 downto 0);
    signal s_tb_memout_rs2_addr_out: std_logic_vector(4 downto 0);
    signal s_tb_memout_rs2_value_out: std_logic_vector(31 downto 0);
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
    
    InstructionFetcherEntity: entity work.InstructionFetcher
    port map(
        clock => clock,
        reset => reset,
        enable_fetch => '1',
        branch_misprediction => s_tb_branch_misprediction,
        branch_offset => s_tb_branch_offset, 
        jump_jalr_pc => s_tb_jump_jalr_pc, 
        branch_prediction => s_tb_branch_prediction, 
        curr_instruction => s_tb_curr_instruction, 
        reg_pc => s_tb_next_pc_1
    );

    instructionDecoderEntity: entity work.InstructionDecoder
    port map(
        clock => clock,
        reset => reset,
        curr_instruction => s_tb_curr_instruction,
        next_pc => s_tb_next_pc_1,
        branch_prediction => s_tb_branch_prediction,
        pipe_writeback_enable => s_tb_memout_pipe_writeback_enable_out,
        pipe_writeback_addr => s_tb_memout_pipe_writeback_addr_out,
        pipe_writeback_value => s_tb_memout_pipe_writeback_value_out,
        rs1_addr => s_tb_rs1_addr,
        rs1_value => s_tb_rs1_value,
        rs2_addr => s_tb_rs2_addr,
        rs2_value => s_tb_rs2_value,
        rd_addr => s_tb_rd_addr,
        immediate => s_tb_immediate,
        instruction_class => s_tb_instruction_class,
        ALU_OP => s_tb_ALU_OP,
        MEM_OP => s_tb_MEM_OP,
        MEM_OP_SIZE => s_tb_MEM_OP_SIZE,
        OP_SIGN => s_tb_OP_SIGN,
        jump_jalr_value => s_tb_jump_jalr_value,
        branch_misprediction => s_tb_branch_misprediction,
        branch_offset => s_tb_branch_offset,
        usage_mem => s_tb_usage_mem,
        usage_writeback => s_tb_usage_writeback,
        reg_pc => s_tb_next_pc_2,
        regs_dump => s_tb_regs_dump
    );
    
    instructionExecutionEntity: entity work.InstructionExecution
    port map(
        clock => clock,
        reset => reset,
        next_pc => s_tb_next_pc_2,
        rs1_addr => s_tb_rs1_addr,
        rs1_value => s_tb_rs1_value,
        rs2_addr => s_tb_rs2_addr,
        rs2_value => s_tb_rs2_value,
        rd_addr => s_tb_rd_addr,
        immediate => s_tb_immediate,
        instruction_class => s_tb_instruction_class,
        ALU_OP => s_tb_ALU_OP,
        MEM_OP => s_tb_MEM_OP,
        MEM_OP_SIZE => s_tb_MEM_OP_SIZE,
        OP_SIGN => s_tb_OP_SIGN,
        usage_mem => s_tb_usage_mem,
        usage_writeback => s_tb_usage_writeback,
        rs1_addr_out => s_tb_ieout_rs1_addr_out,
        rs1_value_out => s_tb_ieout_rs1_value_out,
        rs2_addr_out => s_tb_ieout_rs2_addr_out,
        rs2_value_out => s_tb_ieout_rs2_value_out,
        rd_addr_out => s_tb_ieout_rd_addr_out,
        rd_value_out => s_tb_ieout_rd_value_out,
        reg_pc => s_tb_next_pc_3,
        mem_addr_out => s_tb_ieout_mem_addr_out,
        MEM_OP_out => s_tb_ieout_MEM_OP_out,
        MEM_OP_SIZE_out => s_tb_ieout_MEM_OP_SIZE_out,
        OP_SIGN_out => s_tb_ieout_OP_SIGN_out,
        usage_mem_out => s_tb_ieout_usage_mem_out,
        usage_writeback_out => s_tb_ieout_usage_writeback_out
    );
    
    memoryAccessEntity: entity work.MemoryAccess
    port map(
        clock => clock,
        reset => reset,
        rs1_addr_in => s_tb_ieout_rs1_addr_out,
        rs1_value_in => s_tb_ieout_rs1_value_out,
        rs2_addr_in => s_tb_ieout_rs2_addr_out,
        rs2_value_in => s_tb_ieout_rs2_value_out,
        rd_addr_in => s_tb_ieout_rd_addr_out,
        rd_value_in => s_tb_ieout_rd_value_out,
        next_pc => s_tb_next_pc_3,
        usage_mem_in => s_tb_ieout_usage_mem_out,
        mem_addr_in => s_tb_ieout_mem_addr_out,
        MEM_OP_in => s_tb_ieout_MEM_OP_out,
        MEM_OP_SIZE_in => s_tb_ieout_MEM_OP_SIZE_out,
        OP_SIGN_in => s_tb_ieout_OP_SIGN_out,
        usage_writeback_in => s_tb_ieout_usage_writeback_out,
        rs1_addr_out => s_tb_memout_rs1_addr_out,
        rs1_value_out => s_tb_memout_rs1_value_out,
        rs2_addr_out => s_tb_memout_rs2_addr_out,
        rs2_value_out => s_tb_memout_rs2_value_out,
        pipe_writeback_enable_out => s_tb_memout_pipe_writeback_enable_out,   
        pipe_writeback_addr_out => s_tb_memout_pipe_writeback_addr_out,
        pipe_writeback_value_out => s_tb_memout_pipe_writeback_value_out
    );

    instructionExecutionTest:process
    begin
        RV32I_OPERATION <= "RESET                 ";
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        reset <= '0';
        -- RV32I_OPERATION <= "addi x1, x0, 5        ";
        
        -- RV32I_OPERATION <= "addi x2, x0, 5        ";
        
        -- RV32I_OPERATION <= "addi x3, x0, 3        ";
        
        -- RV32I_OPERATION <= "nop                 ";                -- "padding" instructions for data hazard prevention
        
        -- RV32I_OPERATION <= "nop                 ";                -- "padding" instructions for data hazard prevention
        
        -- RV32I_OPERATION <= "beq  x1, x2, 8      ";                -- Branch taken (5 == 5)
        
        -- RV32I_OPERATION <= "addi x4, x0, 1        ";                -- SKIPPED by branch taken
        
        -- RV32I_OPERATION <= "addi x4, x0, 2        ";
        
        -- RV32I_OPERATION <= "beq  x1, x3, 8      ";                -- Branch NOT taken (5 != 3, falls through)
        
        -- RV32I_OPERATION <= "addi x5, x0, 3        ";
        
        -- RV32I_OPERATION <= "addi x5, x0, 4        ";
        
        -- RV32I_OPERATION <= "jal  x0, 12         ";                -- Unconditional jump forward
        
        -- RV32I_OPERATION <= "addi x6, x0, 6        ";                -- SKIPPED by JAL
        
        -- RV32I_OPERATION <= "addi x6, x0, 7        ";                -- SKIPPED by JAL
        
        -- RV32I_OPERATION <= "addi x6, x0, 8        ";
        
        -- RV32I_OPERATION <= "addi x7, x0, 76       ";
        
        -- RV32I_OPERATION <= "nop                 ";                -- "padding" instructions for data hazard prevention
        
        -- RV32I_OPERATION <= "jalr x0, 0(x7)      ";                -- Jump to absolute address in x7 (index 18)
        
        -- RV32I_OPERATION <= "addi x8, x0, 9        ";
        
        -- expected register values: ([o] -> to fix, [x] -> correct)
        -- [x]  x0 -> 0
        -- [x]  x1 -> 5
        -- [x]  x2 -> 5
        -- [x]  x3 -> 3
        -- [x]  x4 -> 2
        -- [x]  x5 -> 4
        -- [x]  x6 -> 8
        -- [x]  x7 -> 76
        -- [x]  x8 -> 9
        -- [x]  x9 -> 0
        wait;
    end process;

end architecture;