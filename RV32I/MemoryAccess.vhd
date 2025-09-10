library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MemoryAccess is
port (
    clock: in std_logic;
    reset: in std_logic;
    
    rs1_addr_in: in std_logic_vector(4 downto 0);
    rs1_value_in: in std_logic_vector(31 downto 0);
    rs2_addr_in: in std_logic_vector(4 downto 0);
    rs2_value_in: in std_logic_vector(31 downto 0);
    rd_addr_in: in std_logic_vector(4 downto 0);
    rd_value_in: in std_logic_vector(31 downto 0);

    usage_mem_in: in std_logic;
    mem_addr_in: in std_logic_vector(31 downto 0);
    MEM_OP_in: in MEM_OP_T;
    MEM_OP_SIZE_in: in MEM_OP_SIZE_T;
    OP_SIGN_in: in OP_SIGN_T;
    usage_writeback_in: in std_logic;


    mem_addr_out: out std_logic_vector(31 downto 0);
    mem_data_out: out std_logic_vector(31 downto 0);
    rs1_addr_out: out std_logic_vector(4 downto 0);
    rs1_value_out: out std_logic_vector(31 downto 0);
    rs2_addr_out: out std_logic_vector(4 downto 0);
    rs2_value_out: out std_logic_vector(31 downto 0);
    rd_addr_out: out std_logic_vector(4 downto 0);
    rd_value_out: out std_logic_vector(31 downto 0);
    usage_writeback_out: out std_logic;

    pipe_async_mem_data_out: out std_logic_vector(31 downto 0)
);
end entity MemoryAccess;

architecture behaviour of MemoryAccess is
    signal s_write_enable: std_logic;
    signal s_mem_address: std_logic_vector(19 downto 0);
    signal s_byte_enable: std_logic_vector(3 downto 0);
    signal s_data_in: std_logic_vector(31 downto 0);
    signal s_data_out: std_logic_vector(31 downto 0);
    signal s_masked_data_out: std_logic_vector(31 downto 0);
    signal s_pipe_async_data_out: std_logic_vector(31 downto 0);
    signal s_masked_pipe_async_data_out: std_logic_vector(31 downto 0);
begin
    DataBRAMInstance: entity work.DataMemory
    port map(
        clock => clock,
        reset => reset,
        write_enable => s_write_enable,
        address => s_mem_address,
        byte_enable => s_byte_enable,
        data_in => s_data_in,
        data_out => s_data_out,
        pipe_async_data_out => s_pipe_async_data_out
    );


    loadInstructionMask: process(MEM_OP_SIZE_in, OP_SIGN_in, s_data_out, s_pipe_async_data_out)
    begin
        s_masked_data_out <= (others => '0');
        s_masked_pipe_async_data_out <= (others => '0');

        case(MEM_OP_SIZE_in) is
            when OP_SIZE_BYTE =>
                if OP_SIGN_in = OP_SIGNED then
                    s_masked_data_out <= std_logic_vector(resize(signed(s_data_out(7 downto 0)), 32));
                    s_masked_pipe_async_data_out <= std_logic_vector(resize(signed(s_pipe_async_data_out(7 downto 0)), 32));
                else
                    s_masked_data_out <= std_logic_vector(resize(unsigned(s_data_out(7 downto 0)), 32));
                    s_masked_pipe_async_data_out <= std_logic_vector(resize(unsigned(s_pipe_async_data_out(7 downto 0)), 32));
                end if;
            when OP_SIZE_HALFWORD =>
                if OP_SIGN_in = OP_SIGNED then
                    s_masked_data_out <= std_logic_vector(resize(signed(s_data_out(15 downto 0)), 32));
                    s_masked_pipe_async_data_out <= std_logic_vector(resize(signed(s_pipe_async_data_out(15 downto 0)), 32));
                else
                    s_masked_data_out <= std_logic_vector(resize(unsigned(s_data_out(15 downto 0)), 32));
                    s_masked_pipe_async_data_out <= std_logic_vector(resize(unsigned(s_pipe_async_data_out(15 downto 0)), 32));
                end if;
            when OP_SIZE_WORD =>
                s_masked_data_out <= s_data_out;
                s_masked_pipe_async_data_out <= s_pipe_async_data_out;
            when others =>
                s_masked_data_out <= (others => '0');
                s_masked_pipe_async_data_out <= (others => '0');
        end case;
    end process;

    memoryAccessControl:process(clock, reset)
    begin
        if reset = '1' then
            s_write_enable <= '0';
            s_mem_address <= (others => '0');
            s_byte_enable <= (others => '0');
            s_data_in <= (others => '0');
            mem_data_out <= (others => '0');
            rs1_addr_out <= (others => '0');
            rs1_value_out <= (others => '0');
            rs2_addr_out <= (others => '0');
            rs2_value_out <= (others => '0');
            rd_addr_out <= (others => '0');
            rd_value_out <= (others => '0');
            usage_writeback_out <= '0';
        elsif rising_edge(clock) then
            if usage_mem_in = '1' then
                s_write_enable <= '0';
                s_byte_enable <= "0000";
                s_mem_address <= mem_addr_in(19 downto 0);
                if MEM_OP_in = OP_STORE then
                    s_data_in <= rs2_value_in;

                    case(MEM_OP_SIZE_in) is
                        when OP_SIZE_BYTE =>
                            s_byte_enable <= "0001";
                        when OP_SIZE_HALFWORD =>
                            s_byte_enable <= "0011";
                        when OP_SIZE_WORD =>
                            s_byte_enable <= "1111";
                        when others =>
                            s_byte_enable <= "0000";
                    end case;
                    s_write_enable <= '1';
                elsif MEM_OP_in = OP_LOAD then
                    mem_data_out <= s_masked_data_out;
                end if;
            else
                mem_data_out <= (others => '0');
            end if;
            mem_addr_out <= mem_addr_in;
            rs1_addr_out <= rs1_addr_in;
            rs1_value_out <= rs1_value_in;
            rs2_addr_out <= rs2_addr_in;
            rs2_value_out <= rs2_value_in;
            rd_addr_out <= rd_addr_in;
            rd_value_out <= rd_value_in;
            usage_writeback_out <= usage_writeback_in;
        end if;
    end process;
    pipe_async_mem_data_out <= s_masked_pipe_async_data_out;
end behaviour;