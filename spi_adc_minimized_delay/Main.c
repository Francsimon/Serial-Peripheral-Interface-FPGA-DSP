//###########################################################################
//
// FILE:   Main.c
//
// TITLE:  ACD reading and SPI transmission with delay minimization
//
//! \addtogroup FPGA_DSP_group
//! <h1>ADC read and SPI transmit (ADC_SPI)</h1>
//!
//! This program is developed as a part of Dr. Francesco Simonetti's PhD project. It is based on the
//! example code *Example_2837xDSpi_FFDLB.c* provided by Texas Instruments. This
//! implementation modifies and extends the functionality to include:
//! - ADC sampling
//! - Connection of SPI-CS to the ADC start of conversion
//! - ISR at the end of the ADC conversion to store the value into the SPI register
//!
//! This program provides a customized solution for sampling data from ADC and sending them via SPI such to minimize the communication delays.
//!
//! The code sets the ADCa converter to be triggered via an external signal. The external signal coincides with the SPI-CS of SPIb, that has to be active high.
//! When the master SPI (external board) asserts the SPI-CS, the ADC on the DSP samples the data.
//! When the ADC conversion is finished, an interrupt is triggered and the ISR stores the ADC value into the SPI register, which is ready for the transmission.
//! Note: the master SPI (external board) has to be programmed such to wait the time needed by the ADC to correctly sample the data.
//!
//###########################################################################
// $Francsimon Release: F2837xD FPGA-DSP Library v1 $
// $Release Date: Fri Dec  13 15:41:15 CDT 2024 $
//###########################################################################
//
// Included Files
//
#include "F28x_Project.h"
#include "math.h"

//////////////////
//
// Function Prototypes
//
interrupt void adca1_isr(void);

void spi_init(void);
void adc_config();
void SetupADCSoftwareSync(void);

Uint16 Vbus = 0;

void main(void)
{
    // Initialize the system control (PLL, clocks, and watchdog)
    InitSysCtrl();
    // Initialize GPIO pins for SPI functionality
    InitSpiaGpio();

    // Disable CPU interrupts
    DINT;
    IER = 0x0000; // Clear interrupt enable register
    IFR = 0x0000; // Clear interrupt flag register

    // Initialize the PIE control registers to their default state
    InitPieCtrl();

    // Initialize the PIE vector table with default ISR pointers
    InitPieVectTable();

    // Map the ADCA interrupt 1 to the corresponding ISR function
    EALLOW;  // Enable write to protected registers
    PieVectTable.ADCA1_INT = &adca1_isr;
    EDIS; // Disable access to protected registers

    // Initialize the SPI peripheral
    spi_init();

    // Configure and initialize the ADC
    adc_config();
    SetupADCSoftwareSync(); // Set up ADC with software synchronization

    // Enable CPU interrupt groups
    IER |= M_INT1; //Enable group 1 interrupts (for ADC interrupt)

    // Enable the PIE (Peripheral Interrupt Expansion) block
    PieCtrlRegs.PIECTRL.bit.ENPIE = 1;

    // Enable ADCA interrupt in PIE group 1, interrupt 1
    PieCtrlRegs.PIEIER1.bit.INTx1 = 1;

    // Configure input for ADC external start-of-conversion (EXTSOC)
    XbarRegs.XBARFLG2.bit.INPUT5=1; // Clear any prior flags for input 5
    EALLOW;
    InputXbarRegs.INPUT5SELECT = 23; // Map SPI-CS (pin 23) to ADCEXTSOC
    EDIS;

    // Enable global interrupts and real-time interrupt handling
    EINT;  // Enable Global interrupt INTM
    ERTM;  // Enable Global realtime interrupt DBGM

    while(1)
    {

    }
}

