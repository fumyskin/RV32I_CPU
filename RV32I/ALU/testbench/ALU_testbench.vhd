library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU_testbench is
end ALU_testbench;

architecture Behavioral of ALU_testbench is

    signal clk_tb: std_logic := '0';
    signal rst_tb: std_logic := '0';
    signal rs1_tb: std_logic_vector(31 downto 0) := (others => '0');
    signal rs2_tb: std_logic_vector(31 downto 0) := (others => '0');
    signal controls_tb: std_logic_vector(7 downto 0) := (others => '0');
    signal out_sel_L_tb: std_logic := '0';
    signal out_sel_C_tb: std_logic := '0';
    signal flags_tb: std_logic_vector(3 downto 0) := (others => '0');
    signal rout_tb: std_logic_vector(31 downto 0) := (others => '0');

    type test_vector is record
        rs1, rs2: std_logic_vector(31 downto 0);
        controls: std_logic_vector(7 downto 0);
        out_sel_L: std_logic;
        out_sel_C: std_logic;
        expected_rout: std_logic_vector(31 downto 0);
        expected_flags: std_logic_vector(3 downto 0);
    end record;
    type test_array is array (natural range <>) of test_vector;
    -- [controls to perform simple (unsigned) addition] (from lsb to msb):
        --  01  -> use directly rs2
        --  0   -> no carry in
        --  0   -> unsigned sum
        --  X   -> not used by the adder (will use 0)
        --  X   -> not used by the adder
        --  X   -> not used by the adder
        --  X   -> not used by the adder
        -- out_sel_L_tb = 0 -> select the adder result
        -- out_sel_C_tb = 0 -> select the L-mux result
    constant tests : test_array := (
        (
            rs1            => x"00000001",
            rs2            => x"00000001",
            controls       => "00000001",
            out_sel_L      => '0',
            out_sel_C      => '0',
            expected_rout  => x"00000002",
            expected_flags => "0000"
        ),
        (
            rs1            => x"FFFFFFFF",
            rs2            => x"00000001",
            controls       => "00000001",
            out_sel_L      => '0',
            out_sel_C      => '0',
            expected_rout  => x"00000000",
            expected_flags => "0010"  -- e.g., Carry or Zero flag set
        )
    );
    constant clk_period: time := 5ns;
begin
    uut: entity work.ALU
    port map(
        clk         => clk_tb,
        rst         => rst_tb,
        rs1         => rs1_tb,
        rs2         => rs2_tb,
        controls    => controls_tb,
        out_sel_L   => out_sel_L_tb,
        out_sel_C   => out_sel_C_tb,
        flags       => flags_tb,
        rout        => rout_tb
    );
    clk_process: process is
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
        rst_tb <= '1';
        wait for clk_period;
        rst_tb <= '0';
        wait for clk_period;
    
        for i in tests'range loop
            report "--- Test Case " & integer'image(test_num) & " ---";
    
            -- 🟢 Apply inputs BEFORE rising edge
            rs1_tb       <= tests(i).rs1;
            rs2_tb       <= tests(i).rs2;
            controls_tb  <= tests(i).controls;
            out_sel_L_tb <= tests(i).out_sel_L;
            out_sel_C_tb <= tests(i).out_sel_C;
    
            -- 🔁 Wait for output after ONE rising edge
            wait until rising_edge(clk_tb);
    
            -- ✅ Check outputs immediately
            assert rout_tb = tests(i).expected_rout
            report "FAIL: rout mismatch. Expected: " & to_hstring(tests(i).expected_rout) &
                   " Got: " & to_hstring(rout_tb)
            severity error;
    
            assert flags_tb = tests(i).expected_flags
            report "FAIL: flags mismatch. Expected: " & to_hstring(tests(i).expected_flags) &
                   " Got: " & to_hstring(flags_tb)
            severity error;
    
            test_num := test_num + 1;
        end loop;
    
        report "All test cases passed.";
        wait;
    end process;
    
end Behavioral;
