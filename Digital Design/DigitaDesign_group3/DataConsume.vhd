library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use ieee.std_logic_unsigned."+";
use ieee.std_logic_unsigned."-";
use ieee.std_logic_unsigned."=";
--use work.dataConsume_pack.all;
use work.common_pack.all;



entity dataConsume is
	port (
	  clk:		in std_logic;
		reset:		in std_logic; -- Synchronous reset
		start:  in std_logic; -- Asserted (active-high) to signal data transfer
		numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0); -- Contain the BCD type number of bytes to process
		ctrlIn: in std_logic; -- Input from data generator
		ctrlOut: out std_logic; -- Output to data generator
		data: in std_logic_vector(7 downto 0); -- Data from the data generator
		dataReady: out std_logic; -- Asserted (active-high) to signify that a new byte of data that has been supplied
		byte: out std_logic_vector(7 downto 0);
		seqDone: out std_logic; -- Asserted (active-high) to signify that the result has been completed
		maxIndex: out BCD_ARRAY_TYPE(2 downto 0); -- Contain the BCD type number of peak number
		dataResults: out CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1) -- Contain the results in an Array type (three previous bytes, the peak byte, three later byte) 
	);
end dataConsume;

ARCHITECTURE Arch OF dataConsume IS
    type STATE_TYPE is
		(
			INIT,
			REQ_DATA,
			WAIT_DATA,
			DATA_VALID
		);
		
    SIGNAL curState, nextState: state_type;

    SIGNAL ctrlIn_delayed, ctrlIn_detected: std_logic; -- From data generator
    SIGNAL MaxNum : Integer; -- contain the integer number of bytes to process
    SIGNAL maxIndex_reg: BCD_ARRAY_TYPE(2 downto 0); -- The index of the 
    SIGNAL Result_Reg: CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1):=(others => (others =>'0')); -- index 3 holds the peak(0 to 6)
    SIGNAL Current_reg: CHAR_ARRAY_TYPE(0 to 3):=(others => (others =>'0')); -- Hold previous three datas and current data
    SIGNAL Index,Peak_Index: integer; -- Hold the current index and the index of peak value

    SIGNAL ctrlOut_reg: std_logic:='0'; -- Registor of the ctrlOut signal
    SIGNAL SeqCount: integer:=0; -- Count how many asserted seqdone  

BEGIN
  ctrlIn_detected <= ctrlIn xor ctrlIn_delayed;--detect the changing of ctrlIn signal
  combi_nextState: PROCESS(curState,start,ctrlIn_detected)
  BEGIN         
      CASE curState IS
      WHEN INIT =>
        IF start = '1' THEN
          nextState <= REQ_DATA;
        ELSE
          nextState <= INIT;
        END IF;
        
      --all the signals have been initialized and start to request data
      WHEN REQ_DATA =>
        nextState <=WAIT_DATA ;

      --the request data signal has been sent and wait for a data coming in
      when WAIT_DATA =>      
        --when the ctrlIn signal changes which means data has been given  
        IF ctrlIn_detected = '1' THEN
          nextState <= DATA_VALID; 
        ELSE         
          nextState <= WAIT_DATA; 
        END IF;

      --A data has come in and compare the number of data has been compared 
      --with the number of data which the user asked for  
      WHEN DATA_VALID =>
        IF Index < MaxNum-1 AND start = '1' THEN --if user's request has not been statified          
          nextState <=  REQ_DATA;
        ELSIF Index = MaxNum-1 THEN
          nextState <= INIT;-- all the process has done, go to initial state and wait for the user's another command
        ELSE  
          nextState <=  DATA_VALID;
        END IF;
        
    END CASE;
  END PROCESS;
--------------------------------------------------------------------------

