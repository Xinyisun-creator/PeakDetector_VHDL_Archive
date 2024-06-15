library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.">"; -- overload the < operator for std_logic_vectors
use ieee.std_logic_unsigned."="; -- overload the = operator for std_logic_vectors
use work.common_pack.all;
use ieee.numeric_std.all; 


ENTITY cmdProc is
    port (
      -- overall control signal
      clk:		in std_logic;
      reset:		in std_logic;
      
      --RX port
      rxnow:		in std_logic; --valid
      rxData:			in std_logic_vector (7 downto 0); --Data
      rxdone:		out std_logic; -- done
      ovErr:		in std_logic; --OE error
      framErr:	in std_logic; --FE error
      
      --TX port
      txData:			out std_logic_vector (7 downto 0); -- data
      txnow:		out std_logic; 
      txdone:		in std_logic;
      
      -- command processor output signal
      start: out std_logic;
      numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0);
      
      -- command processor input signal
      dataReady: in std_logic;
      byte: in std_logic_vector(7 downto 0);
      maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
      dataResults: in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
      seqDone: in std_logic
    );
  end;
  
  ---->>>>>>>>>>>>>>>>>>>>> ARCHITECTURE <<<<<<<<<<<<<<<<<<<<<<<<----
  
ARCHITECTURE myArch OF cmdProc IS

 TYPE state_type IS
 (
  INIT, --- INIT all enable triggers and initial internal signals
  RECEIVE_ANNN_A, --- DETECT A ascii code from RX port in ANNN command
  RECEIVE_ANNN_N, --- DETECT A ascii code from RX port in ANNN command
  Tx_print_A, --- Print A in TX 
  Tx_print_N, --- Print N in TX
  Tx_print_error, --- Print wrong command and then back to INIT
  Measure_MaxNum, --- measure the numwords from ANNN command and transfer it into DATA PROCESSOR port.
  START_S,   --- transfer start signal to DATA ptocessor
  CONVERT,   --- get number from data processor and transfer the data into TX
  PRINT_NUMBER_1, --- print the first number of byte(0 to 3)
  PRINT_NUMBER_2, --- print the second number of byte(4 to 7)
  PRINT_SPACE, --- print space between numbers
  DETECT_LP, --- DETECT the L or P command
  TX_L_PRINT_Number_1, --- print the first number in L command
  TX_L_PRINT_Number_2, --- print the second number in L command
  TX_L_PRINT_SPACE, --- print the space in L command
  TX_P_PRINT_Number_1, --- print the first number in P command
  TX_P_PRINT_Number_2 --- print the second number in P command
 );-- insert states here
 
  TYPE logical_type is (TRUE, FALSE);
  
  --->>>counts and states<<<---
  SIGNAL count_ANNN: integer:=0;  ---- counts of ANNN
  SIGNAL count_start:integer:=0;  ---- counts of how many starts inputted in data processor.
  SIGNAL curState, nextState: state_type; --- states.
  SIGNAL TX_L_COUNTER:integer:=0; --- counts how many of figures printed in L command(MAX:7)
  SIGNAL TX_P_COUNTER:integer:=0; --- counts how many of elements printed in P command(MAX:6)
  
  --->>>RX VAR(YJR)<<<--- 
  SIGNAL detect_ANNN: bit;  --- detect if each byte of ANNN is input correctly
  SIGNAL LP_error: bit; --- detect if L and P are input correctly
  SIGNAL L_detect: bit; --- detect l signal
  SIGNAL P_detect: bit; --- detect p signal
    
  --->>>REG<<<---
  SIGNAL RX_REG:std_logic_vector (7 downto 0):=(others => '0'); --- store each letter IN EVERY STATSE
  SIGNAL data_reg: CHAR_ARRAY_TYPE (0 to 7); --- store all datas from data results that L command needed
  SIGNAL RX_ANNNreg: BCD_ARRAY_TYPE(0 to 3); ---store ANNN
  SIGNAL maxIndex_reg: BCD_ARRAY_TYPE(2 downto 0); ---store max index
  SIGNAL dataResults_reg: CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1); --store data results
  SIGNAL NumWords_BCD_reg: BCD_ARRAY_TYPE(0 to 2); --- store numwords
  SIGNAL BYTE_ASCII_REG:CHAR_ARRAY_TYPE(0 to 1); --- split byte format from BCD(2 HEX NUMBER) into ASCII format
  SIGNAL MaxNum:integer:=0; --- the max index
  SIGNAL TxData_reg:std_logic_vector(7 downto 0):=(others => '0'); --- store ASCII code needed by TX port
  SIGNAL SeqDone_reg:std_logic:='0'; --- store SeqDone.
  SIGNAL RESULTDATA_ASCII:CHAR_ARRAY_TYPE(0 to 13); --- 14 bytes. store all numbers of DATARESULT
  SIGNAL TX_P_REG:CHAR_ARRAY_TYPE(0 to 5):=(others =>(others => '0')); --- store max vlue(2bytes), a space(1 bytes), and max index(3 bytes)
  SIGNAL Byte_delay:std_logic_vector(7 downto 0):=(others => '0');
  
  --->>>EN<<<---
  SIGNAL Detect_ANNN_Enable: bit; --- enable the process to detect ANNN
  SIGNAL LP_enable: bit; --- enable LP detector to work
  SIGNAL RX_ANNNreg_EN:std_logic; --- add RXDATA INTO RX_RG WHEN TURE
  SIGNAL ASCII_TO_BCD_EN:std_logic; --- STORE numwords_BCD into REG
  SIGNAL check_seq_en:bit;--- Enable to check seqdone
  SIGNAL ByteTRANS_EN:bit;--- Enable to transfer byte from HEX BCD TO ASCII

  --->>>ASCII constant<<<---
  ---------------------------------------------------------
  --| ASCII constants that CMD processor needs identify |--
  ---------------------------------------------------------
  constant ASCII_NUM_pre: std_logic_vector (3 downto 0):= "0011"; 
  constant ASCII_NUM_A_BIG: std_logic_vector (7 downto 0):= "01000001"; 
  constant ASCII_NUM_a_small: std_logic_vector (7 downto 0):= "01100001";
  constant ASCII_NUM_L_BIG: std_logic_vector (7 downto 0):= "01001100";
  constant ASCII_NUM_l_small: std_logic_vector (7 downto 0):= "01101100";
  constant ASCII_NUM_P_BIG: std_logic_vector (7 downto 0):= "01010000";
  constant ASCII_NUM_p_small: std_logic_vector (7 downto 0):= "01110000";
  constant ASCII_SPACE: std_logic_vector (7 downto 0):= "00100000";
  
  -- B TO F ASCII constant--
  ---------------------------------------------------------
  --| ASCII constants of alphabets needed by HEX format |--
  ---------------------------------------------------------
  constant ASCII_NUM_B_BIG: std_logic_vector (7 downto 0):= "01000010";
  constant ASCII_NUM_C_BIG: std_logic_vector (7 downto 0):= "01000011";
  constant ASCII_NUM_D_BIG: std_logic_vector (7 downto 0):= "01000100";
  constant ASCII_NUM_E_BIG: std_logic_vector (7 downto 0):= "01000101";
  constant ASCII_NUM_F_BIG: std_logic_vector (7 downto 0):= "01000110";
  
  --->>>HEX(BCD) constant<<<---
  ---------------------------------------------------------
  --|   HEX code of alphabets that HEX format needed.   |--
  ---------------------------------------------------------
  constant HEX_A:std_logic_vector (3 downto 0):= "1010";
  constant HEX_B:std_logic_vector (3 downto 0):= "1011";
  constant HEX_C:std_logic_vector (3 downto 0):= "1100";
  constant HEX_D:std_logic_vector (3 downto 0):= "1101";
  constant HEX_E:std_logic_vector (3 downto 0):= "1110"; 
  constant HEX_F:std_logic_vector (3 downto 0):= "1111"; 
  
  --->>>OTHER<<<---
  SIGNAL TX_L_DONE:std_logic; --- '1' if L command finished well
  SIGNAL TX_P_DONE:std_logic; --- '1' if P command finished well
  
  
