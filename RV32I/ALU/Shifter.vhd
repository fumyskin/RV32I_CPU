library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Shifter is
Port (
    rs1: in std_logic_vector(31 downto 0);
    rs2: in std_logic_vector(31 downto 0);
    shamt : in std_logic_vector(4 downto 0);
    sh_type : in std_logic;                 -- (controls[5]) 0: Logical, 1: Arithmetic
    sh_dir : in std_logic;                  -- (controls[6]) 0: Right, 1: Left
    sh_src : in std_logic;                  -- (controls[7]) 0: shamt, 1: rs2 (5 lsb bits)
    rout: out std_logic_vector(31 downto 0)
);
end Shifter;

architecture Behavioral of Shifter is
begin
    process(rs1, rs2, shamt, sh_type, sh_dir, sh_src) 
        variable op_res: std_logic_vector(31 downto 0) := (others => '0');
        variable v_shamt: std_logic_vector(4 downto 0) := (others => '0');
        variable v_shamt_i: natural range 0 to 31;
    begin
        if sh_src = '1' then
            v_shamt := rs2(4 downto 0);
        elsif sh_src = '0' then
            v_shamt := shamt;
        else
            v_shamt := (others => '0');
        end if;
        
        v_shamt_i := to_integer(unsigned(v_shamt));
        
        case to_stdlogicvector(sh_dir & sh_type) is
            when "00" =>
                op_res := std_logic_vector(unsigned(rs1) srl v_shamt_i);
            when "01" => 
                op_res := std_logic_vector(signed(rs1) sra v_shamt_i);
            when "10" => 
                op_res := std_logic_vector(unsigned(rs1) sll v_shamt_i);
            when "11" => 
                op_res := std_logic_vector(signed(rs1) sla v_shamt_i);
            when others =>
                op_res := rs1;
        end case;
        rout <= op_res;
    end process;
end Behavioral;