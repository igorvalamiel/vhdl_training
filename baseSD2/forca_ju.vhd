------------------------------------------------------------------
--  lcd.vhd -- general LCD testing program
------------------------------------------------------------------
--  Author -- Dan Pederson, 2004
--			  -- Barron Barnett, 2004
--			  -- Jacob Beck, 2006
------------------------------------------------------------------
--  This module is a test module for implementing read/write and
--  initialization routines for an LCD on the Digilab boards
------------------------------------------------------------------
--  Revision History:								    
--  05/27/2004(DanP):  created
--  07/01/2004(BarronB): (optimized) and added writeDone as output
--  08/12/2004(BarronB): fixed timing issue on the D2SB
--  12/07/2006(JacobB): Revised code to be implemented on a Nexys Board
--				Changed "Hello from Digilent" to be on one line"
--				Added a Shift Left command so that the message
--				"Hello from Diligent" is shifted left by 1 repeatedly
--				Changed the delay of character writes
------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity lcd is
    Port ( LCD_DB: out std_logic_vector(7 downto 0);		--DB( 7 through 0)
           RS:out std_logic;  				--WE
           RW:out std_logic;				--ADR(0)
	   CLK:in std_logic;				--GCLK2
	   --ADR1:out std_logic;				--ADR(1)
	   --ADR2:out std_logic;				--ADR(2)
	   --CS:out std_logic;				--CSC
	   OE:out std_logic;				--OE
	   rst:in std_logic		);		--BTN
	   --rdone: out std_logic);			--WriteDone output to work with DI05 test
end lcd;

architecture Behavioral of lcd is

--  Component Declarations

component kb_code port (
    clk, reset: in std_logic;
    ps2d, ps2c: in std_logic;
    rd_key_code: in std_logic;
    key_code: out std_logic_vector(7 downto 0);
    kb_buf_empty: out std_logic
     );
end component kb_code;		    


--LCD control state machine
	type mstate is (					  
		stFunctionSet,		 			--Initialization states
		stDisplayCtrlSet,
		stDisplayClear,
		stPowerOn_Delay,  				--Delay states
		stFunctionSet_Delay,
		stDisplayCtrlSet_Delay, 	
		stDisplayClear_Delay,
		stInitDne,					--Display charachters and perform standard operations
		stActWr,
		stCharDelay					--Write delay for operations
		--stWait					--Idle state
	);

	--Write control state machine
	type wstate is (
		stRW,						--set up RS and RW
		stEnable,					--set up E
		stIdle						--Write data on DB(0)-DB(7)
	);
	

