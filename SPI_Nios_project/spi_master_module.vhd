-- *******************************************************************
-- SPI (Serial Peripheral Interface) master module
-- Description: This project implements an SPI master module.
--					 The SPI master module has configurable clock polarity and phase according to the standard.
--					 It also allows setting a delay between the SPI-CS and the first SPI-CLK pulse.
--					 Moreover, the SPI communication is triggered by an external "start operation."
-- Author: [Francesco Simonetti]
-- Date: [13/12/2024]
-- *******************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_master_module is
generic(
			CLK_DIV : integer:=3; -- clk prescaler, the clk frequency will be divided by 2*CLK_DIV
			cpol :  std_logic:='0'; -- SPI-CLK polarity
			cpha : std_logic:='0'; -- SPI-CLK phase
			WORD : integer:=32 -- length of the data to transmit
);
port (clk : in std_logic; -- module clock
		reset : in std_logic; -- module reset, active HIGH

		start: in std_logic; -- module start operation, active on the transition LOW->HIGH
		data_tx_in : in std_logic_vector(WORD-1 downto 0); -- data to transmit
		data_rx_out : out std_logic_vector(WORD-1 downto 0); -- received data
		DELAY_CONSTANT : in integer:=12; -- delay between SPI-CS and first SPI-CLK pulse (moved in the inputs so we can change it via SW with Nios II)

		spi_miso_in: in std_logic; -- master input slave output
		spi_mosi_out: out std_logic; -- master output slave input
		spi_cs_out: out std_logic; -- chip select
		spi_clk_out: out  std_logic; -- SPI clock
 
		end_signal: out std_logic -- end operation 
	);
end spi_master_module;

-- Architecture for the SPI master module
architecture arch1 of spi_master_module is

 -- Internal signal declarations
type state_type is (idle, init_tx_state, communication_state, store_rx_state, end_state);
signal state_reg, state_next : state_type; -- state of the ASM

signal tx_buffer_reg, tx_buffer_next : std_logic_vector(WORD-1 downto 0); -- tx register and tx update signal
signal rx_buffer_reg, rx_buffer_next : std_logic_vector(WORD-1 downto 0); -- rx register and tx update signal

signal delay_counter_reg, delay_counter_next : integer; -- delay counter register and delay counter update signal 
signal div_counter_reg, div_counter_next : integer; -- divider counter register and divider counter update signal 
signal bits_counter_reg, bits_counter_next : integer; -- bits counter register and bits counter update signal 

signal SHIFT : integer; -- shift according to chpol

signal spi_cs_reg, spi_cs_next : std_logic; -- CS buffer register and CS buffer update signal 
signal spi_clk_reg, spi_clk_next : std_logic; -- SPI-CLK buffer register and SPI-CLK buffer update signal 

signal load_tx_buffer : std_logic; -- load tx register signal
signal start_delay : std_logic; -- start delay counter signal
signal start_sclk : std_logic; -- toggle SPI-CLK signal
signal en_tx : std_logic; -- enable SPI register shift signal
signal en_div_counter : std_logic; -- enable counter divider signal

signal div_clk_pulse : std_logic; -- clock pulse from clock divider circuit
signal delay_counter_end : std_logic; -- end delay counter
signal delay_counter_shift_end : std_logic; -- end delay counter for chpol='1'

signal div_counter_2_reg, div_counter_2_next : integer; -- clk divider 2 register and clk divider 2 update signal
signal div_clk_2_pulse : std_logic; -- clock pulse from clock divider 2 circuit
signal en_div_counter_shift : std_logic; -- enable counter divider 2 signal

signal rx_data_reg, rx_data_next : std_logic_vector(WORD-1 downto 0); -- received data to output register and tx update signal
			
begin

-- Mux to select shift according to chpol
SHIFT<= -CLK_DIV when cpha ='0' else 
		  0; 
	
