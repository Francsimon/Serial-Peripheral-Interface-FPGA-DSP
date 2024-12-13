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

	u0 : component nios
		port map (
			clk_clk                                       => CONNECTED_TO_clk_clk,                                       --                                    clk.clk
			delay_spi_external_connection_export          => CONNECTED_TO_delay_spi_external_connection_export,          --          delay_spi_external_connection.export
			end_spi_external_connection_export            => CONNECTED_TO_end_spi_external_connection_export,            --            end_spi_external_connection.export
			reset_reset_n                                 => CONNECTED_TO_reset_reset_n,                                 --                                  reset.reset_n
			spi_rx_register_0_external_connection_export  => CONNECTED_TO_spi_rx_register_0_external_connection_export,  --  spi_rx_register_0_external_connection.export
			spi_rx_register_1_external_connection_export  => CONNECTED_TO_spi_rx_register_1_external_connection_export,  --  spi_rx_register_1_external_connection.export
			spi_rx_register_2_external_connection_export  => CONNECTED_TO_spi_rx_register_2_external_connection_export,  --  spi_rx_register_2_external_connection.export
			spi_rx_register_3_external_connection_export  => CONNECTED_TO_spi_rx_register_3_external_connection_export,  --  spi_rx_register_3_external_connection.export
			spi_rx_register_4_external_connection_export  => CONNECTED_TO_spi_rx_register_4_external_connection_export,  --  spi_rx_register_4_external_connection.export
			spi_rx_register_5_external_connection_export  => CONNECTED_TO_spi_rx_register_5_external_connection_export,  --  spi_rx_register_5_external_connection.export
			spi_tx_register_1_external_connection_export  => CONNECTED_TO_spi_tx_register_1_external_connection_export,  --  spi_tx_register_1_external_connection.export
			spi_tx_register_2_external_connection_export  => CONNECTED_TO_spi_tx_register_2_external_connection_export,  --  spi_tx_register_2_external_connection.export
			spi_tx_register_3_external_connection_export  => CONNECTED_TO_spi_tx_register_3_external_connection_export,  --  spi_tx_register_3_external_connection.export
			spi_tx_register_4_external_connection_export  => CONNECTED_TO_spi_tx_register_4_external_connection_export,  --  spi_tx_register_4_external_connection.export
			spi_tx_register_5_external_connection_export  => CONNECTED_TO_spi_tx_register_5_external_connection_export,  --  spi_tx_register_5_external_connection.export
			spi_tx_register_0_external_connection_export  => CONNECTED_TO_spi_tx_register_0_external_connection_export,  --  spi_tx_register_0_external_connection.export
			start_spi_register_external_connection_export => CONNECTED_TO_start_spi_register_external_connection_export  -- start_spi_register_external_connection.export
		);

