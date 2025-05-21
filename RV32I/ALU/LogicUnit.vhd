library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LogicUnit is
Port (
    clk: in std_logic;
    rst: in std_logic;
    
    rs1: in std_logic_vector(31 downto 0);
    rs2: in std_logic_vector(31 downto 0);
    op_type: in std_logic_vector(2 downto 0);
    
    rout: out std_logic_vector(31 downto 0)
);
end LogicUnit;

architecture Behavioral of LogicUnit is

begin
    -- Logic Unit Operations: Xor --> [000] Or --> [001] Not --> [010] And --> [011]
    -- Note: 'not' operation is computed on rs1 (the only one given in the instruction)
    process(clk, rst) 
        variable op_res: std_logic_vector(31 downto 0);
    begin
        if rst = '1' then 
            rout <= (others => '0');
        elsif rising_edge(clk) then
            case op_type is
                when "000" =>
                    op_res := (rs1 xor rs2);
                when "001" =>
                    op_res := (rs1 or rs2);
                when "010" =>
                    op_res := (not rs1);
                when "011" =>
                    op_res := (rs1 and rs2);
                when others =>
                    op_res <= (others => '0');
            end case;
            rout <= op_res;
        end if;
    end process;
end Behavioral;