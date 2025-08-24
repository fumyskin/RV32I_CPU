library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionMemory is
    port(
        clock: in std_logic;
        read_enable: in std_logic;
        address: in std_logic_vector(10 downto 0);                  -- address space: [0, 2047] (8KB memory)
        data_out: out std_logic_vector(31 downto 0)
    );
end entity InstructionMemory;

architecture behaviour of InstructionMemory is
    type bram_t is array (0 to 2047) of std_logic_vector(31 downto 0);
    signal bram: bram_t;
begin
    process(clk)
    begin
        if rising_edge(clock) and read_enable = '1' then
            data_out <= bram(to_integer(unsigned(address)));
        end if;
    end process;
end architecture;