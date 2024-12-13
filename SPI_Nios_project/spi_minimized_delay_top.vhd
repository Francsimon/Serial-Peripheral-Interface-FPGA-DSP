-- *******************************************************************
-- SPI (Serial Peripheral Interface) master module controlled via Nios II
-- Description: This project implements the Nios II soft-processor to control 6 SPI master modules.
--					 The SPI master modules have configurable clock polarity and phase according to the standard.
--					 They also allow setting a delay between the SPI-CS and the first SPI-CLK pulse.
--					 Moreover, the SPI communication is triggered by an external "start operation" controllable via Nios II.
--					 Nios II can write the data to send from the specific SPI master module, start the communication and read the received data.
-- Author: [Francesco Simonetti]
-- Date: [13/12/2024]
-- *******************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Entity declaration for the SPI master modules controlled via Nios II
entity spi_minimized_delay_top is	
port( clk: in std_logic; -- system clock
		reset_n: in std_logic; -- system reset, active LOW in our system

		spi_0_MISO : in std_logic; -- master input slave output, SPI module 0
		spi_0_MOSI : out std_logic; -- master output slave input, SPI module 0
		spi_0_SCLK : out std_logic; -- SPI clock, SPI module 0           
		spi_0_CS : out std_logic; -- chip select (active HIGH), SPI module 0 

		spi_1_MISO : in std_logic; -- master input slave output, SPI module 1
		spi_1_MOSI : out std_logic; -- master output slave input, SPI module 1
		spi_1_SCLK : out std_logic; -- SPI clock, SPI module 1          
		spi_1_CS : out std_logic; -- chip select (active HIGH), SPI module 1	
		
		spi_2_MISO : in std_logic; -- master input slave output, SPI module 2
		spi_2_MOSI : out std_logic; -- master output slave input, SPI module 2
		spi_2_SCLK : out std_logic; -- SPI clock, SPI module 2
		spi_2_CS : out std_logic; -- chip select (active HIGH), SPI module 2 

		spi_3_MISO : in std_logic; -- master input slave output, SPI module 3
		spi_3_MOSI : out std_logic; -- master output slave input, SPI module 3
		spi_3_SCLK : out std_logic; -- SPI clock, SPI module 3           
		spi_3_CS : out std_logic; -- chip select (active HIGH), SPI module 3 

		spi_4_MISO : in std_logic; -- master input slave output, SPI module 4
		spi_4_MOSI : out std_logic; -- master output slave input, SPI module 4
		spi_4_SCLK : out std_logic; -- SPI clock, SPI module 4           
		spi_4_CS : out std_logic; -- chip select (active HIGH), SPI module 4 

		spi_5_MISO : in std_logic; -- master input slave output, SPI module 5
		spi_5_MOSI : out std_logic; -- master output slave input, SPI module 5
		spi_5_SCLK : out std_logic; -- SPI clock, SPI module 5
		spi_5_CS : out std_logic -- chip select (active HIGH), SPI module 5		
);
end spi_minimized_delay_top;

-- Architecture for the SPI master modules controlled via Nios II
architecture arch0 of spi_minimized_delay_top is

 -- Internal signal declarations
type spi_bits_array_type is array(integer range <>) of std_logic;
signal spi_dsp_miso_in_array, spi_dsp_mosi_out_array, spi_dsp_clk_out_array, spi_dsp_cs_out_array, 
		 end_signal_spi_dsp_array : spi_bits_array_type(0 to 5); -- arrays containing the MISO, MOSI, SCLK, CS, "end operation" of the six SPI modules

signal rst: std_logic; -- reset active HIGH for the desigend SPI module

signal start_spi: std_logic_vector(5 downto 0); -- "start SPI register"
signal end_signal_spi_dsp: std_logic; -- "end operation" of the whole SPI modules
signal delay_spi: std_logic_vector(7 downto 0); -- delay between SPI-CS and first SPI-CLK pulse

type spi16_rx_array_type is array(0 to 5) of std_logic_vector(15 downto 0);
signal data_dsp_rx_array: spi16_rx_array_type; -- array of data to transmit via SPI
signal spi_tx: spi16_rx_array_type; -- array of data received via SPI

signal spi_rx_0, spi_rx_1, spi_rx_2, spi_rx_3, spi_rx_4, spi_rx_5: std_logic_vector(15 downto 0); -- transmit data registers
signal spi_tx_0, spi_tx_1, spi_tx_2, spi_tx_3, spi_tx_4, spi_tx_5: std_logic_vector(15 downto 0); -- receive data registers
	
signal delay_spi_int : integer;