//
// Configurazione SPI
//
void spi_init(){
    //
    //GPIO settings
    //
    EALLOW; // Disable core registers protection
    //SPI-CLK pin 22
    GpioCtrlRegs.GPAPUD.bit.GPIO22 = 1; // Pull up enabled
    GpioCtrlRegs.GPAQSEL2.bit.GPIO22 = 3; // Asynchronous
    GpioCtrlRegs.GPAGMUX2.bit.GPIO22=1; // Mux to SPICLKB
    GpioCtrlRegs.GPAMUX2.bit.GPIO22=2; // Mux to SPICLKB
    GpioCtrlRegs.GPADIR.bit.GPIO22=0; // Input (default)
    //SPI-CS pin 23
    GpioCtrlRegs.GPAPUD.bit.GPIO23 = 0; // Pull up enabled
    GpioCtrlRegs.GPAQSEL2.bit.GPIO23 = 3; // Asynchronous
    GpioCtrlRegs.GPAGMUX2.bit.GPIO23=1; // Mux to SPISTEB
    GpioCtrlRegs.GPAMUX2.bit.GPIO23=2; // Mux to SPISTEB
    GpioCtrlRegs.GPADIR.bit.GPIO23=0; // Input (default)
    //SPI-MOSI pin 24
    GpioCtrlRegs.GPAPUD.bit.GPIO24 = 1; // Pull up enabled
    GpioCtrlRegs.GPAQSEL2.bit.GPIO24 = 3; // Asynchronous
    GpioCtrlRegs.GPAGMUX2.bit.GPIO24 =1; // Mux to SPISIMOB
    GpioCtrlRegs.GPAMUX2.bit.GPIO24 =2; // Mux to SPISIMOB
    GpioCtrlRegs.GPADIR.bit.GPIO24 =0; // Input (default)
    //SPI-MISO pin 25
    GpioCtrlRegs.GPAPUD.bit.GPIO25  = 0; // Pull up disabled (default)
    GpioCtrlRegs.GPAQSEL2.bit.GPIO25 = 3; // Asynchronous
    GpioCtrlRegs.GPAGMUX2.bit.GPIO25=1; // Mux to SPISOMIB
    GpioCtrlRegs.GPAMUX2.bit.GPIO25=2; // Mux to SPISOMIB
    GpioCtrlRegs.GPADIR.bit.GPIO25=1; // Output
    //
    // SPI settings
    //
    SpibRegs.SPICCR.bit.SPISWRESET = 0; // Reset: configuration may be changed in any order
    SpibRegs.SPICCR.bit.CLKPOLARITY = 0; // Rising edge
    SpibRegs.SPICCR.bit.HS_MODE =0;    // High Speed Mode DISABLE
    SpibRegs.SPICCR.bit.SPILBK = 0; // Loopback Disable (Testing Mode)
    SpibRegs.SPICCR.bit.SPICHAR = (16-1); // 16 bit character length
    //
    SpibRegs.SPICTL.bit.OVERRUNINTENA = 0; // Disable RECEIVER OVERRUN interrupts
    SpibRegs.SPICTL.bit.CLK_PHASE = 0; // without delay
    SpibRegs.SPICTL.bit.MASTER_SLAVE = 0; // slave
    SpibRegs.SPICTL.bit.TALK = 1; // Enables transmission
    SpibRegs.SPICTL.bit.SPIINTENA = 0; // Disables transmit/receive interrupt
    //
    SpibRegs.SPIBRR.bit.SPI_BIT_RATE = 39; // Baud rate = LSPCLK/(SPIBRR+1)
    //
    SpibRegs.SPIPRI.bit.FREE = 1; // Free run, continue SPI operation regardless a suspend occurred (for example, a breakpoint during debugging)
    SpibRegs.SPIPRI.bit.STEINV = 1; // SPI-CS active high
    //
    SpibRegs.SPICCR.bit.SPISWRESET = 1; // Release SPI from the reset state
    //
    EDIS; // Disable EALLOW
}
//
// configure ADC
//
void adc_config(){
    //
    EALLOW; // Disable core registers protection
    //
    //Write configurations
    AdcaRegs.ADCCTL2.bit.PRESCALE = 6; //Set ADCCLK divider to /4x
    AdcSetMode(ADC_ADCA, ADC_RESOLUTION_12BIT, ADC_SIGNALMODE_SINGLE); //Set resolution of ADC
    //
    //interrupt setup
    //
    AdcaRegs.ADCCTL1.bit.INTPULSEPOS = 1; //Set pulse positions to late, i.e., at the end of conversion (EOC)
    AdcaRegs.ADCINTSEL1N2.bit.INT1SEL = 0; // EOC0 is trigger for ADCINT1
    AdcaRegs.ADCINTSEL1N2.bit.INT1E = 1; // Interrupt enable
    AdcaRegs.ADCINTFLGCLR.bit.ADCINT1 = 1; // Make sure INT1 flag is cleared
    //
    //power up the ADCs
    //
    AdcaRegs.ADCCTL1.bit.ADCPWDNZ = 1;
    DELAY_US(1000); // Delay for 1ms to allow ADC time to power up
    //
    EDIS; // Disable EALLOW
}
//
// Configure ADC synchronization
//
void SetupADCSoftwareSync(void)
{
    Uint16 acqps;
    //
    // Determine minimum acquisition window (in SYSCLKS) based on resolution
    //
    if(ADC_RESOLUTION_12BIT == AdcaRegs.ADCCTL2.bit.RESOLUTION)
    {
        acqps = 14; //75ns
    }
    else // Resolution is 16-bit
    {
        acqps = 63; //320ns
    }
    //
    // Select the channels to convert, the start of conversion channel and the conversion time window
    //
    EALLOW; // Disable core registers protection
    //
    AdcaRegs.ADCSOC0CTL.bit.CHSEL = 2; // Convert value from pin ADCINA2 in this work
    AdcaRegs.ADCSOC0CTL.bit.ACQPS = acqps; // Determines acquisition window
    AdcaRegs.ADCSOC0CTL.bit.TRIGSEL = 4; // Conversion triggered by ADCEXTSOC (rising edge the transitions 0->1)
    //
    EDIS; // Disable EALLOW
}
//
// ADC ISR
//
interrupt void adca1_isr(void)
{
    Vbus = AdcaResultRegs.ADCRESULT0;  // acquire value sampled by the ADC
    //
    SpibRegs.SPIDAT = Vbus; // store the value directly into the SPI
    //
    AdcaRegs.ADCINTFLGCLR.bit.ADCINT1 = 1; // clear INT1 flag
    PieCtrlRegs.PIEACK.all = PIEACK_GROUP1; // clear interrupt's PIE group 1
}
