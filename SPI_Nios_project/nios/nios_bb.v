
module nios (
	clk_clk,
	delay_spi_external_connection_export,
	end_spi_external_connection_export,
	reset_reset_n,
	spi_rx_register_0_external_connection_export,
	spi_rx_register_1_external_connection_export,
	spi_rx_register_2_external_connection_export,
	spi_rx_register_3_external_connection_export,
	spi_rx_register_4_external_connection_export,
	spi_rx_register_5_external_connection_export,
	spi_tx_register_1_external_connection_export,
	spi_tx_register_2_external_connection_export,
	spi_tx_register_3_external_connection_export,
	spi_tx_register_4_external_connection_export,
	spi_tx_register_5_external_connection_export,
	spi_tx_register_0_external_connection_export,
	start_spi_register_external_connection_export);	

	input		clk_clk;
	output	[7:0]	delay_spi_external_connection_export;
	input		end_spi_external_connection_export;
	input		reset_reset_n;
	input	[15:0]	spi_rx_register_0_external_connection_export;
	input	[15:0]	spi_rx_register_1_external_connection_export;
	input	[15:0]	spi_rx_register_2_external_connection_export;
	input	[15:0]	spi_rx_register_3_external_connection_export;
	input	[15:0]	spi_rx_register_4_external_connection_export;
	input	[15:0]	spi_rx_register_5_external_connection_export;
	output	[15:0]	spi_tx_register_1_external_connection_export;
	output	[15:0]	spi_tx_register_2_external_connection_export;
	output	[15:0]	spi_tx_register_3_external_connection_export;
	output	[15:0]	spi_tx_register_4_external_connection_export;
	output	[15:0]	spi_tx_register_5_external_connection_export;
	output	[15:0]	spi_tx_register_0_external_connection_export;
	output	[5:0]	start_spi_register_external_connection_export;
endmodule
