-- Data Source (dataSource.vhd)
-- Asynchronous reset, active high
------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.ALL;

ENTITY dataSource IS
  PORT (
    clk: IN STD_ULOGIC;
    reset: in STD_ULOGIC;
    outValid: in STD_ULOGIC;
    A_out: out STD_ULOGIC_VECTOR(7 downto 0);
    B_out: out STD_ULOGIC_VECTOR(7 downto 0);
    C_out: out STD_ULOGICc_VECTOR7 downto 0);
    D_out: out STD_ULOGIC_VECTOR(7 downto 0);
    E_out: out STD_ULOGIC_VECTOR(7 downto 0)
  );
END;

ARCHITECTURE behavioural OF dataSource IS
  -- signed and unsigned are used to represent numeric types
  -- signed uses 2's complement representation
  -- usage of signed and unsigned is similar to std_ulogic
  -- as they are also vectors
  -- See http://www.gstitt.ece.ufl.edu/vhdl/refs/vhdl_math_tricks_mapld_2003.pdf
  SIGNAL A_int, B_int, C_int, D_int, E_int : SIGNED(7 downto 0);
  SIGNAL enCount : BOOLEAN;
BEGIN
  PROCESS(reset,clk)
  BEGIN
    IF reset = '1' THEN
      A_int <= TO_SIGNED(0,8); -- 0 is the decimal value, 8 is the number of bits
      B_int <= TO_SIGNED(0,8); -- could also say B_int <= "00000000";
      C_int <= TO_SIGNED(0,8);
      D_int <= TO_SIGNED(0,8);
      E_int <= TO_SIGNED(0,8);
    ELSIF clk'event AND clk='1' THEN
      IF enCount = true THEN
        A_int <= A_int - 1;
        B_int <= B_int + 2;
        C_int <= C_int - 3;
        D_int <= D_int + 4;
        E_int <= E_int + 5;
      END IF;
    END IF;
  END PROCESS;
  
  enCount <= true WHEN outValid = '1' ELSE false; -- concurrent MUX
  
  A_out <= STD_ULOGIC_VECTOR(A_int); -- type casting
  B_out <= STD_ULOGIC_VECTOR(B_int);  
  C_out <= STD_ULOGIC_VECTOR(C_int);
  D_out <= STD_ULOGIC_VECTOR(D_int);
  E_out <= STD_ULOGIC_VECTOR(E_int);
  
END; -- behavioural