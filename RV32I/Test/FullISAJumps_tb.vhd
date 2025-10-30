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
    
    signal s_tb_next_pc_1: std_logic_vector(31 downto 0) := (others => '0');
    signal s_tb_next_pc_2: std_logic_vector(31 downto 0) := (others => '0');
    signal s_tb_next_pc_3: std_logic_vector(31 downto 0) := (others => '0');
    signal s_tb_curr_instruction: std_logic_vector(31 downto 0);
    signal s_tb_async_branch_not_taken: std_logic := '0';
    signal s_tb_is_pc_changer: std_logic := '0';

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
    signal s_tb_pipe_is_pc_changer: std_logic;
    signal s_tb_pipe_pc_changer_op: std_logic;

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

    signal s_tb_pipe_pc_changer_done: std_logic;
    signal s_tb_pipe_new_pc: std_logic_vector(31 downto 0);
    signal s_tb_pipe_use_new_pc: std_logic;

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
        is_pc_changer => s_tb_pipe_is_pc_changer,
        pipe_pc_changer_done => s_tb_pipe_pc_changer_done,
        pipe_use_new_pc => s_tb_pipe_use_new_pc,
        pipe_new_pc => s_tb_pipe_new_pc,
        curr_instruction => s_tb_curr_instruction,
        reg_pc => s_tb_next_pc_1
    );

    instructionDecoderEntity: entity work.InstructionDecoder
    port map(
        clock => clock,
        reset => reset,
        curr_instruction => s_tb_curr_instruction,
        next_pc => s_tb_next_pc_1,
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
        BRANCH_OP_COND => s_tb_BRANCH_OP_COND,
        usage_mem => s_tb_usage_mem,
        usage_writeback => s_tb_usage_writeback,
        pipe_is_pc_changer => s_tb_pipe_is_pc_changer,
        pipe_pc_changer_op => s_tb_pipe_pc_changer_op,
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
        BRANCH_OP_COND => s_tb_BRANCH_OP_COND,
        usage_mem => s_tb_usage_mem,
        usage_writeback => s_tb_usage_writeback,
        pipe_pc_changer => s_tb_pipe_pc_changer_op,

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
        usage_writeback_out => s_tb_ieout_usage_writeback_out,
        pipe_pc_changer_done => s_tb_pipe_pc_changer_done,
        pipe_use_new_pc => s_tb_pipe_use_new_pc,
        pipe_new_pc => s_tb_pipe_new_pc
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
        
        -- RV32I_OPERATION <= "addi x1, x0, 7        ";
        
        -- RV32I_OPERATION <= "addi x2, x0, 8        ";
        
        -- RV32I_OPERATION <= "addi x3, x0, 9        ";
        
        -- RV32I_OPERATION <= "addi x4, x0, 10       ";
        
        -- RV32I_OPERATION <= "addi x5, x0, 11       ";
        
        -- RV32I_OPERATION <= "slt x9, x1, x2        ";
        
        -- RV32I_OPERATION <= "sw x3, 64(x0)         ";                -- Write x3 value (9 dec) to byte address 040hex (64dec) in 3 clock cycles
        
        -- RV32I_OPERATION <= "addi x6, x0, 12       ";                -- "padding" instructions as there's no control of pipe hazards (yet)
        
        -- RV32I_OPERATION <= "slt x7, x1, x2        ";
        
        -- RV32I_OPERATION <= "addi x6, x0, 12       ";
        
        -- RV32I_OPERATION <= "lw x1, 64(x0)         ";                -- the value 09 is expected in the register x1 after 4 clock cycles 
        
        -- expected register values: ([o] -> to fix, [x] -> correct)
        -- [x]  x0 -> 0
        -- [x]  x1 -> 7 |>  9
        -- [x]  x2 -> 8
        -- [x]  x3 -> 9
        -- [x]  x4 -> a
        -- [x]  x5 -> b
        -- [x]  x6 -> c |> c
        -- [x]  x7 -> 1
        -- [x]  x8 -> 0
        -- [x]  x9 -> 1
        wait;
    end process;

end architecture;