-- Process to update registers: if reset='1', write default value, otherwise update the register values (x_reg) with their update signals (x_next)
reg_process: process(clk,reset)
begin
	if reset='1' then	
		state_reg<=idle;
		tx_buffer_reg<=(others=>'0');
		rx_buffer_reg<=(others=>'0');
		delay_counter_reg<=0;
		div_counter_reg<=0;
		spi_cs_reg<='0';
		spi_clk_reg<=cpol;
		bits_counter_reg<=0;
		div_counter_2_reg<=0;
		rx_data_reg<=(others=>'0');
	elsif clk'event and clk='1' then
		state_reg<=state_next;
		tx_buffer_reg<=tx_buffer_next;
		rx_buffer_reg<=rx_buffer_next;
		delay_counter_reg<=delay_counter_next;
		div_counter_reg<=div_counter_next;
		spi_cs_reg<=spi_cs_next;
		spi_clk_reg<=spi_clk_next;
		bits_counter_reg<=bits_counter_next;
		div_counter_2_reg<=div_counter_2_next;
		rx_data_reg<=rx_data_next;
	end if;
end process;

-- Processs describing the ASM 
next_logic_process: process(start, state_reg, bits_counter_reg, spi_cs_reg, rx_buffer_reg, rx_data_reg)
begin
	-- Default value of the ASM output signals
	end_signal<='0';
	load_tx_buffer<='0';
	spi_cs_next<='0';
	start_delay<='0';
	rx_data_next<=rx_data_reg;

	-- State evolution of the ASM
	case state_reg is
		when idle => -- Wait for the start to move on
			if start='1' then
				state_next<=init_tx_state;
			else
				state_next<=idle;
			end if;
			
		when init_tx_state => -- Load the tx register and move on
			load_tx_buffer<='1';
			state_next<=communication_state;
		
		when communication_state => -- Assert SPI-CS and start delay signal
			spi_cs_next<='1';
			start_delay<='1';
		
			if bits_counter_reg<WORD*2 then	-- Stay in this state until transmission is ended, then move on	
				state_next<=communication_state;
			else
				state_next<=store_rx_state;
			end if;
			
		when store_rx_state => -- Store value inside rx register (received via SPI) to rx data register (visible from the outside), then move on
			rx_data_next<=rx_buffer_reg;
			state_next<=end_state;
			
		when end_state =>	-- Wait for start signal to be back 1
			end_signal<='1';
			if start='1' then
				state_next<=end_state;
			else
				state_next<=idle;
			end if;
	end case;
end process;

-- Clk divider pulse generator. It generates two clock pulses at f_s = f_clk/CLK_DIV and f_s/2 (f_clk is the frequency of the system clock)
en_div_counter<=delay_counter_end; -- connect end signal of DELAY_CONSTANT counter to enable signal of CLK_DIV-1 counter
en_div_counter_shift<=delay_counter_shift_end; -- connect end signal of DELAY_CONSTANT+SHIFT counter to enable signal of CLK_DIV*2-1 counter
process(div_counter_reg, en_div_counter, div_counter_2_reg, en_div_counter_shift)
begin
	-- Default value of the muxs
	div_counter_next<=0;
	div_clk_pulse<='0';
	div_counter_2_next<=0;
	div_clk_2_pulse<='0';

	-- Muxs selection: 
	-- As long as en_div_counter is '1', div_counter counts up tp CLK_DIV-1, then go back 0. When it reaches 0, div_clk_pulse is set to '0'
	-- Generate a pulse at f_s = f_clk / CLK_DIV
	if en_div_counter='1' then
		div_counter_next<=div_counter_reg+1;
		if div_counter_reg=CLK_DIV-1 then
			div_counter_next<=0;
		end if;
	
		if div_counter_reg=0 then	
			div_clk_pulse<='1';
		end if;
	end if;
	-- Muxs selection: 
	-- As long as en_div_counter_shift is '1', div_counter_2 counts up tp CLK_DIV*2-1, then go back 0. When it reaches 0, div_clk_2_pulse is set to '0'
	-- Generate a pulse at f_s = f_clk / CLK_DIV / 2
	if en_div_counter_shift='1' then
		div_counter_2_next<=div_counter_2_reg+1;
		if div_counter_2_reg=CLK_DIV*2-1 then
			div_counter_2_next<=0;
		end if;
		if div_counter_2_reg=0 then
			div_clk_2_pulse<='1';
		end if;
	end if;	