----------------------------------------------------- 
----------------------------------------------------- 
BEGIN 
cmdProc_NextState: process(curState,byte,detect_ANNN,txDone,L_detect,P_detect) --insert triggering states here
BEGIN


--|next clock, go to RECEIVE_ANNN_A state then receive A of ANNN command 
  CASE curState IS   
    WHEN INIT =>
      nextState <= RECEIVE_ANNN_A; 
      count_ANNN <= 0;         

--|if getting A well and no error happen, go to print A in TX port.  
--|if something is wrong, print current error message and go to INIT.
    WHEN RECEIVE_ANNN_A => 
      IF detect_ANNN = '1'  THEN
        nextState <= Tx_print_A; --- transfer next state to make sure ANNN's information storing well
      ELSIF ovErr = '1' or framErr = '1' THEN --or RX_inputERROR = '1' 
        nextState <= Tx_print_error;
      ELSE
        nextState <= RECEIVE_ANNN_A;
      END IF;

--| PRINT A in TX port, and then add 1 in count_ANNN. 
--| about count_ANNN:                                 
--| A:1, AN:2, ANN:3, ANNN:4.                         
--| If count_ANNN is 4, ANNN command is prepared well.
    WHEN Tx_print_A =>
      IF TxDone = '1' THEN
        nextState <= RECEIVE_ANNN_N;
        count_ANNN <= count_ANNN + 1;
      ELSE
        nextState <= Tx_print_A;
      END IF;

