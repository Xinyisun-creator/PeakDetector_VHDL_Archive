ENTITY gate IS
  PORT (
    a:IN BIT;
    b:IN BIT;
    
    q:OUT BIT
  );
END gate;

ARCHITECTURE dataflow OF gate IS

  SIGNAL q_prim : BIT;
  
BEGIN

  q_prim <= a AND b AFTER 5 ns;
  
  q <= NOT q_prim;
  
END dataflow;

