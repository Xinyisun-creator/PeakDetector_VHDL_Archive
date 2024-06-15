ENTITY tb_recog2 IS END;

ARCHITECTURE behav OF tb_recog2 IS
  COMPONENT recog2 
    port (
      X: in	bit;
      CLK: in	bit;
      RESET: in	bit;
      Y: out		bit);
  END COMPONENT;
  
  FOR r_myArch: recog2 USE ENTITY WORK.recog2(myArch);
  
  SIGNAL x, reset, clk: bit :='0';
  SIGNAL y: bit;
  CONSTANT clk_period_half: time := 5 ns;
  --CONSTANT no_of_cycles: integer := 4; -- no of cycles for result to be valid
BEGIN
  --generate Clk
  clk <= NOT Clk AFTER clk_period_half WHEN NOW < 3 us ELSE clk; 
  x <= '0', '1' AFTER 12 ns, '0' AFTER 24 ns, '1' AFTER 100 ns, '0' AFTER 120 ns, '1' AFTER 130 ns,
    '0' AFTER 140 ns,'1' AFTER 150 ns, 
    '0' AFTER 180 ns,
    '1' AFTER 360 ns,
    '0' AFTER 550 ns,
    '1' AFTER 700 ns,
    '0' AFTER 870 ns;
    
  reset <= '0' AFTER 5 ns,
    '1' AFTER 10 ns;
   
   r_myArch: recog2 PORT MAP(x,clk,reset,y);

    
END;