--|if getting number well and no error happen, go to print numver in TX port.
--|if something is wrong, print current error message and go to INIT.        
    WHEN RECEIVE_ANNN_N =>
      IF ovErr = '1' or framErr = '1' THEN
        nextState <= Tx_print_error;  
      ELSIF detect_ANNN = '1' and count_ANNN <=3 THEN
        nextState <= Tx_print_N;
      ELSIF count_ANNN=4 and Txdone='1' THEN
        nextState <= Tx_print_N;
      ELSE 
        nextState <= RECEIVE_ANNN_N;
      END IF;

--| PRINT number in TX port, and then add 1 in count_ANNN.|
    WHEN Tx_print_N =>
      IF txDone='1' THEN
        IF count_ANNN <= 3  THEN
          nextState <= RECEIVE_ANNN_N;
          count_ANNN <= count_ANNN + 1;
        ELSIF count_ANNN = 4 THEN       --- receiving all needed number.
          nextState <= Measure_MaxNum;
        END IF;
      ELSE
        nextState <= Tx_print_N;
      END IF;
      
--| PRINT wrong RXinput in TX port, and then back to INIT.|  
    WHEN Tx_print_error =>
      IF TxDone = '0' THEN
        nextState <= Tx_print_error;
      ELSIF TxDone = '1' THEN
        nextState <= INIT;
      END IF;
      
--| Measure MAXindex by ANNN         
    WHEN Measure_MaxNum =>
      nextState <= Start_s;
      
--| send Start to data processor
    WHEN START_S => 
      nextState <= CONVERT;
      
--| get number from data processor and transfer the data into TX  
    WHEN CONVERT => 
      IF byte = byte_delay THEN--when they are same, don't need to change the state
        nextState <= CONVERT;
      ELSE                     --when there is a change
        nextState <= PRINT_NUMBER_1;
      END IF;
      
--| Print first number of a figure.
    WHEN  PRINT_NUMBER_1 =>
      IF  TXdone ='1' THEN
        nextState <= PRINT_NUMBER_2;
      ELSE
        nextState <= PRINT_NUMBER_1;
      END IF;
      
--| Print second number of a figure.        
    WHEN PRINT_NUMBER_2 => 
      IF TXdone = '1' THEN
        nextState <= PRINT_SPACE;
      ELSE
        nextState <= PRINT_NUMBER_2;
      END IF;

--| Print space between figrues and detect whether seqDone is ready.                
--| seqDone:1. nextStep: detect L or P command.                                     
--| seqDone:0, Txdone and dataReady:1. nextStep: give start to dataProcessor again. 
    WHEN PRINT_SPACE =>
      IF seqDone_reg = '1' THEN
        nextState <= DETECT_LP;
      ELSIF TXdone = '1' and dataReady='1' THEN
        nextState <= START_S;
      ELSE
        nextState <= PRINT_SPACE;
      END IF;
      
--| Detect L or P command from RX port.
--| If getting A again, back to detecting ANNN and print A.
--| If getting L, go to run L command.If getting P, go to run P command.
--| If getting wrong message, go back to INIT.
    WHEN DETECT_LP => 
      count_ANNN <= 0; 
      IF LP_error = '1' THEN
        nextState <= INIT;   
      ELSIF L_detect = '1' and TX_L_DONE = '0' THEN
        nextState <= TX_L_PRINT_Number_1;
      ELSIF P_detect = '1' and TX_P_DONE = '0' THEN
        nextState <= TX_P_PRINT_Number_1;
      ELSIF detect_ANNN = '1' THEN
        nextState <= Tx_print_A;
      ELSE 
        nextState <= DETECT_LP;
      END IF;
      
