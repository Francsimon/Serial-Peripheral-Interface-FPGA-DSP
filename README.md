# Serial Peripheral Interface between FPGA and DSP: Optimized Scheme for Minimum Communication Delay

This project implements the serial peripheral interface (SPI) protocol between an Altera FPGA and a Texas Instruments DSP.
The main feature of this project is the sampling and transmission scheme of the data, which was designed to minimize the delays between the sapling of the data from the ADC
in the DSP and the SPI transmission of the data from DSP to FPGA. Refer to the published paper for further details.
It contains two files:
1. Quartus Prime project for Altera FPGAs: "SPI_Nios_project" folder (VHDL)
2. Code Composer Studio project for Texas Instruments DSPs:  "spi_adc_minimized_delay" folder (C)

---

## Table of Contents

1. [Author](#author)
2. [Overview](#overview)
3. [Platform Targets](#platform-targets)
4. [Installation](#installation)
5. [Usage Instructions](#usage-instructions)
6. [For More Details](#for-more-details)

--- 

## Author
* **Francesco Simonetti**, PhD, Research Assistant at Aalborg University, Denmark.
ORCID: https://orcid.org/0000-0002-1135-052X
ResearchGate: https://www.researchgate.net/profile/Francesco_Simonetti4

---

## Overview

The FPGA implements the Nios II soft processor to drive the SPI communication of six SPI master modules (this number can be easily extended).
Via C programming, is it possible to code Nios II to transmit data via one SPI module, read the received data, start the SPI communication and monitor if the transmission is finished.
By using the SPI modules provided by Altera, it is only possible to start the SPI communication via software. Hence, if we have multiple SPI modules, we have to execute one
line of code for each of them, starting the transmissions sequentially.
It creates a small delay between subsequent communications, i.e., about 600 ns. If we consider six SPI communications, like in this project, there is a 300 us delay between
the first and last transmission. This phenomenon can be undesirable for hard-time-constrained applications.

This project overcomes this drawback by using an ad-hoc designed SPI module.
The major feature of this module is the presence of a start operation signal that allows the communication to start via HW.
The start operation signal of each SPI module is connected to a register, accessible from Nios II.
By writing into this register, Nios II can start communications with multiple SPI peripherals with a single line of code, establishing the SPI transmissions concurrently!

Moreover, the implementation of the sample & transmission of the data was designed to minimize the delay on the DSP.
The start of conversion of the ADC was connected to the SPI-CS, such as to start acquiring the data soon after the master FPGA asks for them. 
An interrupt is triggered after the conversion and the ISR stores the value into the register of the SPI slave module.
The SPI master module on the FPGA was designed to wait for a delay between the SPI-CS and SPI-CLK to allow the correct sample & store from the DSP.

This sample & communication scheme resulted in minimizing the delays in the ADC sampling & SPI transmission of the data from DSP to FPGA.

---

## Platform Targets

This project was developed with the following platforms:

- **Desktop PC**:
  - Linux Ubuntu 20.04
  - Quartus Prime Version 17.1.0 Lite Edition
  - Code Composer Studio 12.7.0

- **FPGA**:
  - Altera Cyclone V 5CEBA7F31C8N

- **DSP**:
  - Texas Instrument TMS320 F28377SPTPT

---

## Installation

### Steps

1. From the FPGA side, import "SPI_Nios_project" in Quartus Prime.
   You will find a main code employing two components:
   - The SPI master module;
   - The Nios II soft processor.
   You can look at the Platform Designer to see the connections among Nios II, the JTAG programmer, RAM memory and the main registers.

   You can look at the SPI master module to understand the inputs and the possible operating modes (clock phase and polarities, delays, word length).

2. In the Quartus Prime window, navigate to Tools -> Nios II Software Build Tools for Eclipse.
 
    Select ./SPI_NIOS_project/software as workspace.
   
    In the Project Explorer, on the left, right-click on the soft_bsp folder. Click on Nios -> Generate BSP.
   
    Then, right-click on the soft folder. Click on Build Project and Run As -> Nios II Hardware to run the code.

3. From the DSP side, import "spi_adc_minimized_delay" in Code Composer Studio. Then, Build and Flash.

---

## Usage Instructions

From the Eclipse window opened through Quartus Prime, you can modify the C code executed by Nios II. You can send data via SPI, read received data and start communications in parallel.

From Code Composer Studio, you can adapt the code to your implementation by employing the communication scheme that minimizes the sample & transmission delays.
You can modify the provided code to develop your own implementation, taking advantage of the optimized sample & transmission of the data.

---

## For More Details

You can refer to the paper:

F. Simonetti, M. Dezhbord, S. Mohamadian, A. D’Innocenzo, C. Cecati and R. Di Fonso, "Optimized DSP-FPGA Communication in CHB-STATCOM with Direct MPC," 2024 IEEE Energy Conversion Congress and Exposition (ECCE), Phoenix, AZ, USA, 2024, pp. 3997-4002, doi: 10.1109/ECCE55643.2024.10861606.



