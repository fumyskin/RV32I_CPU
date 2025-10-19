library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.common.all;

entity InstructionExecution_tb is
end entity InstructionExecution_tb;

architecture behaviour of InstructionExecution_tb is
    constant CLOCK_PERIOD : time := 10 ns;
    constant TEST_CYCLES : integer := 6;
    signal RV32I_OPERATION : string(1 to 22);

    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
    
    signal s_tb_curr_instruction: std_logic_vector(31 downto 0) := (others => '0');
    signal s_tb_next_pc: std_logic_vector(31 downto 0) := (others => '0');
    signal s_tb_pipe_writeback_enable: std_logic := '0';
    signal s_tb_pipe_writeback_addr: std_logic_vector(4 downto 0) := (others => '0');
    signal s_tb_pipe_writeback_value: std_logic_vector(31 downto 0) := (others => '0');
    signal s_tb_pipe_res_alu: std_logic_vector(31 downto 0) := (others => '0');
    signal s_tb_pipe_res_mem: std_logic_vector(31 downto 0) := (others => '0');
    signal s_tb_pipe_res_rs1_selection: std_logic_vector(1 downto 0) := (others => '0');
    signal s_tb_pipe_res_rs2_selection: std_logic_vector(1 downto 0) := (others => '0');
    
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
    signal s_tb_usage_jump: std_logic;
    signal s_tb_usage_alu: std_logic;
    signal s_tb_usage_mem: std_logic;
    signal s_tb_usage_writeback: std_logic;
    signal s_tb_pipe_pc_changer: std_logic;
    signal s_tb_reg_pc: std_logic_vector(31 downto 0) := (others => '0');
    
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
    signal s_tb_ieout_pipe_use_new_pc: std_logic;
    signal s_tb_ieout_pipe_new_pc: std_logic_vector(31 downto 0);
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
    
    instructionDecoderEntity: entity work.InstructionDecoder
    port map(
        clock => clock,
        reset => reset,
        curr_instruction => s_tb_curr_instruction,
        next_pc => s_tb_next_pc,
        pipe_writeback_enable => s_tb_pipe_writeback_enable,        -- this writeback will be used by the pipe (linking the WriteBack stage to InstructionDecoder)
        pipe_writeback_addr => s_tb_pipe_writeback_addr,            -- it's not used in this test for this reason, writeback signals for operations results are generated in InstructionDecoder
        pipe_writeback_value => s_tb_pipe_writeback_value,
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
        usage_jump => s_tb_usage_jump,
        usage_alu => s_tb_usage_alu,
        usage_mem => s_tb_usage_mem,
        usage_writeback => s_tb_usage_writeback,
        pipe_pc_changer => s_tb_pipe_pc_changer,
        reg_pc => s_tb_reg_pc
    );

    instructionExecutionEntity: entity work.InstructionExecution
    port map(
        clock => clock,
        reset => reset,
        
        next_pc => s_tb_reg_pc,
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
        usage_jump => s_tb_usage_jump,
        usage_alu => s_tb_usage_alu,
        usage_mem => s_tb_usage_mem,
        usage_writeback => s_tb_usage_writeback,
        pipe_pc_changer => s_tb_pipe_pc_changer,

        rs1_addr_out => s_tb_ieout_rs1_addr_out,
        rs1_value_out => s_tb_ieout_rs1_value_out,
        rs2_addr_out => s_tb_ieout_rs2_addr_out,
        rs2_value_out => s_tb_ieout_rs2_value_out,
        rd_addr_out => s_tb_ieout_rd_addr_out,
        rd_value_out => s_tb_ieout_rd_value_out,
        mem_addr_out => s_tb_ieout_mem_addr_out,
        MEM_OP_out => s_tb_ieout_MEM_OP_out,
        MEM_OP_SIZE_out => s_tb_ieout_MEM_OP_SIZE_out,
        OP_SIGN_out => s_tb_ieout_OP_SIGN_out,
        usage_mem_out => s_tb_ieout_usage_mem_out,
        usage_writeback_out => s_tb_ieout_usage_writeback_out,
        pipe_use_new_pc => s_tb_ieout_pipe_use_new_pc,
        pipe_new_pc => s_tb_ieout_pipe_new_pc
    );

    instructionExecutionTest:process                                -- it was faster and more complete (and even easier, lol) to instantiate and connect both entities
    begin                                                           -- it's the same process as InstructionDecoderTest, just with another entity connected (will check the output signals of InstructionExecution)
        reset <= '1';
        RV32I_OPERATION <= "RESET                 ";
        wait until rising_edge(clock);
        wait until rising_edge(clock);
        reset <= '0';
        
        RV32I_OPERATION <= "addi x1, x0, 7        ";
        s_tb_curr_instruction <= x"00700093";
        s_tb_next_pc <= x"00000004";
        s_tb_pipe_writeback_enable <= '0';
        s_tb_pipe_writeback_addr <= (others => '0');
        s_tb_pipe_writeback_value <= (others => '0');
        s_tb_pipe_res_alu <= x"80000008";
        s_tb_pipe_res_mem <= x"70000007";
        s_tb_pipe_res_rs1_selection <= "00";
        s_tb_pipe_res_rs2_selection <= "00";
        wait until rising_edge(clock);
        
        RV32I_OPERATION <= "addi x2, x0, 8        ";
        s_tb_curr_instruction <= x"00800113";
        s_tb_next_pc <= x"00000008";
        s_tb_pipe_writeback_enable <= '0';
        s_tb_pipe_res_alu <= x"90000009";
        s_tb_pipe_res_mem <= x"80000008";
        s_tb_pipe_res_rs1_selection <= "00";
        s_tb_pipe_res_rs2_selection <= "00";
        wait until rising_edge(clock);

        -- RV32I_OPERATION <= "addi x3, x5, x6       ";
        -- s_tb_curr_instruction <= x"006281b3";
        -- s_tb_next_pc <= x"0000000c";
        -- s_tb_pipe_writeback_enable <= '1';                          -- test the writeback procedure for the pipe
        -- s_tb_pipe_writeback_addr <= "10000"; 
        -- s_tb_pipe_writeback_value <= x"00000005";
        -- s_tb_pipe_res_alu <= x"00000001";
        -- s_tb_pipe_res_mem <= x"00000002";
        -- s_tb_pipe_res_rs1_selection <= "01"; 
        -- s_tb_pipe_res_rs2_selection <= "10"; 
        -- wait until rising_edge(clock);

        -- RV32I_OPERATION <= "xor x18, x1, x2       ";
        -- s_tb_curr_instruction <= x"0020c933";
        -- s_tb_next_pc <= x"00000010";
        -- s_tb_pipe_writeback_enable <= '0';
        -- s_tb_pipe_res_rs1_selection <= "00";
        -- s_tb_pipe_res_rs2_selection <= "00";
        -- wait until rising_edge(clock);

        RV32I_OPERATION <= "slt x4, x1, x2        ";
        s_tb_curr_instruction <= x"0020a233";
        s_tb_next_pc <= x"00000014";
        wait until rising_edge(clock);

        RV32I_OPERATION <= "lh x5, 96(x1)         ";
        s_tb_curr_instruction <= x"06009283";
        s_tb_next_pc <= x"00000018";
        wait until rising_edge(clock);

        -- RV32I_OPERATION <= "sh x5, 104(x18)       ";
        -- s_tb_curr_instruction <= x"06591423";
        -- s_tb_next_pc <= x"0000001c";
        -- s_tb_pipe_writeback_enable <= '0';
        -- wait until rising_edge(clock);

        -- RV32I_OPERATION <= "blt x4, x3, 128       ";
        -- s_tb_curr_instruction <= x"08324063";
        -- s_tb_next_pc <= x"00000020";
        -- s_tb_pipe_writeback_enable <= '0';
        -- wait until rising_edge(clock);

        -- RV32I_OPERATION <= "jalr x19, 120(x16)    ";
        -- s_tb_curr_instruction <= x"078809e7";
        -- s_tb_next_pc <= x"00000024";
        -- wait until rising_edge(clock);
        
        wait;
    end process;

end architecture;