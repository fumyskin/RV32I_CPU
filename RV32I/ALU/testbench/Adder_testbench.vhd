library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Adder_testbench is
end entity Adder_testbench;

architecture Behavioral of Adder_testbench is
    signal clk_tb: std_logic := '0';
    signal rst_tb: std_logic := '0';

    signal rs1_tb: std_logic_vector(31 downto 0) := (others => '0');
    signal rs2_tb: std_logic_vector(31 downto 0) := (others => '0');
    signal cond_type_tb: std_logic_vector(1 downto 0) := "00";
    signal carry_in_tb: std_logic := '0';
    signal signed_sum_tb: std_logic := '0';

    signal carry_out_tb: std_logic;
    signal valid_tb: std_logic;
    signal rout_tb: std_logic_vector(31 downto 0);

    constant clk_period: time := 5 ns;
    
    -- Test result storage
    type test_vector is record
        rs1, rs2: std_logic_vector(31 downto 0);
        cond_type: std_logic_vector(1 downto 0);
        carry_in, signed_sum: std_logic;
        expected_result: std_logic_vector(31 downto 0);
        expected_carry, expected_valid: std_logic;
    end record;
    
    type test_array is array (natural range <>) of test_vector;
    
    -- Test cases
    constant tests : test_array := (
        -- Test case 1: Unsigned addition, no condition, no carry-in (Correct :))
        (x"0000000A", x"00000005", "01", '0', '0', x"0000000F", '0', '1'),
        
        -- Test case 2: Unsigned addition, NOT condition, no carry-in (Correct :))
        (x"0000000A", x"00000005", "10", '0', '0', x"00000004", '1', '1'),
        
        -- Test case 3: Signed addition, no condition, carry-in (Correct :))
        (x"00000005", x"0000000A", "01", '1', '1', x"00000010", '0', '1'),
        
        -- Test case 4: Signed addition, NOT condition, no carry-in (Correct :))
        (x"0000000A", x"00000005", "10", '0', '1', x"00000004", '0', '1'),
        
        -- Test case 5: Unsigned addition, all zeros condition (Correct :))
        (x"000000FF", x"12345678", "00", '0', '0', x"000000FF", '0', '1'),
        
        -- Test case 6: Signed addition, all ones condition, carry-in (that is: 1 -1 +1 -> 1, Correct :))
        (x"00000001", x"00000000", "11", '1', '1', x"00000001", '0', '1'),
        
        -- Test case 7: Unsigned addition with carry-in (FFFF + 2 -> 1 + carry_out,  Correct :))
        (x"FFFFFFFF", x"00000001", "01", '1', '0', x"00000001", '1', '1'),
        
        -- Test case 8: Signed overflow (positive + positive = negative) (Still don't know why this single case DOES NOT work :()
        (x"7FFFFFFF", x"00000001", "01", '0', '1', x"80000000", '0', '0'),
        
        -- Test case 9: Signed negative addition (-2,147,483,648 + (-1) -> +2,147,483,647 (due to an overflow), Correct :))
        (x"80000000", x"FFFFFFFF", "01", '0', '1', x"7FFFFFFF", '1', '0')
    );

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: entity work.Adder
    port map (
        clk => clk_tb,
        rst => rst_tb,
        rs1 => rs1_tb,
        rs2 => rs2_tb,
        cond_type => cond_type_tb,
        carry_in => carry_in_tb,
        signed_sum => signed_sum_tb,
        carry_out => carry_out_tb,
        valid => valid_tb,
        rout => rout_tb
    );

    clk_process: process
    begin
        while now < 1000 ns loop
            clk_tb <= not clk_tb after clk_period / 2;
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    stim_process: process
        variable test_num : integer := 1;
    begin
        -- Reset the UUT
        rst_tb <= '1';
        wait for clk_period;
        rst_tb <= '0';
        wait for clk_period;
        
        -- Run all test cases
        for i in tests'range loop
            report "--- Test Case " & integer'image(test_num) & " ---";
            wait until rising_edge(clk_tb);
          -- Apply inputs
            rs1_tb <= tests(i).rs1;
            rs2_tb <= tests(i).rs2;
            cond_type_tb <= tests(i).cond_type;
            carry_in_tb <= tests(i).carry_in;
            signed_sum_tb <= tests(i).signed_sum;
            
            -- Wait for a cycle (results appear)
            wait until rising_edge(clk_tb);
            
            -- Check results with proper type matching
--             assert rout_tb = tests(i).expected_result 
--                 report "Test Case " & integer'image(test_num) & " Failed: Result mismatch. "
--                 severity error;
--                 
--             assert carry_out_tb = tests(i).expected_carry
--                 report "Test Case " & integer'image(test_num) & " Failed: Carry mismatch."
--                 severity error;
--                 
--             assert valid_tb = tests(i).expected_valid
--                 report "Test Case " & integer'image(test_num) & " Failed: Valid mismatch."
--                 severity error;
            
            test_num := test_num + 1;
        end loop;
        
        report "--- All Tests Completed ---";
        wait;
    end process;

end architecture Behavioral;