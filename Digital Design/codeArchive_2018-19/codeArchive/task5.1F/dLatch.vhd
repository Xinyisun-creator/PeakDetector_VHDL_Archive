LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY dLatch IS
  PORT (
    d:IN STD_ULOGIC;
    clk:IN STD_ULOGIC;
    reset:IN STD_ULOGIC;
    q:OUT STD_ULOGIC;
    qPrim:OUT STD_ULOGIC
  );
END dLatch;

------------------------------------------------------
-- behavioural Implementation   ----------------------
------------------------------------------------------
ARCHITECTURE behav of dLatch IS
BEGIN
    PROCESS(clk, d, reset)
    BEGIN
     IF reset = '0' THEN -- active low reset
       q <= '0';
       qPrim <= '1'; 
     ELSIF clk = '1' THEN
       q <= d;
       qPrim <= not d;
     END IF;
   END PROCESS;
END behav;
------------------------------------------------------