--|Print first number of each elements in dataResults.
    WHEN TX_L_PRINT_Number_1=>
      IF TXdone = '1' THEN
        nextState <= TX_L_PRINT_Number_2;
      ELSE
        nextState <= TX_L_PRINT_Number_1;
      END IF;
      
--|Print second number of each elements in dataResults.      
    WHEN TX_L_PRINT_Number_2=>
      IF TXdone = '1' THEN
        nextState <= TX_L_PRINT_SPACE;
      ELSE
        nextState <= TX_L_PRINT_Number_2;
      END IF;
      
--|Print spaces between elements in dataResults.
--|TX_L_COUNTER:7 , printting is finished. Detect L or P agian.
--|otherwise, go back to print other elements in dataResults.
    WHEN TX_L_PRINT_SPACE =>
      IF TX_L_COUNTER = 7 THEN
        nextState <= DETECT_LP;
      ELSIF TX_L_COUNTER < 7 and TXdone ='1' THEN
        nextState <= TX_L_PRINT_Number_1;
      ELSE
        nextState <= TX_L_PRINT_SPACE;
      END IF;
      
--|The state is used to print the number with index of 0,2,4 in P list(length:6).
--|If everything was printed done, then go back to detect_LP to check next command and stop printing. 
--|Otherwise, go to print next number or stay waiting and printing.      
    WHEN TX_P_PRINT_Number_1=>
      IF TXdone = '1' AND TX_P_COUNTER=6 THEN
        nextState <= DETECT_LP;
      ELSIF TXdone = '1' AND TX_P_COUNTER<6 THEN
        nextState <= TX_P_PRINT_Number_2;
      ELSE
        nextState <= TX_P_PRINT_Number_1;
      END IF;
      
--|The state is used to print the number with index of 1,3,5 in P list(length:6).
--|If number is printed well, then go back TX_P_PRINT_Number_1 state to print next number.
--|Otherwise, stay waiting and printing.  
    WHEN TX_P_PRINT_Number_2=>
      IF TXdone = '1' AND TX_P_COUNTER<6 THEN
        nextState <= TX_P_PRINT_Number_1;
      ELSE
        nextState <= TX_P_PRINT_Number_2;
      END IF;
      
  END CASE; 
END PROCESS;
  
-----------------------------------------------------   
  STATES_timing_process: PROCESS(clk, reset)
  BEGIN
    IF clk'event and clk='1' THEN
      curState <= nextState; 
    ELSIF reset = '1' THEN
      curState <= INIT;    
    END IF;
  END PROCESS;     
