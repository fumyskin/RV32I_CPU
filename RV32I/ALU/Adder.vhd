library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- This entity includes Conditioning Block
entity Adder is
Port (
    clk: in std_logic;
    rst: in std_logic;
    
    rs1: in std_logic_vector(31 downto 0);
    rs2: in std_logic_vector(31 downto 0);
    cond_type: in std_logic_vector(1 downto 0);
    carry_in: in std_logic;
    signed_sum: in std_logic;
    
    carry_out: out std_logic := '0';
    valid: out std_logic := '0';
    rout: out std_logic_vector(31 downto 0);
);
end Adder;

architecture Behavioral of Adder is
    signal sum: unsigned(32 downto 0) := (others => '0');
    signal sum_s: signed(32 downto 0) := (others => '0');
    signal overflow_det: std_logic_vector(2 downto 0) := (others => '0');
begin
    process(clk, rst) 
        variable v_reg_in_1_s: signed(31 downto 0);
        variable v_reg_in_2_cond: unsigned(31 downto 0);
        variable v_reg_in_2_cond_s: signed(32 downto 0);
        variable v_sum: unsigned(32 downto 0);
        variable v_sum_s: signed(32 downto 0);
    begin
        if rst = '1' then
            rout <= (others => '0');
            valid <= '0';
            carry_out <= '0';
        elsif rising_edge(clk) then
            -- Combinatorial conditioning logic (no pipeline)
            case cond_type is
                when "00" => v_reg_in_2_cond := (others => '0');
                             v_reg_in_2_cond_s := (others => '0');
                when "01" => v_reg_in_2_cond := unsigned(rs2);
                             v_reg_in_2_cond_s := resize(signed(rs2), 33);
                when "10" => v_reg_in_2_cond := not unsigned(rs2);
                             v_reg_in_2_cond_s := resize(not signed(rs2), 33);
                when "11" => v_reg_in_2_cond := (others => '1');
                             v_reg_in_2_cond_s := (others => '1');
                when others => null;
            end case;

            
            -- Actual addition
            if signed_sum = '1' then
                v_reg_in_1_s := signed(rs1);
                v_sum_s := resize(v_reg_in_1_s, 33) + v_reg_in_2_cond_s;
                if carry_in = '1' then
                    v_sum_s := v_sum_s + to_signed(1, 33);
                end if;
                
                carry_out <= v_sum_s(32);
                rout <= std_logic_vector(v_sum_s(31 downto 0));
                
                -- Overflow detection
                overflow_det <= v_reg_in_1_s(31) & v_reg_in_2_cond_s(31) & v_sum_s(31);
                if overflow_det = "001" or overflow_det = "110" then
                    valid <= '0';
                else
                    valid <= '1';
                end if;
            else
                v_sum := resize(unsigned(rs1), 33) + resize(v_reg_in_2_cond, 33);
                if carry_in = '1' then
                    v_sum := v_sum + to_unsigned(1, 33);
                end if;
                
                carry_out <= v_sum(32);
                valid <= not v_sum(32);
                rout <= std_logic_vector(v_sum(31 downto 0));
            end if;
        end if;
    end process;
end Behavioral;