-- Signal Declarations and Constants

	signal rd_key_code: std_logic;
    	signal ps2d: std_logic;
    	signal psdc: std_logic;
	signal key_read: std_logic_vector(7 downto 0); -- Reading letter
	signal kb_entry: std_logic_vector(7 downto 0); -- Saving letter read
	signal kb_empty: std_logic;

	signal clkCount:std_logic_vector(5 downto 0);
	signal activateW:std_logic:= '0';		    			--Activate Write sequence
	signal count:std_logic_vector (16 downto 0):= "00000000000000000";	--15 bit count variable for timing delays
	signal delayOK:std_logic:= '0';						--High when count has reached the right delay time
	signal OneUSClk:std_logic;						--Signal is treated as a 1 MHz clock	
	signal stCur:mstate:= stPowerOn_Delay;					--LCD control state machine
	signal stNext:mstate;			  	
	signal stCurW:wstate:= stIdle; 						--Write control state machine
	signal stNextW:wstate;
	signal writeDone:std_logic:= '0';					--Command set finish
	signal counter: std_logic_vector (3 downto 0) := "1001";
	
	signal gabarito : std_logic_vector (4 downto 0) := "00000";
	signal letra_salva : std_logic_vector (7 downto 0);


    type LCD_CMDS_T is array(integer range 35 downto 0) of std_logic_vector(9 downto 0);
	signal LCD_CMDS : LCD_CMDS_T := ( 0 => "00"&X"3C",			--Function Set

-- PARTE DE CIMA DO DISPLAY
     
        1 => "00"&X"0C", --Display ON, Cursor OFF, Blink OFF
        2 => "00"&X"01", --Clear Display
        3 => "00"&X"02", --return home
        
        4 => "10"&X"20", --SPACE
        5 => "10"&X"20", --SPACE
        6 => "10"&X"46", --F 
        7 => "10"&X"6F", --o 
        8 => "10"&X"72", --r 
        9 => "10"&X"63", --c 
        10 => "10"&X"61", --a 
        11 => "10"&X"20", --SPACE
        12 => "10"&X"20", --SPACE
        13 => "10"&X"7C", -- |
        14 => "10"&X"54", -- T
        15 => "10"&X"72", -- r
        16 => "10"&X"79", -- y
        17 => "10"&X"3A", -- :
        18 => "10"&X"39", -- 9

-- PARTE DE BAIXO DO DISPLAY       
        19 => "00"&X"C0", --Select second line
        20 => "10"&X"20", --SPACE
        21 => "10"&X"20", --SPACE
        22 => "10"&X"5F", -- _
        23 => "10"&X"5F", -- _
        24 => "10"&X"5F", -- _
        25 => "10"&X"5F", -- _
        26 => "10"&X"5F", -- _
        27 => "10"&X"20", --SPACE
        28 => "10"&X"20", --SPACE
        29 => "10"&X"7C", -- |
        30 => "10"&X"20", -- GANHOU OU PERDEU
        31 => "10"&X"20", -- GANHOU OU PERDEU
        32 => "10"&X"20", -- GANHOU OU PERDEU
        33 => "10"&X"20", -- GANHOU OU PERDEU
        34 => "10"&X"20", -- GANHOU OU PERDEU
        35 => "10"&X"20" -- GANHOU OU PERDEU

 );
					
	signal lcd_cmd_ptr : integer range 0 to LCD_CMDS'HIGH + 1 := 0;


begin

	kbc: kb_code port map (CLK, rst, ps2d, psdc, rd_key_code, key_read, kb_empty);

process (clk)
	begin
	if (clk = '1' and kb_empty = '1') then rd_key_code <= '0';
	elsif (clk = '1' and kb_empty = '0') then rd_key_code <= '1'; letra_salva <= key_read; -- troquei key_code por key_read
	end if;
	if (letra_salva /= "01010000" and letra_salva /= "01001111" and letra_salva /= "01010010" and letra_salva /= "01010100" and letra_salva /= "01000001") then 		count <= count - 1;
	else
		counter <= counter;
	end if;

-----------------------------------------------
-- FIM DE JOGO    
-----------------------------------------------  

if (count /= "0000" and gabarito = "1111") then

LCD_CMDS(4) <= "10"&X"41"; -- A 
LCD_CMDS(5) <= "10"&X"20"; --SPACE 
LCD_CMDS(6) <= "10"&X"70"; ---- P, 
LCD_CMDS(7) <= "10"&X"41"; -- A,
LCD_CMDS(8) <= "10"&X"6C"; -- L,
LCD_CMDS(9) <= "10"&X"41"; -- A,
LCD_CMDS(10) <= "10"&X"76"; -- V
LCD_CMDS(11) <= "10"&X"72"; -- R,
LCD_CMDS(12) <= "10"&X"41"; -- A
LCD_CMDS(13) <= "10"&X"20"; --SPACE 
LCD_CMDS(14) <= "10"&X"65"; --E 
LCD_CMDS(15) <= "10"&X"72"; -- R;
LCD_CMDS(16) <= "10"&X"41"; -- A 
LCD_CMDS(17) <= "10"&X"20"; --SPACE 
LCD_CMDS(18) <= "10"&X"20"; --SPACE 

LCD_CMDS(19) <= "00"&X"C0";
LCD_CMDS(20)<= "10"&X"20"; --SPACE
LCD_CMDS(21)<= "10"&X"20"; --SPACE
LCD_CMDS(22)<= "10"&X"50"; -- P
LCD_CMDS(23)<= "10"&X"4F"; -- O
LCD_CMDS(24) <= "10"&X"52"; -- R
LCD_CMDS(25) <= "10"&X"54"; -- T
LCD_CMDS(26) <= "10"&X"41"; -- A
LCD_CMDS(27) <= "10"&X"20"; --SPACE
LCD_CMDS(28) <= "10"&X"20"; --SPACE
LCD_CMDS(29) <= "10"&X"7C"; -- |
LCD_CMDS(30) <= "10"&X"47"; -- G
LCD_CMDS(31) <= "10"&X"41"; -- A
LCD_CMDS(32) <= "10"&X"4E"; -- N
LCD_CMDS(33) <= "10"&X"48"; -- H
LCD_CMDS(34) <= "10"&X"4F"; -- O
LCD_CMDS(35) <= "10"&X"55"; -- U

