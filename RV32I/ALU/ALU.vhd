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
        -- [0] = Z (from FlagsChecker),
        -- [1] = C (from Adder), 
        -- [2] = N (from FlagsChecker),
        -- [3] = V (from Adder)
    rout: out std_logic_vector(31 downto 0)
);
end ALU;

architecture Behavioral of ALU is
    component Adder is
        Port (
            clk: in std_logic;
            rst: in std_logic;
            rs1: in std_logic_vector(31 downto 0);
            rs2: in std_logic_vector(31 downto 0);
            cond_type: in std_logic_vector(1 downto 0);
            carry_in: in std_logic;
            signed_sum: in std_logic;
            carry_out: out std_logic;
            valid: out std_logic;
            rout: out std_logic_vector(31 downto 0)
        );
    end component;

    component LogicUnit is
        Port (
          clk: in std_logic;
          rst: in std_logic;
          rs1: in std_logic_vector(31 downto 0);
          rs2: in std_logic_vector(31 downto 0);
          op_type: in std_logic_vector(2 downto 0);
          rout: out std_logic_vector(31 downto 0)
        );
    end component;

    component Shifter is 
        Port (
            clk: in std_logic;
            rst: in std_logic; 
            rs1: in std_logic_vector(31 downto 0);
            rs2: in std_logic_vector(31 downto 0);
            shamt : in std_logic_vector(4 downto 0);
            sh_type : in std_logic;
            sh_dir : in std_logic;
            sh_src : in std_logic;
            rout: out std_logic_vector(31 downto 0)
        );
    end component;

    component FlagsChecker is
        Port (
            clk: in std_logic;
            rst: in std_logic; 
            r: in std_logic_vector(31 downto 0); -- Input: the result to check for Z/N
            flags: out std_logic_vector(1 downto 0) -- Output: Z (bit 0) and N (bit 1) flags from this component
        );
    end component;

    -- Signals to hold the results from individual functional units
    signal adder_rout_s      : std_logic_vector(31 downto 0);
    signal logic_unit_rout_s : std_logic_vector(31 downto 0);
    signal shifter_rout_s    : std_logic_vector(31 downto 0);
    
    -- Signals for the internal multiplexer outputs (these will be registered due to the process)
    signal mux_L_out : std_logic_vector(31 downto 0);
    signal mux_C_out : std_logic_vector(31 downto 0); 

    -- Internal signals to capture flags directly from components
    signal adder_out_f_c : std_logic;                               -- 'C' flag from Adder
    signal adder_out_f_o  : std_logic;                              -- 'V' flag from Adder (captured from its 'valid' output)
    signal flags_checker_out_f : std_logic_vector(1 downto 0);      -- Z and N flags from FlagsChecker

    -- Internal signal to assemble all flags before assigning to the ALU's output port
    signal flags_int : std_logic_vector(3 downto 0); 
    -- flags_int(0) -> zero
    -- flags_int(1) -> carry_out
    -- flags_int(2) -> negative
    -- flags_int(3) -> overflow

begin
    Inst_Adder : Adder
    Port map(
        clk         => clk,
        rst         => rst,
        rs1         => rs1,
        rs2         => rs2,
        cond_type   => controls(1 downto 0),
        carry_in    => controls(2),
        signed_sum  => controls(3),
        carry_out   => adder_out_f_c,    
        valid       => not adder_out_f_o,                           -- simple logic inversion (not valid <=> overflow)
        rout        => adder_rout_s
    );

    Inst_LogicUnit : LogicUnit
    Port map (
        clk     => clk,
        rst     => rst,
        rs1     => rs1,
        rs2     => rs2,
        op_type => controls(2 downto 0),
        rout    => logic_unit_rout_s
    );

    Inst_Shifter : Shifter
    Port map (
        clk     => clk,
        rst     => rst,
        rs1     => rs1,
        rs2     => rs2,
        shamt   => controls(4 downto 0),
        sh_type => controls(5),
        sh_dir  => controls(6),
        sh_src  => controls(7),
        rout    => shifter_rout_s
    );

    -- FlagsChecker has to 'parse' the output of the bottom multiplexer (mux_C_out)
    -- Its 'flags' output is mapped to the internal 'flags_checker_out_f' signal
    Inst_FlagsChecker : FlagsChecker
    Port map (
        clk     => clk,
        rst     => rst,
        r       => mux_C_out,                                       -- FlagsChecker operates on the registered ALU output
        flags   => flags_checker_out_f                              -- Capture Z and N flags from FlagsChecker
    );

    process(clk, rst)
    begin
        if rst = '1' then
            mux_L_out <= (others => '0');
            mux_C_out <= (others => '0');
            rout        <= (others => '0');
            flags_int   <= (others => '0');
        elsif rising_edge(clk) then

            -- MUX L: Selects between Adder and Logic Unit results, output is registered
            case out_sel_L is
                when '0'    => mux_L_out <= adder_rout_s;
                when '1'    => mux_L_out <= logic_unit_rout_s;
                when others => mux_L_out <= (others => '0');
            end case;

            -- MUX C: Selects between MUX L output and Shifter result, output is registered
            case out_sel_C is
                when '0'    => mux_C_out <= mux_L_out;
                when '1'    => mux_C_out <= shifter_rout_s;
                when others => mux_C_out <= (others => '0');
            end case;
            
            rout <= mux_C_out;                                      -- bottom multiplexer mapped as ALU output

            flags_int(0) <= flags_checker_out_f(0);                 -- Z flag from FlagsChecker
            flags_int(1) <= adder_out_f_c;                          -- C flag from Adder
            flags_int(2) <= flags_checker_out_f(1);                 -- N flag from FlagsChecker
            flags_int(3) <= adder_out_f_o;                          -- V flag from Adder

        end if;
    end process;
    
    flags <= flags_int;                                             -- can be done here as flags_int will change synchronously (as it is 'registered')

end Behavioral;