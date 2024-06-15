LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY tb_dLatch is END;

ARCHITECTURE behav of tb_dLatch IS
  COMPONENT dLatch
    PORT (
    d:IN STD_ULOGIC;
    clk:IN STD_ULOGIC;
    qPrim:OUT STD_ULOGIC;
    q:OUT STD_ULOGIC
  );
  END COMPONENT;
  
  FOR D_gate: dLatch USE ENTITY WORK.dLatch(dataflow);
  FOR D_behav1: dLatch USE ENTITY WORK.dLatch(behav1);
  FOR D_behav2: dLatch USE ENTITY WORK.dLatch(behav2);
  
  SIGNAL q_gate,qPrim_gate, q_behav1, qPrim_behav1, q_behav2, qPrim_behav2:STD_ULOGIC;
  SIGNAL clk,d_in:STD_ULOGIC;
  
BEGIN
  clk <= 
    '0',
    '1' AFTER 5 ns,
    '0' AFTER 10 ns,
    '1' AFTER 15 ns,
    '0' AFTER 20 ns,
    '1' AFTER 25 ns,
    '0' AFTER 30 ns,
    '1' AFTER 35 ns,
    '0' AFTER 40 ns;
    
  d_in <= 
		'1',
		'1' AFTER 5 ns,
		'1' AFTER 10 ns,
		'1' AFTER 15 ns,
		'0' AFTER 18 ns,
		'1' AFTER 22 ns,
		'0' AFTER 26 ns,
		'1' AFTER 28 ns,
		'0' AFTER 30 ns,
		'1' AFTER 35 ns,
		'1' AFTER 40 ns;
	
  D_gate:Dlatch PORT MAP(d=>d_in, clk=>clk, qPrim=>qPrim_gate, q=>q_gate);
  D_behav1:Dlatch PORT MAP(d=>d_in, clk=>clk, qPrim=>qPrim_behav1, q=>q_behav1);
  D_behav2:Dlatch PORT MAP(d=>d_in, clk=>clk, qPrim=>qPrim_behav2, q=>q_behav2);
END behav;
 




