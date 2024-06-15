LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY tb_latchVsff is END;

ARCHITECTURE behav of tb_latchVsff IS
  
  COMPONENT dLatch
    PORT (
      d:IN STD_ULOGIC;
      clk:IN STD_ULOGIC;
      reset:STD_ULOGIC;
      q:OUT STD_ULOGIC;
      qPrim:OUT STD_ULOGIC
    );
  END COMPONENT;
  
  COMPONENT ff
    PORT (
      d:IN STD_ULOGIC;
      clk:IN STD_ULOGIC;
      reset:in STD_ULOGIC;
      q:OUT STD_ULOGIC;
      qPrim:OUT STD_ULOGIC
    );
  END COMPONENT;
  
  FOR dL_behav: dLatch USE ENTITY WORK.dLatch(behav);

  FOR ff_behav: ff USE ENTITY WORK.ff(behav);
  
  SIGNAL q_latch, qPrim_latch, q_FF, qPrim_FF:STD_ULOGIC; -- outputs
  SIGNAL reset_in, d_in, clk:STD_ULOGIC; -- inputs
BEGIN
  
  reset_in <= '1', '0' AFTER 2 ns, '1' AFTER 4 ns;
  
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
    '0',
    '1' AFTER 7 ns,
    '0' AFTER 12 ns,
    '1' AFTER 14 ns,
    '0' AFTER 22 ns,
    '1' AFTER 26 ns,
    '0' AFTER 28 ns,
    '1' AFTER 35 ns,
    '0' AFTER 42 ns; 

  dL_behav:dLatch PORT MAP(d => d_in, clk => clk, reset => reset_in, qPrim => qPrim_latch, q => q_latch);
  ff_behav:ff PORT MAP(d => d_in, clk => clk, reset => reset_in, qPrim => qPrim_ff, q => q_ff);
END behav;
 