-- Declare the comopnent for the Nios II soft processor
component nios is
	port (
		clk_clk                                       : in  std_logic                     := 'X';             -- clk
		delay_spi_external_connection_export          : out std_logic_vector(7 downto 0);                     -- export
		end_spi_external_connection_export            : in  std_logic                     := 'X';             -- export
		reset_reset_n                                 : in  std_logic                     := 'X';             -- reset_n
		spi_rx_register_0_external_connection_export  : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
		spi_rx_register_1_external_connection_export  : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
		spi_rx_register_2_external_connection_export  : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
		spi_rx_register_3_external_connection_export  : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
		spi_rx_register_4_external_connection_export  : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
		spi_rx_register_5_external_connection_export  : in  std_logic_vector(15 downto 0) := (others => 'X'); -- export
		spi_tx_register_1_external_connection_export  : out std_logic_vector(15 downto 0);                    -- export
		spi_tx_register_2_external_connection_export  : out std_logic_vector(15 downto 0);                    -- export
		spi_tx_register_3_external_connection_export  : out std_logic_vector(15 downto 0);                    -- export
		spi_tx_register_4_external_connection_export  : out std_logic_vector(15 downto 0);                    -- export
		spi_tx_register_5_external_connection_export  : out std_logic_vector(15 downto 0);                    -- export
		spi_tx_register_0_external_connection_export  : out std_logic_vector(15 downto 0);                    -- export
		start_spi_register_external_connection_export : out std_logic_vector(5 downto 0)                      -- export
		);
	end component nios;

-- Declare the comopnent for the SPI master module
component spi_master_module is
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
end component spi_master_module;

begin

-- Instantiate the Nios II soft processor
u0 : component nios
	port map (
		clk_clk                                       => clk,                                       --                                    clk.clk
		reset_reset_n                                 => reset_n,                                 --                                  reset.reset_n
		start_spi_register_external_connection_export => start_spi, -- start_spi_register_external_connection.export
		end_spi_external_connection_export            => end_signal_spi_dsp,            --            end_spi_external_connection.export
		delay_spi_external_connection_export          => delay_spi,          --          delay_spi_external_connection.export
		spi_rx_register_0_external_connection_export  => spi_rx_0,  --  spi_rx_register_0_external_connection.export
		spi_rx_register_1_external_connection_export  => spi_rx_1,  --  spi_rx_register_1_external_connection.export
		spi_rx_register_2_external_connection_export  => spi_rx_2,  --  spi_rx_register_2_external_connection.export
		spi_rx_register_3_external_connection_export  => spi_rx_3,  --  spi_rx_register_3_external_connection.export
		spi_rx_register_4_external_connection_export  => spi_rx_4,  --  spi_rx_register_4_external_connection.export
		spi_rx_register_5_external_connection_export  => spi_rx_5,  --  spi_rx_register_5_external_connection.export
		spi_tx_register_1_external_connection_export  => spi_tx_1,  --  spi_tx_register_1_external_connection.export
		spi_tx_register_2_external_connection_export  => spi_tx_2,  --  spi_tx_register_2_external_connection.export
		spi_tx_register_3_external_connection_export  => spi_tx_3,  --  spi_tx_register_3_external_connection.export
		spi_tx_register_4_external_connection_export  => spi_tx_4,  --  spi_tx_register_4_external_connection.export
		spi_tx_register_5_external_connection_export  => spi_tx_5,  --  spi_tx_register_5_external_connection.export
		spi_tx_register_0_external_connection_export  => spi_tx_0  --  spi_tx_register_0_external_connection.export
		);
	
rst<=not(reset_n); -- reset active HIGH for the SPI master module

delay_spi_int<=to_integer(unsigned(delay_spi)); -- delay converter into integer 
	
-- For loop to instantiate the six SPI master modules
spi_modules_generate_dsp: for spi_dsp_i in 0 to 5 generate
	spi_master_module_dsp_i:spi_master_module
	generic map(
					CLK_DIV =>3, -- clk prescaler, the clk frequency will be divided by 2*CLK_DIV
					cpol =>'0', -- SPI-CLK polarity
					cpha =>'0', -- SPI-CLK phase
					WORD => 16 -- length of the data to transmit
	)
	port map(clk =>clk, -- module clock
				reset =>rst, -- module reset
				start=>start_spi(spi_dsp_i), -- module start operation, active on the transition LOW->HIGH
				data_tx_in =>spi_tx(spi_dsp_i), -- data to transmit
				DELAY_CONSTANT =>delay_spi_int, -- delay between SPI-CS and first SPI-CLK pulse (moved in the inputs so we can change it via SW with Nios II)

				data_rx_out => data_dsp_rx_array(spi_dsp_i), -- received data
				spi_miso_in=> spi_dsp_miso_in_array(spi_dsp_i), -- master input slave output
				spi_mosi_out=> spi_dsp_mosi_out_array(spi_dsp_i), -- master output slave input
				spi_cs_out=> spi_dsp_cs_out_array(spi_dsp_i), -- chip select
				spi_clk_out=> spi_dsp_clk_out_array(spi_dsp_i), -- SPI clock
				end_signal=>end_signal_spi_dsp_array(spi_dsp_i) -- end operation
	);
