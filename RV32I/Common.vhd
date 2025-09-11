library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package common is
    type INST_CLASS_T is(
        INST_CLASS_R, INST_CLASS_I, INST_CLASS_S, INST_CLASS_B, INST_CLASS_U, INST_CLASS_J, INST_CLASS_NOP, INST_CLASS_ERR
    );
    type ALU_OP_T is(
        OP_ADD,
        OP_SUB,
        OP_AND,
        OP_OR,
        OP_XOR,
        OP_SLL,
        OP_SRL,
        OP_SRA,
        OP_SLT,
        OP_SLTU,
        OP_LUI,
        OP_AUIPC,
        OP_JAL,
        OP_JALR,
        OP_NOP,
        OP_ERR
    );
    type MEM_OP_T is(
        OP_LOAD,
        OP_STORE
    );
    type MEM_OP_SIZE_T is(
        OP_SIZE_BYTE,
        OP_SIZE_HALFWORD,
        OP_SIZE_WORD
    );
    type BRANCH_OP_COND_T is(
        OP_BRANCH_EQ,
        OP_BRANCH_NE,
        OP_BRANCH_LT,
        OP_BRANCH_GE,
        OP_BRANCH_ERR
    );
    type OP_SIGN_T is(
        OP_SIGNED,
        OP_UNSIGNED
    );
end package common;

package body common is
end package body common;