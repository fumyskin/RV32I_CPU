library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DataMemory is
    port(
        clock: in std_logic;
        reset: in std_logic;
        write_enable: in std_logic;
        address: in std_logic_vector(19 downto 0);                  -- tot addressable memory: 1MB
        -- on zynq board 7S6 and 7S15 there are only 5 and 10 36Kb BRAM blocks
        -- the Zedboard zynq-7000 contains a XC7Z020-CLG484 chip, with a total of 4.9Mb (bram) memory -> will use 600KB
        byte_enable: in std_logic_vector(3 downto 0);
        data_in: in std_logic_vector(31 downto 0);
        data_out: out std_logic_vector(31 downto 0);
        pipe_async_data_out: out std_logic_vector(31 downto 0)
    );
end entity DataMemory;

architecture behaviour of DataMemory is
    type bram_t is array (0 to 614399) of std_logic_vector(7 downto 0); -- byte-addressable array of 614,400 locations (600KB)
    signal bram : bram_t := (others => (others => '0'));
    signal s_async_read_addr: std_logic_vector(19 downto 0);        -- will be used to skip stages-clock delay
    signal s_data_out: std_logic_vector(31 downto 0);

begin
    memoryAccess:process(clock, reset)
        variable v_word_addr: integer;
    begin
        if reset = '1' then
            bram <= (others => (others => '0'));
            s_data_out <= (others => '0');
        elsif rising_edge(clock) then
            v_word_addr:= to_integer(unsigned(address(19 downto 2)));
            if write_enable = '0' then
                s_data_out <= bram(v_word_addr) & bram(v_word_addr + 1) & bram(v_word_addr + 2) & bram(v_word_addr + 3); -- read always 4 byte words
            elsif write_enable = '1' then
                if byte_enable(0) = '1' then                        -- check each needed byte
                    bram(v_word_addr) <= data_in(7 downto 0);
                end if;
                if byte_enable(1) = '1' then
                    bram(v_word_addr + 1) <= data_in(15 downto 8);
                end if;
                if byte_enable(2) = '1' then
                    bram(v_word_addr + 2) <= data_in(23 downto 16);
                end if;
                if byte_enable(3) = '1' then
                    bram(v_word_addr + 3) <= data_in(31 downto 24);
                end if; 
            end if;                                                 -- no feedback signals defined yet (might add write confirmation)
        end if;
    end process;
    data_out <= s_data_out;

    s_async_read_addr <= std_logic_vector(to_unsigned(to_integer(unsigned(address(19 downto 2))) * 4, 20));
    pipe_async_data_out <= bram(s_async_read_addr) & bram(s_async_read_addr + 1) & bram(s_async_read_addr + 2) & bram(s_async_read_addr + 3);
end behaviour;