library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FlagsChecker is
Port (
    clk: in std_logic;
    rst: in std_logic; 
    
    r: in std_logic_vector(31 downto 0);
    
    flags: out std_logic_vector(1 downto 0)
        -- [0] = Z (zero)
        -- [1] = N (negative, equivalent to S, sign)
);
end FlagsChecker;

architecture Behavioral of FlagsChecker is
begin
    process(clk, rst) 
        variable zero_flag:std_logic := '0';
        variable neg_flag:std_logic := '0';
    begin
        if rst = '1' then 
            flags <= (others => '0');
        elsif rising_edge(clk) then
            if r = (r'range => '0') then
                zero_flag := '1';
            else
                zero_flag := '0';
            end if;
        
            if r(31) = '1' then
                neg_flag := '1';
            else
                neg_flag := '0';
            end if;
            flags <= neg_flag & zero_flag;
        end if;
    end process;
end Behavioral;