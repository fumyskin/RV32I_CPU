library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
Port (
    clk: in std_logic;
    rst: in std_logic;
    
    rs1: in std_logic_vector(31 downto 0);
    rs2: in std_logic_vector(31 downto 0);
    controls: in std_logic_vector(7 downto 0);
        -- Shifter -> {[0, 4] = shamt} + {[5] = shift type} + {[6] = shift direction} + {[7] = shift amount source}
        -- LogicUnit -> [0, 2] = operation type
        -- Adder -> [0,1] = conditioning type + [2] carry bit in
        -- Assuming controls(3) is 'signed_sum' for the Adder
    out_sel_L: in std_logic;
        -- 0 = Adder output, 1 = Logic Unit output
    out_sel_C: in std_logic;
        -- 0 = out_sel_L MUX output, 1 = Shifter output
    
    flags: out std_logic_vector(3 downto 0); 
        -- [0] = Z
        -- [1] = C (from Adder), 
        -- [2] = N
        -- [3] = V (from Adder)
    rout: out std_logic_vector(31 downto 0)
);
end ALU;

architecture Behavioral of ALU is
    component Adder is
        Port (
            rs1: in std_logic_vector(31 downto 0);
            rs2: in std_logic_vector(31 downto 0);
            cond_type: in std_logic_vector(1 downto 0);
            carry_in: in std_logic;
            signed_sum: in std_logic;
            carry_out: out std_logic;
            overflow: out std_logic;
            rout: out std_logic_vector(31 downto 0)
        );
    end component;

    component LogicUnit is
        Port (
          rs1: in std_logic_vector(31 downto 0);
          rs2: in std_logic_vector(31 downto 0);
          op_type: in std_logic_vector(2 downto 0);
          rout: out std_logic_vector(31 downto 0)
        );
    end component;

    component Shifter is 
        Port (
            rs1: in std_logic_vector(31 downto 0);
            rs2: in std_logic_vector(31 downto 0);
            shamt : in std_logic_vector(4 downto 0);
            sh_type : in std_logic;
            sh_dir : in std_logic;
            sh_src : in std_logic;
            rout: out std_logic_vector(31 downto 0)
        );
    end component;

    signal adder_rout_s      : std_logic_vector(31 downto 0);
    signal logic_unit_rout_s : std_logic_vector(31 downto 0);
    signal shifter_rout_s    : std_logic_vector(31 downto 0);
    
    signal mux_L_out : std_logic_vector(31 downto 0);
    signal mux_C_out : std_logic_vector(31 downto 0); 

    signal adder_out_f_c : std_logic;                               -- 'C' flag from Adder
    signal adder_out_f_o  : std_logic;                              -- 'V' flag from Adder (captured from its 'valid' output)

    signal flags_int : std_logic_vector(3 downto 0); 
    -- flags_int(0) -> zero
    -- flags_int(1) -> carry_out
    -- flags_int(2) -> negative
    -- flags_int(3) -> overflow

begin
    Inst_Adder : Adder
    Port map(
        rs1         => rs1,
        rs2         => rs2,
        cond_type   => controls(1 downto 0),
        carry_in    => controls(2),
        signed_sum  => controls(3),
        carry_out   => adder_out_f_c,    
        overflow    => adder_out_f_o,
        rout        => adder_rout_s
    );

    Inst_LogicUnit : LogicUnit
    Port map (
        rs1     => rs1,
        rs2     => rs2,
        op_type => controls(2 downto 0),
        rout    => logic_unit_rout_s
    );

    Inst_Shifter : Shifter
    Port map (
        rs1     => rs1,
        rs2     => rs2,
        shamt   => controls(4 downto 0),
        sh_type => controls(5),
        sh_dir  => controls(6),
        sh_src  => controls(7),
        rout    => shifter_rout_s
    );

    -- RIP FlagsChecker, it's been replaced inside the main ALU process

    process(clk, rst)
        variable v_mux_L_out : std_logic_vector(31 downto 0);
        variable v_mux_C_out : std_logic_vector(31 downto 0); 
    begin
        if rst = '1' then
            mux_L_out   <= (others => '0');
            mux_C_out   <= (others => '0');
            rout        <= (others => '0');
            flags_int   <= (flags_int'range => '0');
        elsif rising_edge(clk) then
            v_mux_L_out :=
                adder_rout_s when out_sel_L = '0' else
                logic_unit_rout_s when out_sel_L = '1' else (others => '0');
            v_mux_C_out :=
                v_mux_L_out when out_sel_C = '0' else
                shifter_rout_s when out_sel_C = '1' else (others => '0');
            mux_L_out <= v_mux_L_out;
            mux_C_out <= v_mux_C_out;
            rout <= v_mux_C_out;
        end if;
    end process;
    
    flags (0) <= '1' when mux_C_out = (mux_C_out'range => '0') else '0';                -- Z flag
    flags (1) <= adder_out_f_c;                                                         -- C flag from Adder
    flags (2) <= '1' when mux_C_out(31) = '1' else '0';                                 -- N flag
    flags (3) <= adder_out_f_o;                                                         -- V flag from Adder
    rout <= mux_C_out;                                      -- bottom multiplexer mapped as ALU output
end Behavioral;