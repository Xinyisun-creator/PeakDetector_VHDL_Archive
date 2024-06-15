ENTITY tb_nand IS END tb_nand;

ARCHITECTURE testNand OF tb_nand IS

  COMPONENT gate
    PORT (
      a:IN BIT;
      b:IN BIT;
    
      q:OUT BIT
    );
  END COMPONENT;
  
  SIGNAL a_sig,b_sig,q_sig:BIT;
  SIGNAL c_sig:BIT_VECTOR(1 downto 0);

BEGIN

  C1:gate PORT MAP(a_sig,b_sig,q_sig);

  a_sig <= c_sig(1);
       
  b_sig <= c_sig(0);

  c_sig<=
    "00",			
    "01" AFTER 10 ns,
    "11" AFTER 20 ns,
    "10" AFTER 30 ns,
    "00" AFTER 40 ns;
 
END testNand;



