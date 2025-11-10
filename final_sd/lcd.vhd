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
use IEEE.NUMERIC_STD.ALL;

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
			    
------------------------------------------------------------------
--  Component Declarations
------------------------------------------------------------------
component kb_code is
    port (
	clk, reset: in std_logic;
	ps2d, psdc: in std_logic;
	rd_key_code: in std_logic;
	key_code: out std_logic_vector(7 downto 0);
	key_buf_empty: out std_logic);
end component kb_code;

component key2hex is
	port (
	kb_entry: in std_logic_vector(7 downto 0);
	wkey: out std_logic_vector(9 downto 0));
end component key2hex;
------------------------------------------------------------------
--  Local Type Declarations
-----------------------------------------------------------------
--  Symbolic names for all possible states of the state machines.

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
	

------------------------------------------------------------------
--  Signal Declarations and Constants
------------------------------------------------------------------
	--These constants are used to initialize the LCD pannel.

	--FunctionSet:
		--Bit 0 and 1 are arbitrary
		--Bit 2:  Displays font type(0=5x8, 1=5x11)
		--Bit 3:  Numbers of display lines (0=1, 1=2)
		--Bit 4:  Data length (0=4 bit, 1=8 bit)
		--Bit 5-7 are set
	--DisplayCtrlSet:
		--Bit 0:  Blinking cursor control (0=off, 1=on)
		--Bit 1:  Cursor (0=off, 1=on)
		--Bit 2:  Display (0=off, 1=on)
		--Bit 3-7 are set
	--DisplayClear:
		--Bit 1-7 are set	
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

	signal rd_key_code: std_logic;
    signal ps2d: std_logic;
    signal psdc: std_logic;
	signal key_read: std_logic_vector(7 downto 0); -- Reading letter
	signal kb_entry: std_logic_vector(7 downto 0); -- Saving letter read
	signal wkey: std_logic_vector(9 downto 0);
	signal kb_empty: std_logic;
	signal life: integer := 5; -- how many tries the player have
	signal gamemode: integer := 0; -- setting the state of the game

	--setting the key word
	signal data_w5: integer := 0;
	signal data_w4: integer := 0;
	signal data_w3: integer := 0;
	signal data_w2: integer := 0;
	signal data_w1: integer := 0;
	signal data_w0: integer := 0;
	signal is_there: std_logic := '0'; -- signal to see if the letter is in the word

	--setting the error space
	signal error_w5: integer := 0;
	signal error_w4: integer := 0;
	signal error_w3: integer := 0;
	signal error_w2: integer := 0;
	signal error_w1: integer := 0;
	signal error_w0: integer := 0;

	--attempts and errors config
	signal atmp_vector: std_logic_vector(5 downto 0) := "000000";
	signal error_vector: std_logic_vector(5 downto 0) := "000000";

	type LCD_CMDS_T is array(integer range 36 downto 0) of std_logic_vector(9 downto 0);
	signal LCD_CMDS : LCD_CMDS_T := ( 0 => "00"&X"3C",			--Function Set
					    1 => "00"&X"0C",			--Display ON, Cursor OFF, Blink OFF
					    2 => "00"&X"01",			--Clear Display
					    3 => "00"&X"02", 			--return home

					    4 =>  "00"&X"4A", 			--I
					    5 =>  "00"&X"6E",  			--n
					    6 =>  "00"&X"73",  			--s
					    7 =>  "00"&X"69", 			--i
					    8 =>  "00"&X"72", 			--r
					    9 =>  "00"&X"61",  			--a
					    10 => "00"&X"20", 			--space
					    11 => "00"&X"61", 			--a
					    12 => "00"&X"20", 			--space
					    13 => "00"&X"50", 			--P
					    14 => "00"&X"61",			--a
					    15 => "00"&X"6C", 			--l
					    16 => "00"&X"61", 			--a
					    17 => "00"&X"76", 			--v
					    18 => "00"&X"72", 			--r
					    19 => "00"&X"61", 			--a
					    20 => "10"&X"C0",			--enter

					    21 =>  "00"&X"20", 			--entry
					    22 =>  "00"&X"20",			--entry
					    23 =>  "00"&X"20",			--entry
					    24 =>  "00"&X"20",			--entry
					    25 =>  "00"&X"20",			--entry
					    26 =>  "00"&X"20",			--entry
					    27 =>  "00"&X"20",			--entry
					    28 =>  "00"&X"20",			--entry
					    29 =>  "00"&X"20",			--space
					    30 =>  "00"&X"20",			--space
					    31 =>  "00"&X"20",			--space
					    32 =>  "00"&X"20",			--space
					    33 =>  "00"&X"20",			--space
					    34 =>  "00"&X"20",			--space
					    35 =>  "00"&X"20",			--space
					    36 =>  "00"&X"20");			--space

													
	signal lcd_cmd_ptr : integer range 0 to LCD_CMDS'HIGH + 1 := 0;

