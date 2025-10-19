library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--
-- MEMORY BUFFER for FMAs blocks
-- core idea: fetch from cache abc strings, define a, b, c valid
-- and give them back to each FMA block available ( the more the merrier ? We'll discover it soon )
-- the FMA blocks will read the results and process them ??
-- PREPARE abc modules for FMA to read, for each FMA module given

entity FMAMemBuffer is
    generic(
        LENGTH: integer := 16; -- length of bit string 
        FMA_NUM: integer := 3 -- number of fma modules used
    );
    port(
        clk: in std_logic;
        rst: in std_logic;

        abc_input: in std_logic_vector(FMA_NUM*(3*LENGTH)-1 downto 0);      -- array of tuples given in sequential fashion
        abc_valid_in: in std_logic_vector(FMA_NUM*3-1 downto 0);            -- assigning a bit for each number stored to verify its validity

        abc_output: out std_logic_vector(FMA_NUM*(3*LENGTH)-1 downto 0);    -- result that is going to be read and stored in fma moddule(s)
        abc_valid_out: out std_logic;                                            -- signal flag to notify fma module stores valid data
        c_valid_out: out std_logic_vector(FMA_NUM-1 downto 0)               -- collection of c values (that might be used for recycling)
        
    );
end FMAMemBuffer;


architecture Behavioral of FMAMemBuffer is
    -- define record for array of fma
    -- this record can be used both for data coming in and data coming out

    -- module for abc_input
    type FMA_Module is record
            a: signed(LENGTH-1 downto 0);
            b: signed(LENGTH-1 downto 0);
            c: signed(LENGTH-1 downto 0);
    end record;

    -- module for collecting valid bit
    type FMA_Valid is record
        a_valid: std_logic;
        b_valid: std_logic;
        c_valid: std_logic;
    end record;

    type FMA_Array_Input is array (natural range <>) of FMA_Module; -- i want a FMA_NUM range
    type FMA_Valid_Input is array (natural range <>) of FMA_Valid;
    type FMA_Array_Output is array (natural range <>) of FMA_Module; -- ?

    -- prepare [(a1, b1, c1) (a2, b2, c2) (a3, b3, c3)]input -> [(a1_valid, b1_valid, c1_valid) , ... ]output

    signal abc: std_logic_vector(FMA_NUM*(3*LENGTH)-1 downto 0); 
    signal c_valid: std_logic_vector(FMA_NUM-1 downto 0); -- array of FMA_NUM width for traking the validity of every c
    signal fma_ready: std_logic_vector(FMA_NUM-1 downto 0); -- is this useful ?   


    type state is(
        FILL,
        WRITE
    );

    -- -- TO DECIDE WHETHER TO PUT IT OR NOT
    -- -- helper function: unpack abc_input into array of records for each FMA module
    -- -- (abc)_{0} -> (0010101000101001101010101010...000) -> a_{0}, b_{0}, c_{0} 
    -- -- (abc)_{1} -> (010100010101001001 ... 111) -> a_1{0}, b_1{0}, c_1{0}
    -- function unpack_module (vec: std_logic_vector) return FMA_Array_Input(0 to FMA_NUM-1) is
    --     variable res : FMA_Array_Input(0 to FMA_NUM-1);
    -- begin
    --     for i in 0 to FMA_NUM-1 loop
    --         res(i).a := signed(vec((i*3+0+1)*LENGTH-1 downto (i*3+0)*LENGTH));
    --         res(i).b := signed(vec((i*3+1+1)*LENGTH-1 downto (i*3+1)*LENGTH));
    --         res(i).c := signed(vec((i*3+2+1)*LENGTH-1 downto (i*3+2)*LENGTH));
    --     end loop;
    --     return res;
    -- end;

    -- -- helper function: pack back into a std_logic_vector 
    -- -- assign for each index a tuple with 3 bits each -> for each fma_valid_input record, save the current state for a_valid, b_valid, c_valid
    -- function pack_module (arr: FMA_Array_Input) return std_logic_vector is
    --     variable res: std_logic_vector(FMA_NUM*3*LENGTH-1 downto 0);
    -- begin
    --     for i in 0 to FMA_NUM-1 loop
    --         res((i*3+0+1)*LENGTH-1 downto (i*3+0)*LENGTH) := std_logic_vector(arr(i).a);
    --         res((i*3+1+1)*LENGTH-1 downto (i*3+1)*LENGTH) := std_logic_vector(arr(i).b);
    --         res((i*3+2+1)*LENGTH-1 downto (i*3+2)*LENGTH) := std_logic_vector(arr(i).c);
    --     end loop;
    --     return valid_array;
    -- end;
  
    -- signal input_array : FMA_Array(0 to FMA_NUM-1);
    -- signal valid_array : FMA_Valid_Array(0 to FMA_NUM-1);

    signal abc_reg      : FMA_Array(0 to FMA_NUM-1);
    signal c_valid_reg  : std_logic_vector(FMA_NUM-1 downto 0);
    signal fma_ready    : std_logic_vector(FMA_NUM-1 downto 0);

    signal current_state: state := IDLE;

    STATE MACHINE: process(clk) 
    begin
        if (rst = '1') then
            current_state <= FILLING; -- go in filling state
            abc_valid_out <= '0';
            -- everything is zeroed
            c_valid_reg <= (others => '0');
            c_valid_out <= (others => '0');
            fma_ready <= '0';

            abc_input <= (others => '0');
            abc_valid_in <= (others => '0');
            abc_reg <= (others => '0');
            abc_output <= (others => '0');  
        
        else 
            case (current_state) is
                -- when IDLE =>
                --     -- if we receive correct trigger from memory we shall start loading to FMA block
                --     input_array <= unpack_module(abc_input); -- assign to record abc data coming in

                --     -- assign for each the value of the first bit each abc string to verify 
                --     for i in 0 to FMA_NUM-1 loop
                --         valid_array(i).a_valid <= abc_valid_in(i*3 + 0);
                --         valid_array(i).b_valid <= abc_valid_in(i*3 + 1);
                --         valid_array(i).c_valid <= abc_valid_in(i*3 + 2);
                --     end loop;

                --     current_state <= FILL;

                when FILL =>
                    -- first verify that 
                    for i in 0 to FMA_NUM-1 loop
                        -- verify if cs are valid
                        if (abc_valid_in(i*3 + 2) == '1') then
                            c_valid_reg(i) <= '1';
                        end if;

                        if (abc_valid_in(i*3) == '1' AND abc_valid_in(i*3 + 1) == '1') then
                            fma_ready <= '1' 
                        end if;
                        
                        -- if abc_valid 
                        for j in 0 to LENGTH-1 loop
                            for k in 0 to 2 loop
                                if (abc_valid_in(i*3 + k) == '1') then
                                    abc(i*3*LENGTH + k*LENGTH + j) <= abc_input(k*3*LENGTH + k*LENGTH + j); -- check indexes!
                                end if;
                            end loop;
                        end loop;
                    end loop;
                
                    if (fma_ready == '1') then
                        current_state <= WRITE;
                        abc_valid_out <= '1';

                        for i in 0 to FMA_NUM-1 loop
                            c_valid_out(i) <= c_valid_reg(i);
                            for j in 0 to 3*LENGTH-1 loop
                                abc_output(i*3*LENGTH + j) <= abc(i*3*LENGTH + j);
                            end loop;
                        end loop;
                    end if;

                when WRITE =>
                    current_state <= FILL;
                    abc_valid_out <= '0';
                    for i in 0 to FMA_NUM-1 loop
                        c_valid_reg(i) <= '0';
                        fma_ready(i) <= '0';
                        for j in 0 to 3*LENGTH-1 loop
                            abc(i*3*LENGTH + j) <= '0';
                        end loop;
                    end loop;
                
                when others => 
                    current_state <= FILL;

            end case;
        end if;

end Behavioral