combi_curState: PROCESS(curState,start,ctrlIn_detected)
BEGIN
CASE curState IS
  WHEN INIT =>
        --convert the bcd array to integer
        MaxNum <= (to_integer(unsigned(numWords_bcd(2)))*100+to_integer(unsigned(numWords_bcd(1)))*10+to_integer(unsigned(numWords_bcd(0)))) ;
        --initialize the signals
        Index <= -1;-- each number's index
        seqDone <= '0';
        byte <= (others => '0');
        
        IF SeqCount = 0 THEN
          dataResults<=(others => (others =>'0'));
          maxIndex<=(others => (others =>'0'));
          dataReady<='0';
        END IF;
        
  WHEN REQ_DATA =>
        --change the ctrlOut signal which means to ask for another data
        dataReady<='0';
        IF start = '1' THEN
          ctrlOut_reg <=NOT ctrlOut_reg;
        END IF;
        
  when WAIT_DATA =>      
        --when the ctrlIn signal changes which means data has been given  
        IF ctrlIn_detected = '1' THEN
          Index <= Index+1;--add index to 1 
          dataReady<='1';
          byte <= data;--assign the data to byte
        END IF;

        
  WHEN DATA_VALID =>
        IF Index = MaxNum-1 THEN
          maxIndex <= maxIndex_reg;
          seqDone <= '1';--all the process has been finished and give the command a done signal
          SeqCount<=SeqCount+1;
          dataResults <= Result_Reg;
        END IF;
  
  WHEN others =>
    
END CASE;
END PROCESS;


--------------------------------------------------------------------------

  seq_state: PROCESS (clk, reset)
  BEGIN
    --the reset signal is set high then initialize the current signal
    IF reset = '1' THEN
      curState <= INIT;      
	   
    ELSIF clk'EVENT AND clk='1' THEN
      curState <= nextState;
      ctrlOut <= ctrlOut_reg;
    END IF;
  END PROCESS; 
  ------------------------------------------------------------------------
  
  delay_CtrlIn: process(clk)     
  --the process is used to detect the changing of ctrlIn signal
  begin
    IF rising_edge(clk) THEN
      ctrlIn_delayed <= ctrlIn;
    END IF;
  end process;
  
  ------------------------------------------------------------------------
  Comparator:PROCESS(clk,Index)
  -- To compare the current byte with the peak before
  BEGIN  
    IF reset = '1' or curState = INIT THEN
      Peak_Index<=0;
      Result_Reg(3)<=data;
    ELSIF data > Result_Reg(3) THEN -- Reaching the new peak
      Result_Reg(0 to 3) <= Current_reg; -- Replace current byte and previous bytes to the result register
      Peak_Index<=Index; -- Renew the Peak Index
    END IF;
  END PROCESS;
  ------------------------------------------------------------------------
  Current_Register:PROCESS(clk)
  -- A Shift Register of the current byte and previous 3 bytes
  BEGIN
    IF rising_edge(clk) and ctrlIn_detected = '1' THEN 
      for i in 0 to 2 loop  
          Current_reg(i) <= Current_reg(i+1); 
      end loop;
      Current_reg(3) <= data;  
    END IF;
  END PROCESS;
  ------------------------------------------------------------------------
  Result_Register: PROCESS(Index,Peak_Index)
  -- when Peak index is renewed, record the later three byte to the result register
  BEGIN
      
      IF Index-Peak_Index=0 THEN 
        Result_Reg(4)<=(others =>'0');
        Result_Reg(5)<=(others =>'0');
        Result_Reg(6)<=(others =>'0');
      ELSIF Index-Peak_Index=1 THEN 
        Result_Reg(4)<=data;
        Result_Reg(5)<=(others =>'0');
        Result_Reg(6)<=(others =>'0');
      ELSIF Index-Peak_Index=2 THEN 
        Result_Reg(5)<=data;
        Result_Reg(6)<=(others =>'0');
      ELSIF Index-Peak_Index=3 THEN 
        Result_Reg(6)<=data;
      END IF;

  END PROCESS;
  ------------------------------------------------------------------------
  maxIndex_register:PROCESS(Peak_Index)
  -- When Peak_Index is renewed, transfer from the integer type to the BCD array type
  BEGIN
    maxIndex_reg(2) <= std_logic_vector( to_unsigned(Peak_Index/100 mod 10,maxIndex_reg(0)'length));
    maxIndex_reg(1) <= std_logic_vector( to_unsigned(Peak_Index/10 mod 10,maxIndex_reg(1)'length));
    maxIndex_reg(0) <= std_logic_vector( to_unsigned(Peak_Index mod 10,maxIndex_reg(2)'length));
  END PROCESS;
END ARCHITECTURE;




