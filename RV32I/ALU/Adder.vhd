library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity Adder is
Port (
    rs1        : in std_logic_vector(31 downto 0);
    rs2        : in std_logic_vector(31 downto 0);
    cond_type  : in std_logic_vector(1 downto 0);
    carry_in   : in std_logic;
    signed_sum : in std_logic;

    carry_out  : out std_logic;
    overflow   : out std_logic;
    rout       : out std_logic_vector(31 downto 0)
);
end Adder;

architecture Behavioral of Adder is
begin
    process(rs1, rs2, cond_type, carry_in, signed_sum)
        variable v_rout       : std_logic_vector(31 downto 0);
        variable v_carry_out  : std_logic;
        variable v_overflow   : std_logic;

        variable reg_in_2_cond    : unsigned(31 downto 0);
        variable reg_in_2_cond_s  : signed(32 downto 0);
        variable reg_in_1_s       : signed(31 downto 0);

        variable sum_u            : unsigned(32 downto 0);
        variable sum_s            : signed(32 downto 0);
        variable ovf_vec          : std_logic_vector(2 downto 0);
    begin
        -- Conditioning logic
        case cond_type is
            when "00" =>
                reg_in_2_cond := (others => '0');
                reg_in_2_cond_s := (others => '0');
            when "01" =>
                reg_in_2_cond := unsigned(rs2);
                reg_in_2_cond_s := resize(signed(rs2), 33);
            when "10" =>
                reg_in_2_cond := not unsigned(rs2);
                reg_in_2_cond_s := resize(not signed(rs2), 33);
            when "11" =>
                reg_in_2_cond := (others => '1');
                reg_in_2_cond_s := (others => '1');
            when others =>
                reg_in_2_cond := (others => '0');
                reg_in_2_cond_s := (others => '0');
        end case;

        -- Adder logic
        if signed_sum = '1' then
            reg_in_1_s := signed(rs1);
            sum_s := resize(reg_in_1_s, 33) + reg_in_2_cond_s;
            if carry_in = '1' then
                sum_s := sum_s + to_signed(1, 33);
            end if;
            v_rout := std_logic_vector(sum_s(31 downto 0));
            v_carry_out := sum_s(32);

            -- Signed overflow detection
            ovf_vec := reg_in_1_s(31) & reg_in_2_cond_s(31) & sum_s(31);
            v_overflow := '1' when (ovf_vec = "001") or (ovf_vec = "110") else '0';
        else
            sum_u := resize(unsigned(rs1), 33) + resize(reg_in_2_cond, 33);
            if carry_in = '1' then
                sum_u := sum_u + to_unsigned(1, 33);
            end if;
            v_rout := std_logic_vector(sum_u(31 downto 0));
            v_carry_out := sum_u(32);
            v_overflow := sum_u(32);
        end if;

        -- Drive outputs
        rout       <= v_rout;
        carry_out  <= v_carry_out;
        overflow   <= v_overflow;
    end process;
end Behavioral;
