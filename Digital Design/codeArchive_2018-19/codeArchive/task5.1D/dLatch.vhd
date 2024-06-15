LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY dLatch IS
  PORT (
    d:IN STD_ULOGIC;
    clk:IN STD_ULOGIC;
    q:OUT STD_ULOGIC;
    qPrim:OUT STD_ULOGIC
  );
END dLatch;

-----------------------------------------------------
-- Gate Level Implementation ------------------------
-----------------------------------------------------
ARCHITECTURE dataflow of dLatch IS
    COMPONENT srLatch_nor
        PORT (
            s:IN STD_ULOGIC;
            r:IN STD_ULOGIC;
            qPrim:OUT STD_ULOGIC;
            q:OUT STD_ULOGIC);
    END COMPONENT;
    FOR SR1: srLatch_nor USE ENTITY work.srLatch_nor(dataflow);
    SIGNAL d_inv, r_int, s_int:STD_ULOGIC;
BEGIN
  s_int <= D and clk;
  r_int <= d_inv and clk;
  d_inv <= not D;

  SR1: srLatch_nor PORT MAP(s_int, r_int, qPrim, q);
END dataflow; 
------------------------------------------------------


------------------------------------------------------
-- behavioural Implementation 1 ----------------------
------------------------------------------------------
ARCHITECTURE behav1 of dLatch IS
BEGIN
    PROCESS(clk, d)
    BEGIN
     IF clk = '1' THEN
       q <= d;
       qPrim <= not d;
     END IF;
   END PROCESS;
END behav1;
------------------------------------------------------


------------------------------------------------------
-- behavioural Implementation 2 ----------------------
------------------------------------------------------
ARCHITECTURE behav2 OF dLatch IS
BEGIN
	PROCESS(clk, d)
		VARIABLE var_q, var_qPrim : STD_ULOGIC;
	BEGIN	
		IF clk = '1' THEN
			var_q := d;
			var_qPrim := not var_q;
		END IF;
		q <= var_q;
		qPrim <= var_qPrim;
	END PROCESS;
END behav2;
------------------------------------------------------