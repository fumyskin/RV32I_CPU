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
    signal bram : bram_t := (                                       -- define some random words to be able to test the entities
        0 => x"00100093",
        1 => x"00200113",
        2 => x"003101b3",
        3 => x"00010193",
        4 => x"00000217",
        5 => x"0000006f",
        others => (others => '0')                                   -- keep the other cells to 0
    );
begin
    process(clock)
    begin
        if rising_edge(clock) then
            if read_enable = '1' then
                data_out <= bram(to_integer(unsigned(address)));
            else
                data_out <= (others => '0');                        -- need this to avoid howls (UUUU -> undefined signals, lol)
            end if;
        end if;
    end process;
end architecture;