library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- This entity includes Flags Detection Block and input/output selection
entity ALU is
Port (
    clk: in std_logic;
    rst: in std_logic;
    
    rs1: in std_logic_vector(31 downto 0);
    rs2: in std_logic_vector(31 downto 0);
    controls: in std_logic_vector(7 downto 0);
        -- Shifter -> {[0, 4] = shamt} + {[5] = shift type} + {[6] = shift direction} + {[7] = shift amount source}
        -- LogicUnit -> [0, 3] = operation type
        -- Adder -> [0,1] = conditioning type + [2] carry bit in 
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

begin


end Behavioral;
