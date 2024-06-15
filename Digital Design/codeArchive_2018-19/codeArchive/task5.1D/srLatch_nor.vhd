LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY SRLatch_nor IS
  PORT (
    s:IN STD_ULOGIC;
    r:IN STD_ULOGIC;
    qPrim:OUT STD_ULOGIC;
    q:OUT STD_ULOGIC
  );
END SRLatch_nor;

ARCHITECTURE dataflow OF SRLatch_nor IS
  SIGNAL qPrimInt: STD_ULOGIC;
  SIGNAL qInt: STD_ULOGIC;
BEGIN
  qInt <= r nor qPrimInt;
  qPrimInt <= s nor qInt;  
  q <= qInt;
  qPrim <= qPrimInt;
END dataflow;