else
	
LCD_CMDS(4) <= "10"&X"41"; -- A 
LCD_CMDS(5) <= "10"&X"20"; --SPACE 
LCD_CMDS(6) <= "10"&X"70"; ---- P 
LCD_CMDS(7) <= "10"&X"41"; -- A;
LCD_CMDS(8) <= "10"&X"6C"; -- L
LCD_CMDS(9) <= "10"&X"41"; -- A;
LCD_CMDS(10) <= "10"&X"76"; -- V;
LCD_CMDS(11) <= "10"&X"72"; -- R;
LCD_CMDS(12) <= "10"&X"41"; -- A;
LCD_CMDS(13) <= "10"&X"20"; --SPACE 
LCD_CMDS(14) <= "10"&X"65"; --E 
LCD_CMDS(15) <= "10"&X"72"; -- R;
LCD_CMDS(16) <= "10"&X"41"; -- A 
LCD_CMDS(17) <= "10"&X"20"; --SPACE 
LCD_CMDS(18) <= "10"&X"20"; --SPACE 

LCD_CMDS(19) <= "00"&X"C0";
LCD_CMDS(20)<= "10"&X"20"; --SPACE
LCD_CMDS(21)<= "10"&X"20"; --SPACE
LCD_CMDS(22)<= "10"&X"50"; -- P
LCD_CMDS(23)<= "10"&X"4F"; -- O
LCD_CMDS(24) <= "10"&X"52"; -- R
LCD_CMDS(25) <= "10"&X"54"; -- T
LCD_CMDS(26) <= "10"&X"41"; -- A
LCD_CMDS(27) <= "10"&X"20"; --SPACE
LCD_CMDS(28) <= "10"&X"20"; --SPACE
LCD_CMDS(29) <= "10"&X"7C"; -- |
LCD_CMDS(30) <= "10"&X"50"; -- P
LCD_CMDS(31) <= "10"&X"45"; --E
LCD_CMDS(32) <= "10"&X"52"; -- R
LCD_CMDS(33) <= "10"&X"44"; -- D
LCD_CMDS(34) <= "10"&X"45"; --E
LCD_CMDS(35) <= "10"&X"55"; -- U

end if;
end process;

------------------------------------------
-- DUVIDA EM COMO CONSIDERAR O RESET
------------------------------------------

gabarito(0) <= '1' when letra_salva = "01010000" and counter > "0000";   -- P
gabarito(1) <= '1' when letra_salva = "01001111" and counter > "0000"; -- O
gabarito(2) <= '1' when letra_salva = "01010010" and counter > "0000"; -- R
gabarito(3) <= '1' when letra_salva = "01010100" and counter > "0000"; -- T
gabarito(4) <= '1' when letra_salva = "01000001" and counter > "0000"; -- A

LCD_CMDS(22) <= "10"&X"50" when (gabarito(0) = '1') else "10"&X"5F";
LCD_CMDS(23) <= "10"&X"4F" when (gabarito(1) = '1') else "10"&X"5F";
LCD_CMDS(24) <= "10"&X"52" when (gabarito(2) = '1') else "10"&X"5F";
LCD_CMDS(25) <= "10"&X"54" when (gabarito(3) = '1') else "10"&X"5F";
LCD_CMDS(26) <= "10"&X"41" when (gabarito(4) = '1') else "10"&X"5F";

-----------------------------------------------
-- CONTAGEM DE TENTATIVAS
-----------------------------------------------
  
