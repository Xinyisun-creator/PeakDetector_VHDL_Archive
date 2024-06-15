LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY ff IS
  PORT (
    d:IN STD_ULOGIC;
    clk:IN STD_ULOGIC;
    reset:in STD_ULOGIC;
    q:OUT STD_ULOGIC;
    qPrim:OUT STD_ULOGIC
  );
END ff;

------------------------------------------------------
-- behavioural Implementation ------------------------
------------------------------------------------------
ARCHITECTURE behav of ff IS
BEGIN
  	PROCESS(reset, clk)
  	BEGIN
  	  IF reset = '0' THEN -- active low reset
	     q <= '0';
       qPrim <= '1';
   		ELSIF clk'EVENT AND clk='1' THEN
			 q <= d;
			 qPrim <= not d;
  		 END IF;
   END PROCESS;
END behav;
------------------------------------------------------