end process;

-- Delay counter 
process(start_delay, delay_counter_reg, SHIFT, DELAY_CONSTANT)
begin
	-- Default value of the muxs
	delay_counter_next<=0;
	delay_counter_end<='0';
	delay_counter_shift_end<='0';
	
	-- Mux selection: delay_counter increases as long as start_delay='1' (driven by the ASM)
	if start_delay='1' then
		delay_counter_next<=delay_counter_reg+1;			
	end if;
	
	-- Mux selection: delay_counter_end asserted when delay_counter reaches DELAY_CONSTANT value (delay designed by the upper level module)
	if delay_counter_reg>DELAY_CONSTANT then -- to tx & rx
		delay_counter_end<='1';
	end if;
	
	-- Mux selection: delay_counter_shift_end asserted when delay_counter reaches DELAY_CONSTANT+SHIFT value (considers chpol setting)
	if delay_counter_reg>DELAY_CONSTANT+SHIFT then -- to spi_clk
		delay_counter_shift_end<='1';
	end if;
end process;


-- SPI-CLK toggle process & bit counter process to count the number of bits already transmitted (used to notify the end of the transmission to ASM)
start_sclk<=delay_counter_shift_end and div_clk_pulse; -- toggle at every pulses at f_s as soon as the delay+shift is expired
process(start_sclk, spi_clk_reg, bits_counter_reg, start_delay)
begin
	-- Default value of the muxs
	spi_clk_next<=spi_clk_reg;
	bits_counter_next<=0;
	
	-- Muxs selection: 
	-- As long as start_delay = '1' (driven by ASM), it bits_counter increases at every SPI-CLK cycle, i.e., every bit transmission
	-- As long as start_delay = '1' SPI-CLK is toggled, the SPI-CLK frequency is equal to f_s/2
	if start_delay='1' then
		bits_counter_next<=bits_counter_reg;
		if start_sclk='1' then
			spi_clk_next<= not spi_clk_reg;
			bits_counter_next<=bits_counter_reg+1;
		end if;
	end if;
end process;

-- TX & RX registers process
en_tx<=delay_counter_end and div_clk_2_pulse; -- enable TX and RX shift at f_s/2 as soon as the designed delay is expired
process(en_tx, tx_buffer_reg,  rx_buffer_reg, load_tx_buffer, data_tx_in,  spi_miso_in)
begin
	-- Default value of the muxs
	rx_buffer_next<=rx_buffer_reg;
	tx_buffer_next<=tx_buffer_reg;

	-- Muxs selection: 
	-- If load_tx signal is '1' (driven by ASM), load the input data to transmit at next SPI communication
	-- Otherwise, shift the SPI register according to en_tx
	-- TX register contains the input data and tranmits it via MOSI
	-- RX register is used to store the incoming bits via MISO
	if load_tx_buffer='1' then
		tx_buffer_next<=data_tx_in;
	elsif en_tx='1' then
			tx_buffer_next<=tx_buffer_reg(tx_buffer_reg'high-1 downto 0) & '0'; --I erase the buffer at the end
			rx_buffer_next<=rx_buffer_reg(rx_buffer_reg'high-1 downto 0) & spi_miso_in; -- I use two buffer register (tx and rx), even if the standard is usign the same register for tx and rx
	end if;		
end process;

spi_mosi_out<=tx_buffer_reg(tx_buffer_reg'high); -- MOSI equal to the MSB of the TX register

data_rx_out<=rx_data_next; -- RX data is available at the output of the SPI master module

spi_cs_out<=spi_cs_reg; -- CS output signal connected to CS buffer
spi_clk_out<=spi_clk_reg; -- SPI-CLK output signal connected to the SPI-CLK buffer

end arch1;