-----------------------------------------------------   
  combi_EN_trigger: PROCESS(curState,byte) 
  BEGIN
  -- initialize signals
  Detect_ANNN_Enable <= '0';
  LP_enable <= '0';
  RX_ANNNreg_EN <= '0';
  ASCII_TO_BCD_EN <= '0';
  check_seq_en <= '0';
  ByteTRANS_EN <= '0';
    
  CASE curState IS
    WHEN INIT =>
    --|initialize relevant signals
      START<='0';
      txnow<='0';
      count_start <= 0;
      numWords_bcd<=(others =>(others =>'0'));
      
      TX_L_DONE <= '0';
      TX_P_DONE <= '0';
      
      rxdone<='1';
         
    WHEN RECEIVE_ANNN_A =>  
    --|enable the register of "DetectANNN_LP" to detect and store "A" in "ANNN"
    --|convert ASCII to BCD format
      rxdone<='0';
      Detect_ANNN_Enable <= '1';
      RX_ANNNreg_en <= '1';
      ASCII_TO_BCD_EN <= '1';
      
    WHEN Tx_print_A =>
    --|enable Tx to print "A" in the sequence "ANNN"
      TxData_reg <= Rx_reg;
      txnow <= '1';
      rxDone <= '1';
      
    WHEN RECEIVE_ANNN_N =>
    --|enable the register of "DetectANNN_LP" to detect and store "N" in "ANNN"
    --|convert ASCII to BCD format
      rxdone<='0';
      Detect_ANNN_Enable <= '1';
      RX_ANNNreg_en <= '1';
      ASCII_TO_BCD_EN <= '1';
            
    WHEN Tx_print_N =>
    --|enable Tx to print "N" in the sequence "ANNN"
      TxData_reg <= Rx_reg;
      txnow <= '1';
      rxDone <= '1';
      
    WHEN Tx_print_error =>
    --|send "done" to Rx in order to tell it all data has been successfully read and clear register
      rxDone <= '1';
      
    WHEN Measure_MaxNum =>
    --|convert BCD to decimal format for the results of P
      numWords_bcd <= numWords_bcd_reg;
      MaxNum <= (to_integer(unsigned(numWords_bcd_reg(0)))*100+to_integer(unsigned(numWords_bcd_reg(1)))*10+to_integer(unsigned(numWords_bcd_reg(2))));
     
    WHEN Start_s =>
    --|send "start" to data processer in order to tell it to send all signals from data generator
      IF count_start <= MaxNum-1 THEN
        start <='1';
        count_start <= count_start + 1;
      ELSE
        start <='0';
      END IF;
            
    WHEN CONVERT => 
    --|get number from data processor and transfer the data into TX
      ByteTRANS_EN  <= '1';
      start <='0';
      
    WHEN PRINT_NUMBER_1 =>
    --|convert hexadecimal to BCD format
    --|print the first 4-bit signal from data processor
      
      IF byte(7 downto 4) <= "1001" THEN
        TxData_reg <= ASCII_NUM_pre & byte(7 downto 4);
      ELSIF byte(7 downto 4) = HEX_A THEN
        TxData_reg <= ASCII_NUM_A_BIG;
      ELSIF byte(7 downto 4) = HEX_B THEN
        TxData_reg <= ASCII_NUM_B_BIG;
      ELSIF byte(7 downto 4) = HEX_C THEN
        TxData_reg <= ASCII_NUM_C_BIG;    
      ELSIF byte(7 downto 4) = HEX_D THEN
        TxData_reg <= ASCII_NUM_D_BIG;
      ELSIF byte(7 downto 4) = HEX_E THEN
        TxData_reg <= ASCII_NUM_E_BIG;
      ELSIF byte(7 downto 4) = HEX_F THEN
        TxData_reg <= ASCII_NUM_F_BIG;
      END IF;
      TXNOW <='1' ;  
      
    WHEN PRINT_NUMBER_2 => 
    --|convert hexadecimal to BCD format
    --|print the second 4-bit signal from data processor
      IF byte(3 downto 0) <= "1001" THEN
        TxData_reg <= ASCII_NUM_pre & byte(3 downto 0);
      ELSIF byte(3 downto 0) = HEX_A THEN
        TxData_reg <= ASCII_NUM_A_BIG;
      ELSIF byte(3 downto 0) = HEX_B THEN
        TxData_reg <= ASCII_NUM_B_BIG;
      ELSIF byte(3 downto 0) = HEX_C THEN
        TxData_reg <= ASCII_NUM_C_BIG;    
      ELSIF byte(3 downto 0) = HEX_D THEN
        TxData_reg <= ASCII_NUM_D_BIG;
      ELSIF byte(3 downto 0) = HEX_E THEN
        TxData_reg <= ASCII_NUM_E_BIG;
      ELSIF byte(3 downto 0) = HEX_F THEN
        TxData_reg <= ASCII_NUM_F_BIG;
      END IF;
      TXNOW <='1' ; 
      
    WHEN PRINT_SPACE =>
    --|add space between data
      TXnow <='1';
      TxData_reg <= ASCII_SPACE; 
      IF seqDone_reg = '1' THEN
        rxDone <= '1';  -- if all the signals have been sent, tell Rx to clear its register
      ELSE 
        rxDone <= '0';
      END IF;
      TX_L_DONE <= '0';
      TX_P_DONE <= '0';

    WHEN DETECT_LP =>
    --|detect L and P
      rxdone<='0';
      count_start <= 0;      
      
      IF detect_ANNN = '1' THEN  -- if the next input signal is another ANNN, stop detecting L and P, instead detect ANNN again
        RX_ANNNreg_en <= '1';
        ASCII_TO_BCD_EN <= '1'; 
      ELSIF L_detect = '1' and TX_L_DONE = '0' THEN  -- initialize the counter of L
        TX_L_COUNTER<=0;
      ELSIF P_detect = '1' and TX_P_DONE = '0' THEN  -- initialize the counter of L
        TX_P_COUNTER<=0;
      END IF;
            
    WHEN TX_L_PRINT_Number_1=>
    --|enable Tx to print the first bit of each data in L result
      TX_L_done<='1';
      Txdata_reg <=  RESULTDATA_ASCII(2*TX_L_COUNTER);
      TXNOW <='1' ;  
      
    WHEN TX_L_PRINT_Number_2=>
    --|enable Tx to print the second bit of each data in L result
      Txdata_reg <= RESULTDATA_ASCII(2*TX_L_COUNTER+1);
      TXNOW <='1' ;  
      
    WHEN TX_L_PRINT_SPACE =>
    --|add space between each data in L result
      IF TX_L_COUNTER < 7 and TXdone ='1' THEN
        TX_L_COUNTER<=TX_L_COUNTER+1;
      END IF;
      Txdata_reg <= ASCII_SPACE;
      TXNOW <='1' ;  
      
    WHEN TX_P_PRINT_Number_1=> 
    --|enable Tx to print even bits of P result
      TX_P_done <='1';
      IF TX_P_COUNTER < 7 and TXdone = '1'  THEN
        TX_P_COUNTER <= TX_P_COUNTER+1;
      END IF;
      Txdata_reg <= Tx_P_reg(TX_P_COUNTER);
      TXNOW <='1' ; 
       
    WHEN TX_P_PRINT_Number_2 =>
    --|enable Tx to print odd bits of P result
      IF TX_P_COUNTER < 7 and TXdone = '1'  THEN
        TX_P_COUNTER <= TX_P_COUNTER+1;
      END IF;
      Txdata_reg <= Tx_P_reg(TX_P_COUNTER);
      TXNOW <='1' ;  
   
    WHEN others =>
    --|if there are redundant states, do not run any signals
      
  END CASE;