LCD_CMDS(18) <= "10"&X"31" when (counter = "0001");    
LCD_CMDS(18) <= "10"&X"32" when (counter = "0010");    
LCD_CMDS(18) <= "10"&X"33" when (counter = "0011");    
LCD_CMDS(18) <= "10"&X"34" when (counter = "0100");    
LCD_CMDS(18) <= "10"&X"35" when (counter = "0101");    
LCD_CMDS(18) <= "10"&X"36" when (counter = "0110");    
LCD_CMDS(18) <= "10"&X"37" when (counter = "0111");    
LCD_CMDS(18) <= "10"&X"38" when (counter = "1000");
LCD_CMDS(18) <= "10"&X"39" when (counter = "1001");



    --  This process counts to 50, and then resets.  It is used to divide the clock signal time.
	process (CLK, oneUSClk)
    		begin
			if (CLK = '1' and CLK'event) then
				clkCount <= clkCount + 1;
			end if;
		end process;
	--  This makes oneUSClock peak once every 1 microsecond

	oneUSClk <= clkCount(5);
	--  This process incriments the count variable unless delayOK = 1.
	process (oneUSClk, delayOK)
		begin
			if (oneUSClk = '1' and oneUSClk'event) then
				if delayOK = '1' then
					count <= "00000000000000000";
				else
					count <= count + 1;
				end if;
			end if;
		end process;

	--This goes high when all commands have been run
	writeDone <= '1' when (lcd_cmd_ptr = LCD_CMDS'HIGH) 
		else '0';
	--rdone <= '1' when stCur = stWait else '0';
	--Increments the pointer so the statemachine goes through the commands
	process (lcd_cmd_ptr, oneUSClk)
   		begin
			if (oneUSClk = '1' and oneUSClk'event) then
				if ((stNext = stInitDne or stNext = stDisplayCtrlSet or stNext = stDisplayClear) and writeDone = '0') then 
					lcd_cmd_ptr <= lcd_cmd_ptr + 1;
				elsif stCur = stPowerOn_Delay or stNext = stPowerOn_Delay then
					lcd_cmd_ptr <= 0;
				else
					lcd_cmd_ptr <= lcd_cmd_ptr;
				end if;
			end if;
		end process;
	
	--  Determines when count has gotten to the right number, depending on the state.

	delayOK <= '1' when ((stCur = stPowerOn_Delay and count = "00100111001010010") or 			--20050  
					(stCur = stFunctionSet_Delay and count = "00000000000110010") or	--50
					(stCur = stDisplayCtrlSet_Delay and count = "00000000000110010") or	--50
					(stCur = stDisplayClear_Delay and count = "00000011001000000") or	--1600
					(stCur = stCharDelay and count = "11111111111111111"))			--Max Delay for character writes and shifts
					--(stCur = stCharDelay and count = "00000000000100101"))		--37  This is proper delay between writes to ram.
		else	'0';
  	
	-- This process runs the LCD status state machine
	process (oneUSClk, rst)
		begin
			if oneUSClk = '1' and oneUSClk'Event then
				if rst = '1' then
					stCur <= stPowerOn_Delay;
				else
					stCur <= stNext;
				end if;
			end if;
		end process;

	
	--  This process generates the sequence of outputs needed to initialize and write to the LCD screen
	process (stCur, delayOK, writeDone, lcd_cmd_ptr)
		begin   
		
			case stCur is
			
				--  Delays the state machine for 20ms which is needed for proper startup.
				when stPowerOn_Delay =>
					if delayOK = '1' then
						stNext <= stFunctionSet;
					else
						stNext <= stPowerOn_Delay;
					end if;
					RS <= LCD_CMDS(lcd_cmd_ptr)(9);
					RW <= LCD_CMDS(lcd_cmd_ptr)(8);
					LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
					activateW <= '0';

				-- This issuse the function set to the LCD as follows 
				-- 8 bit data length, 2 lines, font is 5x8.
				when stFunctionSet =>
					RS <= LCD_CMDS(lcd_cmd_ptr)(9);
					RW <= LCD_CMDS(lcd_cmd_ptr)(8);
					LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
					activateW <= '1';	
					stNext <= stFunctionSet_Delay;
				
				--Gives the proper delay of 37us between the function set and
				--the display control set.
				when stFunctionSet_Delay =>
					RS <= LCD_CMDS(lcd_cmd_ptr)(9);
					RW <= LCD_CMDS(lcd_cmd_ptr)(8);
					LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
					activateW <= '0';
					if delayOK = '1' then
						stNext <= stDisplayCtrlSet;
					else
						stNext <= stFunctionSet_Delay;
					end if;
				
				--Issuse the display control set as follows
				--Display ON,  Cursor OFF, Blinking Cursor OFF.
				when stDisplayCtrlSet =>
					RS <= LCD_CMDS(lcd_cmd_ptr)(9);
					RW <= LCD_CMDS(lcd_cmd_ptr)(8);
					LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
					activateW <= '1';
					stNext <= stDisplayCtrlSet_Delay;

				--Gives the proper delay of 37us between the display control set
				--and the Display Clear command. 
				when stDisplayCtrlSet_Delay =>
					RS <= LCD_CMDS(lcd_cmd_ptr)(9);
					RW <= LCD_CMDS(lcd_cmd_ptr)(8);
					LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
					activateW <= '0';
					if delayOK = '1' then
						stNext <= stDisplayClear;
					else
						stNext <= stDisplayCtrlSet_Delay;
					end if;
				
				--Issues the display clear command.
				when stDisplayClear	=>
					RS <= LCD_CMDS(lcd_cmd_ptr)(9);
					RW <= LCD_CMDS(lcd_cmd_ptr)(8);
					LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
					activateW <= '1';
					stNext <= stDisplayClear_Delay;

				--Gives the proper delay of 1.52ms between the clear command
				--and the state where you are clear to do normal operations.
				when stDisplayClear_Delay =>
					RS <= LCD_CMDS(lcd_cmd_ptr)(9);
					RW <= LCD_CMDS(lcd_cmd_ptr)(8);
					LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
					activateW <= '0';
					if delayOK = '1' then
						stNext <= stInitDne;
					else
						stNext <= stDisplayClear_Delay;
					end if;
				
				--State for normal operations for displaying characters, changing the
				--Cursor position etc.
				when stInitDne =>		
					RS <= LCD_CMDS(lcd_cmd_ptr)(9);
					RW <= LCD_CMDS(lcd_cmd_ptr)(8);
					LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
					activateW <= '0';
					stNext <= stActWr;

				when stActWr =>		
					RS <= LCD_CMDS(lcd_cmd_ptr)(9);
					RW <= LCD_CMDS(lcd_cmd_ptr)(8);
					LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
					activateW <= '1';
					stNext <= stCharDelay;
					
				--Provides a max delay between instructions.
				when stCharDelay =>
					RS <= LCD_CMDS(lcd_cmd_ptr)(9);
					RW <= LCD_CMDS(lcd_cmd_ptr)(8);
					LCD_DB <= LCD_CMDS(lcd_cmd_ptr)(7 downto 0);
					activateW <= '0';					
					if delayOK = '1' then
						stNext <= stInitDne;
					else
						stNext <= stCharDelay;
					end if;
			end case;
		
		end process;					
								   
 	--This process runs the write state machine
	process (oneUSClk, rst)
		begin
			if oneUSClk = '1' and oneUSClk'Event then
				if rst = '1' then
					stCurW <= stIdle;
				else
					stCurW <= stNextW;
				end if;
			end if;
		end process;

	--This genearates the sequence of outputs needed to write to the LCD screen
	process (stCurW, activateW)
		begin   
		
			case stCurW is
				--This sends the address across the bus telling the DIO5 that we are
				--writing to the LCD, in this configuration the adr_lcd(2) controls the
				--enable pin on the LCD
				when stRw =>
					OE <= '0';
					--CS <= '0';
					--ADR2 <= '1';
					--ADR1 <= '0';
					stNextW <= stEnable;
				
				--This adds another clock onto the wait to make sure data is stable on 
				--the bus before enable goes low.  The lcd has an active falling edge 
				--and will write on the fall of enable
				when stEnable => 
					OE <= '0';
					--CS <= '0';
					--ADR2 <= '0';
					--ADR1 <= '0';
					stNextW <= stIdle;
				
				--Waiting for the write command from the instuction state machine
				when stIdle =>
					--ADR2 <= '0';
					--ADR1 <= '0';
					--CS <= '1';
					OE <= '1';
					if activateW = '1' then
						stNextW <= stRw;
					else
						stNextW <= stIdle;
					end if;
				end case;
		end process;
				
end Behavioral;