end generate spi_modules_generate_dsp;

spi_tx(0) <= spi_tx_0; -- connect data to transmit from Nios II to SPI master module 0
spi_tx(1) <= spi_tx_1; -- connect data to transmit from Nios II to SPI master module 1
spi_tx(2) <= spi_tx_2; -- connect data to transmit from Nios II to SPI master module 2
spi_tx(3) <= spi_tx_3; -- connect data to transmit from Nios II to SPI master module 3
spi_tx(4) <= spi_tx_4; -- connect data to transmit from Nios II to SPI master module 4
spi_tx(5) <= spi_tx_5; -- connect data to transmit from Nios II to SPI master module 5

spi_rx_0 <= data_dsp_rx_array(0); -- connect received data from SPI master module 0 to Nios II 
spi_rx_1 <= data_dsp_rx_array(1); -- connect received data from SPI master module 1 to Nios II 
spi_rx_2 <= data_dsp_rx_array(2); -- connect received data from SPI master module 2 to Nios II 
spi_rx_3 <= data_dsp_rx_array(3); -- connect received data from SPI master module 3 to Nios II 
spi_rx_4 <= data_dsp_rx_array(4); -- connect received data from SPI master module 4 to Nios II 
spi_rx_5 <= data_dsp_rx_array(5); -- connect received data from SPI master module 5 to Nios II 

end_signal_spi_dsp<= end_signal_spi_dsp_array(0) or end_signal_spi_dsp_array(1) or end_signal_spi_dsp_array(2) or end_signal_spi_dsp_array(3) or 
							end_signal_spi_dsp_array(4) or end_signal_spi_dsp_array(5) ; -- signal equal to '1' when one SPI transmission is finished
							
spi_dsp_miso_in_array(0)<=spi_0_MISO; -- connect external MISO to the MISO of the SPI master module 0
spi_dsp_miso_in_array(1)<=spi_1_MISO; -- connect external MISO to the MISO of the SPI master module 1
spi_dsp_miso_in_array(2)<=spi_2_MISO; -- connect external MISO to the MISO of the SPI master module 2
spi_dsp_miso_in_array(3)<=spi_3_MISO; -- connect external MISO to the MISO of the SPI master module 3
spi_dsp_miso_in_array(4)<=spi_4_MISO; -- connect external MISO to the MISO of the SPI master module 4
spi_dsp_miso_in_array(5)<=spi_5_MISO; -- connect external MISO to the MISO of the SPI master module 5

spi_0_MOSI<=spi_dsp_mosi_out_array(0); -- connect MOSI of the SPI master module 0 to the external MOSI
spi_1_MOSI<=spi_dsp_mosi_out_array(1); -- connect MOSI of the SPI master module 1 to the external MOSI
spi_2_MOSI<=spi_dsp_mosi_out_array(2); -- connect MOSI of the SPI master module 2 to the external MOSI
spi_3_MOSI<=spi_dsp_mosi_out_array(3); -- connect MOSI of the SPI master module 3 to the external MOSI
spi_4_MOSI<=spi_dsp_mosi_out_array(4); -- connect MOSI of the SPI master module 4 to the external MOSI
spi_5_MOSI<=spi_dsp_mosi_out_array(5); -- connect MOSI of the SPI master module 5 to the external MOSI

spi_0_SCLK<=spi_dsp_clk_out_array(0); -- connect SPI-CLK of the SPI master module 0 to the external SPI-CLK
spi_1_SCLK<=spi_dsp_clk_out_array(1); -- connect SPI-CLK of the SPI master module 1 to the external SPI-CLK
spi_2_SCLK<=spi_dsp_clk_out_array(2); -- connect SPI-CLK of the SPI master module 2 to the external SPI-CLK
spi_3_SCLK<=spi_dsp_clk_out_array(3); -- connect SPI-CLK of the SPI master module 3 to the external SPI-CLK
spi_4_SCLK<=spi_dsp_clk_out_array(4); -- connect SPI-CLK of the SPI master module 4 to the external SPI-CLK
spi_5_SCLK<=spi_dsp_clk_out_array(5); -- connect SPI-CLK of the SPI master module 5 to the external SPI-CLK

spi_0_CS<=spi_dsp_cs_out_array(0); -- connect CS of the SPI master module 0 to the external CS
spi_1_CS<=spi_dsp_cs_out_array(1); -- connect CS of the SPI master module 1 to the external CS
spi_2_CS<=spi_dsp_cs_out_array(2); -- connect CS of the SPI master module 2 to the external CS
spi_3_CS<=spi_dsp_cs_out_array(3); -- connect CS of the SPI master module 3 to the external CS
spi_4_CS<=spi_dsp_cs_out_array(4); -- connect CS of the SPI master module 4 to the external CS
spi_5_CS<=spi_dsp_cs_out_array(5); -- connect CS of the SPI master module 5 to the external CS

end arch0;
