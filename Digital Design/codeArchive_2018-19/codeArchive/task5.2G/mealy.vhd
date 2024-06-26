-- Mealy Machine (mealy.vhd)
-- Asynchronous reset, active low
------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY recog1 IS
PORT(
  x: in STD_ULOGIC;
  clk: in STD_ULOGIC;
  reset: in STD_ULOGIC;
  y: out STD_ULOGIC);
end;

ARCHITECTURE arch_mealy OF recog1 IS
  -- State declaration
  TYPE state_type IS (INIT, FIRST ....);  -- List your states here 	
  SIGNAL curState, nextState: state_type;
BEGIN
  -----------------------------------------------------
  combi_nextState: PROCESS(curState, x)
  BEGIN
    CASE curState IS
      WHEN INIT =>
        IF x='0' THEN 
          nextState <= FIRST;
        ELSE
          ...... -- Fill in
          ......
        END IF;
        
      WHEN FIRST =>
        IF x='0' THEN
          nextState <= ? -- Fill in
        ELSE
          ............? -- Fill in
        END IF;
      WHEN ............ -- Fill in
        ..............
    END CASE;
  END PROCESS; -- combi_nextState
  -----------------------------------------------------
  combi_out: PROCESS(curState, x)
  BEGIN
    y <= '0'; -- assign default value
    IF curState = THIRD AND x='1' THEN
      y <= '1';
    END IF;
  END PROCESS; -- combi_output
  -----------------------------------------------------
  seq_state: PROCESS (clk, reset)
  BEGIN
    IF reset = '0' THEN
      curState <= INIT;
    ELSIF clk'EVENT AND clk='1' THEN
      curState <= nextState;
    END IF;
  END PROCESS; -- seq
  -----------------------------------------------------
END; -- arch_mealy
