library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Shifter is
Port (
    clk: in std_logic;
    rst: in std_logic; 
    
    rs1: in std_logic_vector(31 downto 0);
    rs2: in std_logic_vector(31 downto 0);
    shamt : in std_logic_vector(4 downto 0);
    sh_type : in std_logic;                 -- (controls[5]) 0: Logical, 1: Arithmetic
    sh_dir : in std_logic;                  -- (controls[6]) 0: Right, 1: Left
    sh_src : in std_logic;                  -- (controls[7]) 0: shamt, 1: rs2 (5 lsb bits)
    rout: out std_logic_vector(31 downto 0);
);
end Shifter;

architecture Behavioral of Shifter is
begin
    process(clk, rst) 
        variable op_res: std_logic_vector(31 downto 0) := (others => '0');
        variable v_shamt: std_logic_vector(4 downto 0) := (others => '0');
        variable v_shamt_i: natural range 0 to 31;
        variable v_rs1: unsigned(31 downto 0) := (others => '0');
        variable v_rs1_s: signed(31 downto 0) := (others => '0');
    begin
        if rst = '1' then 
            rout <= (others => '0');
        elsif rising_edge(clk) then
            if sh_src = '1' then
                v_shamt := rs2(4 downto 0);
            elsif sh_src = '0' then
                v_shamt := shamt;
            else
                v_shamt := '0';
            end if;
            
            v_shamt_i := to_integer(unsigned(v_shamt));
            v_rs1 := unsigned(rs1);
            v_rs1_s := signed(rs1);
            
            case sh_dir & sh_type
                when "00" => 
                    op_res := shift_right(v_rs1, v_shamt_i);
                when "01" => 
                    op_res := shift_right(v_rs1_s, v_shamt_i);
                when "10" => 
                    op_res := shift_left(v_rs1, v_shamt_i);
                when "11" => 
                    op_res := shift_left(v_rs1_s, v_shamt_i);
                when others =>
                    op_res <= rs1;
            end case;
            rout <= op_res;
        end if;
    end process;
end Behavioral;