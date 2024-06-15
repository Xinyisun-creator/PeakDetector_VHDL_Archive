LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.ALL;


ENTITY tb_dataSource IS END;

ARCHITECTURE behav OF tb_dataSource IS
  COMPONENT dataSource IS
    PORT (
      clk: IN STD_ULOGIC;
      reset: in STD_ULOGIC;
      outValid: in STD_ULOGIC;
      A_out: out STD_ULOGIC_VECTOR(7 downto 0);
      B_out: out STD_ULOGIC_VECTOR(7 downto 0);
      C_out: out STD_ULOGIC_VECTOR(7 downto 0);
      D_out: out STD_ULOGIC_VECTOR(7 downto 0);
      E_out: out STD_ULOGIC_VECTOR(7 downto 0)
    );
  END COMPONENT;
  
  COMPONENT dataSampler IS
    PORT (
      clk: in STD_ULOGIC;
      reset: in STD_ULOGIC;
      outValid: out STD_ULOGIC;
      A_in: in STD_ULOGIC_VECTOR(7 downto 0);
      B_in: in STD_ULOGIC_VECTOR(7 downto 0);
      C_in: in STD_ULOGIC_VECTOR(7 downto 0);
      D_in: in STD_ULOGIC_VECTOR(7 downto 0);
      E_in: in STD_ULOGIC_VECTOR(7 downto 0);
      F_out: out STD_ULOGIC_VECTOR(15 downto 0);
      G_out: out STD_ULOGIC_VECTOR(15 downto 0)
    );
  END COMPONENT;
  
  FOR dSrc: dataSource USE ENTITY WORK.dataSource(behavioural);
  FOR dSmp_test: dataSampler USE ENTITY WORK.dataSampler(oneAdd_oneMult);
  
  SIGNAL clk, reset, complete : std_ulogic :='0';
  SIGNAL dataValid: std_ulogic; 
  SIGNAL A,B,C,D,E: std_ulogic_vector(7 downto 0);
  SIGNAL F,G,F2,G2, F3, G3: std_ulogic_vector(15 downto 0);
  CONSTANT clk_period_half: time := 5 ns;
  
BEGIN
  --generate Clk  
  clk <= NOT clk AFTER clk_period_half WHEN NOW < 3 us ELSE clk;
  reset <= '0', '1' AFTER 10 ns, '0' AFTER 20 ns;
    
  dSrc: dataSource PORT MAP(clk,reset,dataValid,A,B,C,D,E);
  dSmp: dataSampler PORT MAP(clk,reset,dataValid,A,B,C,D,E,F,G);
  
END behav;