begin

	-- opening kb_code
	kbc: kb_code port map (CLK, rst, ps2d, psdc, rd_key_code, key_read, kb_empty);
	-- opening key2hex
	k2h: key2hex port map (kb_entry, wkey);


	process(clk)

    -- key word variables
	variable word5: std_logic_vector(9 downto 0) := "00"&X"20";
	variable word4: std_logic_vector(9 downto 0) := "00"&X"20";
	variable word3: std_logic_vector(9 downto 0) := "00"&X"20";
	variable word2: std_logic_vector(9 downto 0) := "00"&X"20";
	variable word1: std_logic_vector(9 downto 0) := "00"&X"20";
	variable word0: std_logic_vector(9 downto 0) := "00"&X"20";

	-- attempts
	variable atmp5: std_logic_vector(9 downto 0) := "00"&X"5F";
	variable atmp4: std_logic_vector(9 downto 0) := "00"&X"5F";
	variable atmp3: std_logic_vector(9 downto 0) := "00"&X"5F";
	variable atmp2: std_logic_vector(9 downto 0) := "00"&X"5F";
	variable atmp1: std_logic_vector(9 downto 0) := "00"&X"5F";
	variable atmp0: std_logic_vector(9 downto 0) := "00"&X"5F";

	-- errors
	variable error5: std_logic_vector(9 downto 0) := "00"&X"20";
	variable error4: std_logic_vector(9 downto 0) := "00"&X"20";
	variable error3: std_logic_vector(9 downto 0) := "00"&X"20";
	variable error2: std_logic_vector(9 downto 0) := "00"&X"20";
	variable error1: std_logic_vector(9 downto 0) := "00"&X"20";
	variable error0: std_logic_vector(9 downto 0) := "00"&X"20";

		begin
			if (clk'event and clk = '1') then 
				if (kb_empty = '1') then rd_key_code <= '0';
				elsif (kb_empty = '0') then kb_entry <= key_read;
					if (gamemode = 0) then -- setting the key word
					-- fazer tradução do wkey para 10 bits
						if (data_w5 = 0) then data_w5 <= 1; word5 := wkey;
						elsif (data_w4 = 0) then data_w4 <= 1; word4 := wkey;
						elsif (data_w3 = 0) then data_w3 <= 1; word3 := wkey;
						elsif (data_w2 = 0) then data_w2 <= 1; word2 := wkey;
						elsif (data_w1 = 0) then data_w1 <= 1; word1 := wkey;
						elsif (data_w0 = 0) then data_w0 <= 1; word0 := wkey;
						elsif (wkey = "10"&X"C0") then gamemode <= 1; -- set the start of the game
						end if;
					elsif (gamemode = 1) then
						--Jogo da Forca
                        if (wkey = data_w5) then atmp5 := wkey; is_there <= '1'; data_w5 <= 1; end if;
						if (wkey = data_w4) then atmp4 := wkey; is_there <= '1'; data_w4 <= 1; end if;
						if (wkey = data_w3) then atmp3 := wkey; is_there <= '1'; data_w3 <= 1; end if;
						if (wkey = data_w2) then atmp2 := wkey; is_there <= '1'; data_w2 <= 1; end if;
						if (wkey = data_w1) then atmp1 := wkey; is_there <= '1'; data_w1 <= 1; end if;
						if (wkey = data_w0) then atmp0 := wkey; is_there <= '1'; data_w0 <= 1; end if;
						if (is_there = '0') then
							life <= life - 1;
							if (error_w5 = 0) then error5 := wkey; error_w5 <= 1;
							elsif (error_w4 = 0) then error4 := wkey; error_w4 <= 1;
							elsif (error_w3 = 0) then error3 := wkey; error_w3 <= 1;
							elsif (error_w2 = 0) then error2 := wkey; error_w2 <= 1;
							elsif (error_w1 = 0) then error1 := wkey; error_w1 <= 1;
							elsif (error_w0 = 0) then error0 := wkey; error_w0 <= 1;
							end if;
						end if;
							-- checking the end of the game
						if (life = 0) then gamemode <= 2; -- enging game
						elsif (atmp5 = word5 and atmp4 = word4 and atmp3 = word3 and atmp2 = word2 and atmp1 = word1 and atmp0 = word0) then
							gamemode <= 2;
						end if;
                    elsif (gamemode = 2) then
                        -- restarting the game
                        gamemode <= 0;
					end if;
				end if;
			end if;
			is_there <= '0';
		
            case gamemode is 
                when 0 =>
                    LCD_CMDS(21) <= word5;
                    LCD_CMDS(22) <= word4;
                    LCD_CMDS(23) <= word3;
                    LCD_CMDS(24) <= word2;
                    LCD_CMDS(25) <= word1;
                    LCD_CMDS(26) <= word0;
                when 1 => 
                    LCD_CMDS(4) <= atmp5;
                    LCD_CMDS(5) <= atmp4;
                    LCD_CMDS(6) <= atmp3;
                    LCD_CMDS(7) <= atmp2;
                    LCD_CMDS(8) <= atmp1;
                    LCD_CMDS(9) <= atmp0;
                    LCD_CMDS(21) <= error5;
                    LCD_CMDS(22) <= error4;
                    LCD_CMDS(23) <= error3;
                    LCD_CMDS(24) <= error2;
                    LCD_CMDS(25) <= error1;
                    LCD_CMDS(26) <= error0;
                    case life is
                        when 0 => LCD_CMDS(36) <= "00"&X"30";
                        when 1 => LCD_CMDS(36) <= "00"&X"31";
                        when 2 => LCD_CMDS(36) <= "00"&X"32";
                        when 3 => LCD_CMDS(36) <= "00"&X"33";
                        when 4 => LCD_CMDS(36) <= "00"&X"34";
                        when 5 => LCD_CMDS(36) <= "00"&X"35";
                        when others => LCD_CMDS(36) <= "00"&X"23";
                    end case;
                when 2 =>
                    if (life = 0) then
                        LCD_CMDS(4) <= "00"&X"56"; 			--V
                        LCD_CMDS(5) <= "00"&X"6F";  		--o
                        LCD_CMDS(6) <= "00"&X"63";  		--c
                        LCD_CMDS(7) <= "00"&X"65"; 			--e
                        LCD_CMDS(8) <= "00"&X"20"; 			--space
                        LCD_CMDS(9) <= "00"&X"47";  		--G
                        LCD_CMDS(10) <= "00"&X"61"; 		--a
                        LCD_CMDS(11) <= "00"&X"6E"; 		--n
                        LCD_CMDS(12) <= "00"&X"68";			--h
                        LCD_CMDS(13) <= "00"&X"6F"; 		--o
                        LCD_CMDS(14) <= "00"&X"75";			--u
                    else -- you win
                        LCD_CMDS(4) <= "00"&X"56"; 			--V
                        LCD_CMDS(5) <= "00"&X"6F";  		--o
                        LCD_CMDS(6) <= "00"&X"63";  		--c
                        LCD_CMDS(7) <= "00"&X"65"; 			--e
                        LCD_CMDS(8) <= "00"&X"20"; 			--space
                        LCD_CMDS(9) <= "00"&X"50";  		--P
                        LCD_CMDS(10) <= "00"&X"65"; 		--e
                        LCD_CMDS(11) <= "00"&X"72"; 		--r
                        LCD_CMDS(12) <= "00"&X"64";			--d
                        LCD_CMDS(13) <= "00"&X"65"; 		--e
                        LCD_CMDS(14) <= "00"&X"75";			--u
                    end if;
                when others => 
                    
                end case;
          end process;

 	
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