# Branches

Branches introduce potential control hazards in the pipeline, as they can alter the normal sequential flow of instructions.  
Depending on the branch outcome and the prediction strategy used, they can cause a delay — typically between 0 and 1 pipeline void stage (that is, one cycle of penalty in the worst case).

---

### Static Predictor: **Branch Taken Forward Not Taken (BTFNT)**

The **Branch Taken Forward Not Taken (BTFNT)** strategy is a simple **static branch prediction** technique that relies on the sign bit of the branch immediate field to make its decision.

- If the **immediate value is negative** (`imm[12] = '1'`), the predictor assumes the branch **will be taken** (representing a **backward branch**, such as those used in loops).
- If the **immediate value is positive** (`imm[12] = '0'`), the predictor assumes the branch **will not be taken** (representing a **forward branch**, such as conditional jumps to exit loops or skip code blocks).

This prediction determines the **next program counter (PC)** to use during instruction fetch:
- For predicted-taken branches, the PC is updated to `PC + offset`.
- For predicted-not-taken branches, the PC simply increments by 4 (fetching the next sequential instruction).

This method is **hardware-efficient**, requiring only a simple check on the sign bit of the immediate field, and no dynamic prediction history or pattern tracking.  
It works particularly well in loop-heavy code, where backward branches are frequently taken, but it struggles in more complex or irregular control flows, such as Finite State Machines with multiple transitions or deeply nested conditional structures

---
## Structure Overview

The required structure for this to work involves only **Instruction Fetcher** and **Instruction Decoder**:

**Instruction Fetcher**
```
    |-> fetch the operation at MEM[PC]  (curr_op = MEM[PC])
    |-> if opcode matches branch ("1100011")
        -> if branch offset is negative (curr_op(31) = '1')
            -> decode the immediate value as
                v_immediate_13bits := curr_instruction(31) &        -- imm[12]
                                        curr_instruction(7) &       -- imm[11]
                                        curr_instruction(30 downto 25) & -- imm[10:5]
                                        curr_instruction(11 downto 8) &  -- imm[4:1]
                                        '0';                        -- imm[0]

            -> set the offset signal to the immediate value
            -> pass branch instruction to InstructionDecoder
               with signal `branchPrediction = 1` (branch taken)
        -> else
            -> pass branch instruction with `branchPrediction = 0` (not taken)
    |-> else
        -> PC = PC + 4
        -> pass instruction to InstructionDecoder
```

**Instruction Decoder**
```
    |-> take operation from InstructionFetcher
    |-> fetch needed registers
    |-> if branch opcode ("1100011")
        -> compute branch condition
        -> compare with branchPrediction
        -> set branchMisprediction = branchResult xor branchPrediction
    |-> else
        -> standard decode
```


## Expected Instructions Flow through the pipeline

### Case 1: Backward Branch Not Taken / Forward Branch Taken  
*(Wrong prediction → 2 stage/bubble loss)*

```
1 cycle -> IF fetches branch Bbb, recognizes it, checks offset sign
            -> ID decodes OpX (preceding Bbb)
            -> EXEC executes OpX-1
2 cycle -> IF fetches [(Bbb address)+offset] = OpY
            -> ID checks condition, detects misprediction (branchMisprediction = 1)
            -> EXEC executes OpX
3 cycle -> IF fetches [(Bbb address)+4] = OpC
            -> ID ignores OpY (due to misprediction)
            -> EXEC receives NOP
4 cycle -> IF fetches [(Bbb address)+8] = OpC+1
            -> ID decodes OpC
            -> EXEC receives NOP
5 cycle -> IF fetches [(Bbb address)+8] = OpC+2
            -> ID decodes OpC+1
            -> EXEC executes OpC
```

### Case 2: Backward Branch Taken / Forward Branch Not Taken  
*(Correct prediction → almost 0 stage/bubble loss)*

```
1 cycle -> IF fetches branch Bbb, recognizes it, checks offset sign
            -> ID decodes OpX (preceding Bbb)
            -> EXEC executes OpX-1
2 cycle -> IF fetches [([(Bbb address)+offset | (Bbb address)+4])] = OpY
            -> ID decodes Bbb and checks condition
            -> EXEC executes OpX
3 cycle -> IF fetches [([(Bbb address)+offset+4 | (Bbb address)+8])] = OpY+1
            -> ID decodes OpY
            -> EXEC receives Bbb (no effect)
4 cycle -> IF fetches [([(Bbb address)+offset+8 | (Bbb address)+12])] = OpY+2
            -> ID decodes OpY+1
            -> EXEC executes OpY
```

### Pipeline Progression Table: Branch Prediction
> Table to show how pipeline stages are delayed according to branch predictions
>
> **Wrong prediction** → 2-cycle penalty (IF wait and ID discarded cycle)  
> **Correct prediction** → 0-cycle penalty

