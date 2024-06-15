LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_pattern_recog IS END;

ARCHITECTURE behav OF tb_pattern_recog IS
  COMPONENT pattern_recog 
    PORT (
      x: in	STD_ULOGIC;
      clk: in	STD_ULOGIC;
      reset: in	STD_ULOGIC;
      y: out		STD_ULOGIC);
  END COMPONENT;
  
  FOR t_mealy: pattern_recog USE ENTITY WORK.recog1(arch_mealy);
  FOR t_moore: pattern_recog USE ENTITY WORK.recog1(arch_moore);
  
  SIGNAL x, reset, clk: STD_ULOGIC :='0';
  SIGNAL y_mealy, y_moore: STD_ULOGIC;

BEGIN
  --generate clk
  clk <= NOT clk AFTER 50 ns WHEN NOW < 3 us ELSE clk; 
  x <= '0',
    '1' AFTER 120 ns,
    '0' AFTER 240 ns,
    '1' AFTER 400 ns,
    '0' AFTER 500 ns,
    '1' AFTER 600 ns,
    '0' AFTER 700 ns,
    '1' AFTER 1000 ns,
    '0' AFTER 1200 ns,
    '1' AFTER 1340 ns,
    '0' AFTER 1440 ns,
    '1' AFTER 1540 ns;
    
  reset <= '0' AFTER 10 ns,
    '1' AFTER 20 ns;
   
  t_mealy: pattern_recog PORT MAP(x,clk,reset,y_mealy);
  t_moore: pattern_recog PORT MAP(x,clk,reset,y_moore);
END behav;