END PROCESS;

---------------------------------------------------
 SeqDone_register: PROCESS(reset,curState,seqDONE) --- generate signal to enable Tx to output all the signals from data generator
 BEGIN
  IF reset='1' or curState = INIT or curState = Tx_print_A THEN
    SeqDone_reg <= '0';
  ELSIF SeqDone = '1' THEN
    SeqDone_reg<= '1';
  END IF;
 END PROCESS;
----------------------------------------------------
 RX_and_SEQ_REG: PROCESS (clk, reset)  --- register rxData from Rx and output txData which stored in register
 BEGIN
  IF rising_edge(CLK) THEN
    RX_reg <= rxData;
    txData <= TxData_reg;
  ELSIF reset = '1' THEN
    RX_reg <= (others => '0');
  END IF;
 END PROCESS;
-----------------------------------------------------
 BYTE_BCD_TO_ASCII: PROCESS(byte) --- convert BCD to ASCII
 BEGIN
  for i in 0 to 1 loop
    IF i = 0 THEN
      CASE byte(7 downto 4) IS --- correspond the bits to relevant ASCII code
        WHEN HEX_A =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_A_BIG;
        WHEN HEX_B =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_B_BIG;
        WHEN HEX_C =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_C_BIG;
        WHEN HEX_D =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_D_BIG;
        WHEN HEX_E =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_E_BIG;
        WHEN HEX_F =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_F_BIG;
        WHEN others =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_pre & byte(7 downto 4);
      END CASE;
    ELSE
      CASE byte(3 downto 0) IS
        WHEN HEX_A =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_A_BIG;
        WHEN HEX_B =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_B_BIG;
        WHEN HEX_C =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_C_BIG;
        WHEN HEX_D =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_D_BIG;
        WHEN HEX_E =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_E_BIG;
        WHEN HEX_F =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_F_BIG;
        WHEN others =>
          BYTE_ASCII_REG(i) <= ASCII_NUM_pre & byte(3 downto 0);    
      END CASE;
    END IF;
  END LOOP;
 END PROCESS;