| Cycle | Wrong Prediction (BTFNT fails)       | Correct Prediction (BTFNT succeeds)       |
|-------|------------------------------------|------------------------------------------|
| 1     | IF: fetch Bbb, check offset sign<br>ID: decode OpX<br>EXEC: OpX-1 | IF: fetch Bbb, check offset sign<br>ID: decode OpX<br>EXEC: OpX-1 |
| 2     | IF: fetch OpY at [(Bbb (+4 or +offset))]<br>ID: check condition, branchMisprediction=1<br>EXEC: OpX | IF: fetch OpY at [(Bbb (+4 or +offset))]<br>ID: decode & check Bbb<br>EXEC: OpX |
| 3     | IF: fetch OpC [(Bbb (+4 or +offset) +4)]<br>ID: ignore OpY (bubble)<br>EXEC: NOP (bubble) | IF: fetch OpY+1 [(Bbb (+4 or +offset) +4)]<br>ID: decode OpY<br>EXEC: Bbb (no effect) |
| 4     | IF: fetch OpC+1 [(Bbb (+4 or +offset) +4 +4)]<br>ID: decode OpC<br>EXEC: NOP (bubble) | IF: fetch OpY+2 [(Bbb (+4 or +offset) +4 +4)]<br>ID: decode OpY+1<br>EXEC: OpY |
| 5     | IF: fetch OpC+2 [(Bbb (+4 or +offset) +4 +4 +4)]<br>ID: decode OpC+1<br>EXEC: OpC | - |



# Jumps

The required logic in **Instruction Fetcher** and **Instruction Decoder** for JAL and JALR is instead:

---

**Instruction Fetcher**
```
    |-> fetch the operation at MEM[PC]  (curr_op = MEM[PC])
    |-> if opcode matches J-type ("1101111")
        -> decode the immediate value as
                v_immediate_21bits := curr_instruction(31) &          -- imm[20]
                                       curr_instruction(19 downto 12) & -- imm[19:12]
                                       curr_instruction(20) &          -- imm[11]
                                       curr_instruction(30 downto 21) & -- imm[10:1]
                                       '0';                            -- imm[0]
        -> set the offset signal to this value
        -> pass the **JAL** instruction to InstructionDecoder
           with a `jumpPending = 1` signal (indicating that a jump target is being prepared)
        -> during the next cycle, use `PC + offset` as the target address for the next fetch
    |-> else
        -> standard decode for non-jump operations
```

---

**Instruction Decoder**
```
    |-> take the operation from InstructionFetcher
    |-> if opcode matches J-type ("1101111")
        -> decode destination register (rd)
        -> compute the return address (PC + 4)
        -> prepare writeback signals for the specified rd and set rd_value to the return address
    |-> else
        -> standard decode for non-jump operations
```

---

This mechanism ensures that **JAL (Jump and Link)** and **JALR (Jump and Link Register)** instructions are efficiently handled with minimal control hazards.  
The **Instruction Fetcher** determines the jump target based on the immediate field, while the **Instruction Decoder** finalizes the jump by writing the return address and validating the new PC.  
Since the prediction is implicit (the jump is always taken), the design incurs a **1-cycle bubble** penalty as the pipeline realigns to the new instruction stream.


## Expected Instructions Flow through the pipeline

### JAL Case (1 Stage/Bubble Loss)

```
1 cycle -> IF fetches JAL, recognizes it, sets offset signal
            -> ID decodes OpX (preceding JAL)
            -> EXEC executes OpX-1
2 cycle -> IF fetches at [PC+offset]
            -> ID receives NOP
            -> EXEC executes OpX
3 cycle -> IF fetches at [(PC+offset)+4]
            -> ID decodes operation at [PC+offset]
            -> EXEC receives NOP
```


### JALR Case (2 Stage/Bubble Loss)

```
1 cycle -> IF fetches JALR, recognizes it and set the jumpPending signal to 1 to delay the next fetch
            -> ID decodes OpX (preceding JALR)
            -> EXEC executes OpX-1
2 cycle -> IF waits setting jumpPending to 0 and preparing a NOP for the next stages
            -> ID decodes & executes JALR
               (new_jump_pc = signed(rs1) + resize(signed(imm), 32))
            -> EXEC executes OpX
3 cycle -> IF fetches at [new_jump_pc] the operation OpY
            -> ID receives bubble
            -> EXEC receives JALR and does nothing
4 cycle -> IF fetches at [new_jump_pc+4] the operation OpY+4
            -> ID receives and decodes OpY
            -> EXEC receives a bubble
5 cycle -> IF fetches at [new_jump_pc+8] the operation OpY+8
            -> ID receives and decodes OpY+4
            -> EXEC executes OpY
```

### Pipeline Progression Table: JAL vs JALR

> Table to show how pipeline stages are delayed according to the jump type
>
> **JAL** → 1-cycle bubble (ID stage)  
> **JALR** → 2-cycle bubble (due to jump address dependency)

| Cycle | JAL               | JALR                        |
|-------|------------------|-----------------------------|
| 1     | IF: fetch JAL, set offset<br>ID: decode OpX<br>EXEC: OpX-1 | IF: fetch JALR, jumpPending=1<br>ID: decode OpX<br>EXEC: OpX-1 |
| 2     | IF: fetch OpY [PC+offset]<br>ID: bubble<br>EXEC: OpX | IF: wait (NOP)<br>ID: decode & execute JALR<br>EXEC: OpX |
| 3     | IF: fetch OpY+1 [PC+offset+4]<br>ID: decode OpY<br>EXEC: bubble | IF: fetch OpY [new_jump_pc]<br>ID: bubble<br>EXEC: does nothing |
| 4     | IF: fetch OpY+2 [PC+offset+8]<br>ID: decode OpY+1<br>EXEC: OpY | IF: fetch OpY+1 [new_jump_pc+4]<br>ID: decode OpY<br>EXEC: bubble |
| 5     | -                | IF: fetch OpY+2 [new_jump_pc+8]<br>ID: decode OpY+1<br>EXEC: OpY |