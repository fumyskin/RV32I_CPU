library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.common.ALL;

entity RegisterFile is
    port(
        clock: in std_logic;
        mem_enable: in std_logic;
        mem_operation: in MEM_OP_T;

        addr_A: in std_logic_vector(4 downto 0);
        addr_B: in std_logic_vector(4 downto 0);
        
        addr_C: in std_logic_vector(4 downto 0);                    -- write operations use a dedicated port
        write_C: in std_logic_vector(31 downto 0);

        val_A: out std_logic_vector(31 downto 0);
        val_B: out std_logic_vector(31 downto 0);
    );
end entity;

architecture behaviour of RegisterFile is
    type REG_MEMORY_T is array (0 to 31) of std_logic_vector(31 downto 0); -- 1024 bit memory definition (32x32)
    signal reg_memory: REG_MEMORY_T := (others => (others => '0')); -- start with all registers to 0
    
    begin
        process(clock)
        begin
            if rising_edge(clock) then
                if mem_enable = '1' and mem_operation = OP_STORE then
                    if addr_C /= "00000" then                       -- don't write on x0
                        reg_memory(addr_C) <= write_C;
                    end if;
                end if;
            end if;
        end process;

        val_A <= (others => '0') when addr_A = "00000" else reg_memory(to_integer(unsigned(addr_A)));
        val_B <= (others => '0') when addr_B = "00000" else reg_memory(to_integer(unsigned(addr_B)));
end architecture;