-----------------------------------------------------
 DetectANNN_LP: PROCESS(rxnow,rxdata) --- detect if ANNN and L and P are input correctly
 BEGIN
   IF rxnow = '1' AND Detect_ANNN_Enable = '1' THEN 
     IF count_ANNN = 0 THEN --- IF count is 0, check A and then plus 1
        IF rxData = ASCII_NUM_A_BIG or rxData = ASCII_NUM_a_SMALL THEN
           detect_ANNN <= '1';  --- A is input correctly   
        ELSE 
           detect_ANNN <= '0'; 
        END IF;
        
     ELSIF count_ANNN <4 and count_ANNN >= 1  THEN --- check NNN
        IF rxData(7 downto 4) = ASCII_NUM_pre THEN
          detect_ANNN <= '1'; --- N is input correctly
        ELSE
          detect_ANNN <= '0';
        END IF;   
     ELSIF count_ANNN = 4 AND Detect_ANNN_Enable = '1' THEN --- impossible situation
          detect_ANNN <= '0';    
     END IF;
     
   ELSIF curState = DETECT_LP and rxnow = '1' THEN --- check which signal is detected (ANNN,L,P)
      IF rxData = ASCII_NUM_A_BIG or rxData = ASCII_NUM_a_SMALL THEN
        detect_ANNN <= '1';
      ELSIF rxdata = ASCII_NUM_L_BIG or rxdata = ASCII_NUM_l_small THEN
        L_detect <= '1';
      ELSIF rxdata = ASCII_NUM_P_BIG or rxdata = ASCII_NUM_p_small THEN  
        P_detect <= '1';
      ELSE
        LP_error <= '1';  --- If none of them are detected, it means that L or P are input incorrectly
        detect_ANNN <= '0';
        L_detect <= '0';
        P_detect <= '0'; 
      END IF;
      
    ELSE 
      L_detect <= '0';
      P_detect <= '0';
      detect_ANNN <= '0';
      LP_error <= '0';
    END IF;
    
 END PROCESS; 
------------------------------------------------------ 
 RXANNNreg: PROCESS(reset,count_ANNN) --- store signals from RX with BCD format
 BEGIN
    IF reset = '1' THEN
      RX_ANNNreg <= (others => (others =>'0'));
    ELSIF count_ANNN=1 THEN
      RX_ANNNreg(3) <= rxData(3 downto 0);
    ELSIF count_ANNN=2 THEN
      RX_ANNNreg(2) <= rxData(3 downto 0);
    ELSIF count_ANNN=3 THEN
      RX_ANNNreg(1) <= rxData(3 downto 0);
    ELSIF count_ANNN=4 THEN
      RX_ANNNreg(0) <= rxData(3 downto 0);
    END IF;
 END PROCESS;
-----------------------------------------------------
 ANNN_ascii_to_BCD: PROCESS(reset,ascii_to_bcd_EN,count_ANNN) --- register the BCD signals to prepare for decimal conversion
 BEGIN
   IF reset = '1' THEN
     NumWords_BCD_reg <= (others => (others =>'0'));
   ELSE
     if ascii_to_bcd_EN = '1' and count_ANNN <= 4 and count_ANNN > 1 then --- store NNN
       NumWords_BCD_reg(2) <= RX_ANNNreg(0);
       NumWords_BCD_reg(1) <= RX_ANNNreg(1);
       NumWords_BCD_reg(0) <= RX_ANNNreg(2);
     END IF;
   END IF;
 END PROCESS;
-----------------------------------------------------      
 TX_L_dataResults_TO_ASCII: PROCESS(dataResults) --- Output the results of L to Tx
 --- The results of L: 3 bytes preceding the peak, the peak byte itself and the 3 bytes following the peak in the order received with hexadecimal format 
 BEGIN
  for i in 0 to 6 loop
    --- correspond the first four bits to relevant ASCII code 
    IF dataResults(i)(7 downto 4) <= "1001" THEN 
      RESULTDATA_ASCII(2*i) <= ASCII_NUM_pre & dataResults(i)(7 downto 4);
    ELSIF dataResults(i)(7 downto 4) = HEX_A THEN
      RESULTDATA_ASCII(2*i) <= ASCII_NUM_A_BIG;
    ELSIF dataResults(i)(7 downto 4) = HEX_B THEN
      RESULTDATA_ASCII(2*i) <= ASCII_NUM_B_BIG;
    ELSIF dataResults(i)(7 downto 4) = HEX_C THEN
      RESULTDATA_ASCII(2*i) <= ASCII_NUM_C_BIG;    
    ELSIF dataResults(i)(7 downto 4) = HEX_D THEN
      RESULTDATA_ASCII(2*i) <= ASCII_NUM_D_BIG;
    ELSIF dataResults(i)(7 downto 4) = HEX_E THEN
      RESULTDATA_ASCII(2*i) <= ASCII_NUM_E_BIG;
    ELSIF dataResults(i)(7 downto 4) = HEX_F THEN
      RESULTDATA_ASCII(2*i) <= ASCII_NUM_F_BIG;
    END IF;
    --- correspond the second four bits to relevant ASCII code
    IF dataResults(i)(3 downto 0) <= "1001" THEN
      RESULTDATA_ASCII(2*i+1) <= ASCII_NUM_pre & dataResults(i)(3 downto 0);
    ELSIF dataResults(i)(3 downto 0) = HEX_A THEN
      RESULTDATA_ASCII(2*i+1) <= ASCII_NUM_A_BIG;
    ELSIF dataResults(i)(3 downto 0) = HEX_B THEN
      RESULTDATA_ASCII(2*i+1) <= ASCII_NUM_B_BIG;
    ELSIF dataResults(i)(3 downto 0) = HEX_C THEN
      RESULTDATA_ASCII(2*i+1) <= ASCII_NUM_C_BIG;    
    ELSIF dataResults(i)(3 downto 0) = HEX_D THEN
      RESULTDATA_ASCII(2*i+1) <= ASCII_NUM_D_BIG;
    ELSIF dataResults(i)(3 downto 0) = HEX_E THEN
      RESULTDATA_ASCII(2*i+1) <= ASCII_NUM_E_BIG;
    ELSIF dataResults(i)(3 downto 0) = HEX_F THEN
      RESULTDATA_ASCII(2*i+1) <= ASCII_NUM_F_BIG;
    END IF;
    
   End loop;
    
 END PROCESS;
