-- Data Sampler (dataSampler.vhd)
-- Asynchronous reset, active high
------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.ALL;

ENTITY dataSampler IS
  PORT (
    clk: in STD_ULOGIC;
    reset: in STD_ULOGIC;
    outValid: out STD_ULOGIC;
    A_in: in STD_ULOGIC_VECTOR(7 DOWNTO 0);
    B_in: in STD_ULOGIC_VECTOR(7 DOWNTO 0);
    C_in: in STD_ULOGIC_VECTOR(7 DOWNTO 0);
    D_in: in STD_ULOGIC_VECTOR(7 DOWNTO 0);
    E_in: in STD_ULOGIC_VECTOR(7 DOWNTO 0);
    F_out: out STD_ULOGIC_VECTOR(15 DOWNTO 0);
    G_out: out STD_ULOGIC_VECTOR(15 DOWNTO 0)
  );
END;

ARCHITECTURE oneAdd_oneMult OF dataSampler IS
  TYPE MUXSEL is (LEFT, RIGHT);
  TYPE STATE_TYPE is (STAGE0, STAGE1, STAGE2, STAGE3, STAGE4);
  SIGNAL curState, nextState : STATE_TYPE;      
  -- control signals
  SIGNAL M1_sel, M2_sel, M3_sel : MUXSEL;
  SIGNAL R1_en, R2_en, R3_en, R4_en, R5_en, R6_en : BOOLEAN;
  -- data signals
  SIGNAL reg1_in, reg2_in, reg3_in: SIGNED(7 DOWNTO 0);
  SIGNAL reg1, reg2, reg3, reg4, addOut: SIGNED(7 DOWNTO 0);
  SIGNAL reg5, reg6, multOut : SIGNED(15 DOWNTO 0);
BEGIN
  
  M1: PROCESS(M1_sel,A_in,C_in)
  BEGIN
    IF M1_sel = LEFT THEN
      reg1_in <= signed(A_in);
    ELSE -- RIGHT
      reg1_in <= signed(C_in);
    END IF;
  END PROCESS;
  
  M2: PROCESS(M2_sel,B_in,D_in)
  BEGIN
    IF M2_sel = LEFT THEN
      reg2_in <= signed(B_in);
    ELSE -- RIGHT
      reg2_in <= signed(D_in);
    END IF;
  END PROCESS;
  
  M3: PROCESS(M3_sel,E_in,addOut)
  BEGIN
    IF M3_sel = LEFT THEN
      reg3_in <= signed(E_in);
    ELSE -- RIGHT
      reg3_in <= signed(addOut);
    END IF;
  END PROCESS;  
  
  R1: PROCESS(reset,clk)
  BEGIN
    IF reset = '1' THEN
      reg1 <= TO_SIGNED(0,8);
    ELSIF clk'event AND clk='1' THEN
      IF R1_en = true THEN
        reg1 <= reg1_in;
      END IF;
    END IF;
  END PROCESS;      
        
  R2: PROCESS(reset,clk)
  BEGIN
    IF reset = '1' THEN
      reg2 <= TO_SIGNED(0,8);
    ELSIF clk'event AND clk='1' THEN
      IF R2_en = true THEN
        reg2 <= reg2_in;
      END IF;
    END IF;
  END PROCESS;      
  
  R3: PROCESS(reset,clk)
  BEGIN
    IF reset = '1' THEN
      reg3 <= TO_SIGNED(0,8);
    ELSIF clk'event AND clk='1' THEN
      IF R3_en = true THEN--
        reg3 <= reg3_in;
      END IF;
    END IF;
  END PROCESS;      
        
  R4: PROCESS(reset,clk)
  BEGIN
    IF reset = '1' THEN
      reg4 <= TO_SIGNED(0,8);
    ELSIF clk'event AND clk='1' THEN
      IF R4_en = true THEN
        reg4 <= addOut;
      END IF;
    END IF;
  END PROCESS;

  add: PROCESS(reg1, reg2)
  BEGIN
    addOut <= reg1 + reg2;
  END PROCESS;        

  mult: PROCESS(reg3, reg4)
  BEGIN
    multOut <= reg3 * reg4;
  END PROCESS;        
  
  R5: PROCESS(reset,clk)
  BEGIN
    IF reset = '1' THEN
      reg5 <= TO_SIGNED(0,16);
    ELSIF clk'event and clk='1' THEN
      IF R5_en = true THEN
        reg5 <= multOut;
      END IF;
    END IF;
  END PROCESS;
  
  R6: PROCESS(reset,clk)
  BEGIN
    IF reset = '1' THEN
      reg6 <= TO_SIGNED(0,16);
    ELSIF clk'event AND clk='1' THEN
      IF R6_en = true THEN
        reg6 <= multOut;
      END IF;
    END IF;
  END PROCESS;

  F_out <= STD_ULOGIC_VECTOR(reg5); -- type casting
  G_out <= STD_ULOGIC_VECTOR(reg6);  
  
  stateReg: PROCESS(reset,clk)
  BEGIN
    IF reset = '1'  THEN
      curState <= STAGE0;
    ELSIF clk'event AND clk = '1' THEN
      curState <= nextState;
    END IF;
  END PROCESS;
  
  nextStateLogic: PROCESS(curState)
  BEGIN
    CASE curState IS
      WHEN STAGE0 =>
        nextState <= 
      WHEN 
      ............
      ............
    -- Depending on the number of stages you have, and the minimum required 
    -- number of bits, unused states may result.
    -- If due to some noise or malfunction the FSM should end up in one of 
    -- these undefined states, it may languish in that state for ever, 
    -- until a system reset. Adding the following clause allows the circuit
    -- to enter into a defined state in the next cycle.
    WHEN OTHERS => 
      nextState <= STAGE0;
    END CASE;
  END PROCESS;
  
  ctrlOut: PROCESS(curState)
  BEGIN
    -- assign default values
    R1_sel <= 
    R2_sel <= 
    ..................
    R1_en <= false
    R2_en <= false
    ..................
    outValid <= '0';
    CASE curState IS
      
      WHEN STAGE0 =>
      ..................
    END CASE;
END PROCESS;
  
END; -- nextStateLogic
      
      