-----------------------------------------------------
TX_P_INDEX_REG:PROCESS(dataResults,maxIndex) --- Output the results of P to Tx
 --- The results of P: First two bits are the value of peak, followed by a space and its index in decimal format
 BEGIN
  --- correspond the first bit to relevant HEX code
  IF dataResults(3)(7 downto 4) <= "1001" THEN
    TX_P_REG(0) <= ASCII_NUM_pre & dataResults(3)(7 downto 4);
  ELSIF dataResults(3)(7 downto 4) = HEX_A THEN
    TX_P_REG(0) <= ASCII_NUM_A_BIG;
  ELSIF dataResults(3)(7 downto 4) = HEX_B THEN
    TX_P_REG(0) <= ASCII_NUM_B_BIG;
  ELSIF dataResults(3)(7 downto 4) = HEX_C THEN
    TX_P_REG(0) <= ASCII_NUM_C_BIG;    
  ELSIF dataResults(3)(7 downto 4) = HEX_D THEN
    TX_P_REG(0) <= ASCII_NUM_D_BIG;
  ELSIF dataResults(3)(7 downto 4) = HEX_E THEN
    TX_P_REG(0) <= ASCII_NUM_E_BIG;
  ELSIF dataResults(3)(7 downto 4) = HEX_F THEN
    TX_P_REG(0) <= ASCII_NUM_F_BIG;
  END IF;
  --- correspond the second bit to relevant HEX code 
  IF dataResults(3)(3 downto 0) <= "1001" THEN
    TX_P_REG(1) <= ASCII_NUM_pre & dataResults(3)(3 downto 0);
  ELSIF dataResults(3)(3 downto 0) = HEX_A THEN
    TX_P_REG(1) <= ASCII_NUM_A_BIG;
  ELSIF dataResults(3)(3 downto 0) = HEX_B THEN
    TX_P_REG(1) <= ASCII_NUM_B_BIG;
  ELSIF dataResults(3)(3 downto 0) = HEX_C THEN
    TX_P_REG(1) <= ASCII_NUM_C_BIG;    
  ELSIF dataResults(3)(3 downto 0) = HEX_D THEN
    TX_P_REG(1) <= ASCII_NUM_D_BIG;
  ELSIF dataResults(3)(3 downto 0) = HEX_E THEN
    TX_P_REG(1) <= ASCII_NUM_E_BIG;
  ELSIF dataResults(3)(3 downto 0) = HEX_F THEN
    TX_P_REG(1) <= ASCII_NUM_F_BIG;
  END IF;
  
  Tx_P_REG(2)<= ASCII_SPACE; --- add space between value and index
  TX_P_REG(3)<= ASCII_NUM_pre & maxIndex(2); --- register the peak index
  TX_P_REG(4)<= ASCII_NUM_pre & maxIndex(1);
  TX_P_REG(5)<= ASCII_NUM_pre & maxIndex(0);
  
END PROCESS;
-----------------------------------------------------
Byte_Reg:PROCESS(clk)--- Record the delay of the byte to check if the byte is changed.
BEGIN
  IF rising_edge(clk) THEN
    Byte_delay<=Byte;
  END IF;
End Process;
  
END;