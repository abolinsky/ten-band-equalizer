// top.v
// Top level for cse465
// Instantiate your design and the Leon2 processor and wire them up.
// For Simulation: Comment out `define SYNTH to use the APBBusMaster.
// For Synthesis, uncomment SYNTH to synthesize a real Leon2.
//`define SYNTH

`resetall
`timescale 1ns/10ps

module top(pb_sw, pll_clk, led,
  sdram_a, sdram_d, sdram_ba, sdram_dqm, sdram_clk, sdram_cke, sdram_csn,	sdram_wen, sdram_rasn, sdram_casn,
	uart1_txd, uart1_rxd, uart1_rts, uart1_cts,
	uart2_txd, uart2_rxd,	uart2_rts, uart2_cts,
	flash_a, flash_d, flash_oen, flash_wen,	flash_cen, flash_byte, flash_ready,	flash_rpn, flash_wpn,
  phy_mii_data,	phy_tx_clk,	phy_rx_clk,	phy_rx_data, phy_dv, phy_rx_er,	phy_col, phy_crs,	phy_tx_data, phy_tx_en,	phy_mii_clk, phy_100,	phy_rst_n,
//  gpio,
  can_txd, can_rxd,
	smsc_addr, smsc_data, smsc_nbe, smsc_resetn, smsc_ardy, smsc_nldev,	smsc_nrd,	smsc_nwr,	smsc_ncs,	smsc_aen,	smsc_lclk, smsc_wnr, smsc_rdyrtn,	smsc_cycle,	smsc_nads,
  SPI_AD_SDI, SPI_AD_SDO, AD_CONV_ST, SPI_AD_SCK,
  SPI_DAC_CLK, SPI_DAC_MOSI, SPI_DAC_MISO, DAC_LD,
  LCD_RS, LCD_RW, LCD_EN, BACKL_ON, LCD_DATA, Test) ;

parameter PAMAX = 32, PDMAX = 32 ;

input [4:1] pb_sw ; // push buttons
input pll_clk ; // PLL Clock
output [8:1] 		led ;

output [11:0] 	sdram_a ;
inout [31:0]    sdram_d ;
output [3:0]    sdram_ba ;
output [3:0]    sdram_dqm ;
inout sdram_clk ;
output					sdram_cke ;  // sdram clock enable
output					sdram_csn ; //  sdram chip select
output					sdram_wen ; //  sdram write enable
output					sdram_rasn ; // sdram ras
output 					sdram_casn ; // sdram cas

output					uart1_txd  	;
input						uart1_rxd  	;
output					uart1_rts  	;
input						uart1_cts  	;

output					uart2_txd  	;
input						uart2_rxd  	;
output					uart2_rts  	;
input						uart2_cts  	;

output [20:0]		flash_a ;
inout [15:0] 		flash_d ;
output					flash_oen  	;
output					flash_wen 	;
output					flash_cen  	;
output					flash_byte 	;
input						flash_ready	;
output					flash_rpn 	;
output					flash_wpn 	;

inout						phy_mii_data ; // ethernet PHY interface
input						phy_tx_clk 	;
input						phy_rx_clk 	;
input [3:0] 		phy_rx_data	;
input						phy_dv  	  ;
input						phy_rx_er  	;
input						phy_col 	  ;
input						phy_crs 	  ;
output [3:0]		phy_tx_data ;
output					phy_tx_en 	;
output					phy_mii_clk ;
input						phy_100 	  ;	// 100 Mbit indicator
output					phy_rst_n 	; 

//inout [15:0] gpio ;
output					can_txd	;

input						can_rxd	;

output [14:0] 	smsc_addr ;
inout [31:0]		smsc_data ;
output [3:0] 		smsc_nbe ;
output					smsc_resetn ;
input						smsc_ardy ;
// --    smsc_intr  	: in  std_ulogic;
input						smsc_nldev 	;
output					smsc_nrd   	;
output					smsc_nwr   	;
output					smsc_ncs   	;
output					smsc_aen   	;
output					smsc_lclk  	;
output					smsc_wnr   	;
output					smsc_rdyrtn	;
output					smsc_cycle 	;
output					smsc_nads   ;

output    SPI_AD_SDI ;
input     SPI_AD_SDO ;
output    AD_CONV_ST ;
output    SPI_AD_SCK ;

output    SPI_DAC_CLK ;
output    SPI_DAC_MOSI ;
input     SPI_DAC_MISO ;
output    DAC_LD ;

output LCD_RS ;
output LCD_RW ;
output LCD_EN ;
output BACKL_ON ;
inout [7:0] LCD_DATA ;

output [31:0] Test ;
wire [0:0] gpio ;

// AMBA APB signals
wire Reset_, Clk ;
wire [PAMAX-1:0] PAddr ;
wire [PDMAX-1:0] PWData ;
wire PEnable, PWrite ;
wire PSel8 ;
wire [PDMAX-1:0] PRData8 ;
wire PSel10 ;
wire [PDMAX-1:0] PRData10 ;
wire PSel11 ;
wire [PDMAX-1:0] PRData11 ;
wire PSel12 ;
reg [PDMAX-1:0] PRData12 ;	// made reg
wire PSel13 ;
reg [PDMAX-1:0] PRData13 ; // made reg
wire PSel14 ;
reg [PDMAX-1:0] PRData14 ;	// made reg
wire [31:0] TestD ;
reg  [31:0] Test ;
wire [99:0] ChipScopeData;
wire [7:0] ChipScopeTrig0;

// Module to Module Signals
wire signed [15:0] Band1, Band2, Band3, Band4, Band5, Band6, Band7, Band8, Band9, Band10;
reg [31:0] DSPIn, ADCIn, DACIn;

wire [31:0] ECAddr, ECData;
wire ECSel12, ECSel13, ECSel14, ECWrite, ECEnable;

reg [31:0] Addr, Data;
wire [31:0] RData12, RData13, RData14;
reg Sel12, Sel13, Sel14, Write, Enable;

wire [1:0] RAMEnable;
wire ECOn;

wire SPI_AD_SDO_TEST;
reg SPI_AD_SDO_MUX;
wire SPI_SELECT;

wire signed [15:0] LeftSample, RightSample, Sample;
wire RAMXWr;

// Instantiate your verilog modules here

EqualizerController EC (
    .Reset_(Reset_), 
    .Clk(Clk), 
    .PSel(PSel8), 
    .PEnable(PEnable), 
    .PWrite(PWrite), 
    .PAddr(PAddr), 
    .PWData(PWData), 
    .DSPIn(DSPIn), 
    .ADCIn(ADCIn), 
	 .DACIn(DACIn),
    .PRData(PRData8), 
    .ECSel12(ECSel12), 
    .ECSel13(ECSel13), 
    .ECSel14(ECSel14), 
    .ECEnable(ECEnable), 
    .ECWrite(ECWrite), 
    .ECAddr(ECAddr), 
    .ECData(ECData), 
    .BandOne(Band1), 
    .BandTwo(Band2), 
    .BandThree(Band3), 
    .BandFour(Band4), 
    .BandFive(Band5), 
    .BandSix(Band6), 
    .BandSeven(Band7), 
    .BandEight(Band8), 
    .BandNine(Band9), 
    .BandTen(Band10), 
	 .RAMEnable(RAMEnable),
    .ECOn(ECOn)
    );

ten_band_fir DSP (
    .Reset_(Reset_), 
    .Clk(Clk), 
    .PSel(Sel14), 
    .PEnable(Enable), 
    .PWrite(Write), 
    .PAddr(Addr), 
    .PWData(Data), 
    .BandOneData(Band1), 
    .BandTwoData(Band2), 
    .BandThreeData(Band3), 
    .BandFourData(Band4), 
    .BandFiveData(Band5), 
    .BandSixData(Band6), 
    .BandSevenData(Band7), 
    .BandEightData(Band8), 
    .BandNineData(Band9), 
    .BandTenData(Band10), 
	 .RAMEnable(RAMEnable),
    .PRData(RData14),
	 .LeftSample(LeftSample),
	 .RightSample(RightSample),
	 .Sample(Sample),
	 .RAMXWr(RAMXWr)
    );
	
SPIPeripheral ADC_SPI (
    .Clk(Clk), 
    .Reset_(Reset_), 
    .PSel(Sel12), 
    .PEnable(Enable), 
    .PWrite(Write), 
    .PWData(Data), 
    .PRData(RData12), 
    .SCK(SPI_AD_SCK),
	 .SDI(SPI_AD_SDI),
	 .CS(AD_CONV_ST),
	 .SDO(SPI_AD_SDO_MUX)
    );

SPIPeripheral DAC_SPI (
    .Clk(Clk), 
    .Reset_(Reset_), 
    .PSel(Sel13), 
    .PEnable(Enable), 
    .PWrite(Write), 
    .PWData(Data), 
    .PRData(RData13), 
    .SCK(SPI_DAC_CLK),
	 .SDI(SPI_DAC_MOSI),
	 .CS(DAC_LD),
	 .SDO(SPI_DAC_MISO)
    );

// Assign all unused outputs here

//assign SPI_AD_SDI = 0 ;
//assign AD_CONV_ST = 0 ;
//assign SPI_AD_SCK = 0 ;
//assign SPI_DAC_CLK = 0 ;
//assign SPI_DAC_MOSI = 0 ;
//assign DAC_LD = 0 ;
assign LCD_RS = 0 ;
assign LCD_RW = 0 ;
assign LCD_EN = 0 ;
assign BACKL_ON = 0 ;
assign LCD_DATA = 0 ;

always @  * begin
	if (ECOn == 0) begin
		Sel12 = PSel12;
		Sel13 = PSel13;
		Sel14 = PSel14;
		Enable = PEnable;
		Write = PWrite;
		Data = PWData;
		Addr = PAddr;
		PRData12 = RData12;
		PRData13 = RData13;
		PRData14 = RData14;
		ADCIn = 0;
		DACIn = 0;
		DSPIn = 0;
	end
	else if (ECOn == 1) begin
		Sel12 = ECSel12;
		Sel13 = ECSel13;
		Sel14 = ECSel14;
		Enable = ECEnable;
		Write = ECWrite;
		Data = ECData;
		Addr = ECAddr;
		ADCIn = RData12;
		DACIn = RData13;
		DSPIn = RData14;
		PRData12 = 0;
		PRData13 = 0;
		PRData14 = 0;
	end
	
	if (SPI_SELECT == 1) begin
		SPI_AD_SDO_MUX = SPI_AD_SDO;
	end
	else if (SPI_SELECT == 0) begin
		SPI_AD_SDO_MUX = SPI_AD_SDO_TEST;
	end
end

// Register Test for general purpose outputs on J24
// See top.ucf for pinouts
always @ (posedge Clk)
begin
	if (~Reset_)
	  Test <= 0 ; // Reset TestQ
	else
	  Test <= TestD ;
end

assign TestD[0] = ECWrite ;
assign TestD[1] = ECEnable ;
assign TestD[2] = ECSel12 ;
assign TestD[3] = ECSel13;
assign TestD[4] = Reset_;
assign TestD[5] = RData12[31];
assign TestD[6] = RData13[31];
assign TestD[7] = SPI_DAC_CLK ;
assign TestD[8] = SPI_DAC_MOSI ;
assign TestD[9] = SPI_DAC_MISO ;
assign TestD[10] = DAC_LD ;
assign TestD[11] = SPI_AD_SDI ;
assign TestD[12] = SPI_AD_SDO ;
assign TestD[13] = AD_CONV_ST ;
assign TestD[14] = SPI_AD_SCK ;
assign TestD[15] = ~Test[15] ;
assign ChipScopeData = {RAMXWr, LeftSample[15:0], RightSample[15:0], Sample[14:0],
								DSPIn[31],DSPIn[15:0],ECData[23:0],ECAddr[11],
								RAMEnable[1], SPI_AD_SDI, AD_CONV_ST, SPI_AD_SDO,
								SPI_DAC_MOSI,DAC_LD,
								ECSel14,ECSel13,ECSel12,PSel8} ;
assign ChipScopeTrig0 = {ECSel14,ECSel13,ECSel12,PSel11,PSel10,PSel8,ECEnable,ECWrite} ;

//assign TestD[0] = 0 ;
//assign TestD[1] = 0 ;
//assign TestD[2] = 0 ;
//assign TestD[3] = 0 ;
//assign TestD[4] = 0 ;
//assign TestD[5] = 0 ;
//assign TestD[6] = 0 ;
//assign TestD[7] = 0 ;
//assign TestD[8] = 0 ;
//assign TestD[9] = 0 ;
//assign TestD[10] = 0 ;
//assign TestD[11] = 0 ;
//assign TestD[12] = 0 ;
//assign TestD[13] = 0 ;
//assign TestD[14] = 0 ;
//assign TestD[15] = 0 ;
//assign TestD[16] = 0 ;
//assign TestD[17] = 0 ;
//assign TestD[18] = 0 ;
//assign TestD[19] = 0 ;
//assign TestD[20] = 0 ;
//assign TestD[21] = 0 ;
//assign TestD[22] = 0 ;
//assign TestD[23] = 0 ;
//assign TestD[24] = 0 ;
//assign TestD[25] = 0 ;
//assign TestD[26] = 0 ;
//assign TestD[27] = 0 ;
//assign TestD[28] = 0 ;
//assign TestD[29] = 0 ;
//assign TestD[30] = 0 ;
//assign TestD[31] = 0 ;
//assign ChipScopeData = 0 ;
//assign ChipScopeTrig0 = 0 ;

// Don't modify below here
`ifdef SYNTH
// leon3 processor

assign SPI_SELECT = 1;

leon3mpAPB leon3mpAPB1(.pb_sw(pb_sw), .pll_clk(pll_clk), .led(led),
  .sdram_a(sdram_a), 
  .sdram_d(sdram_d), 
  .sdram_ba(sdram_ba), .sdram_dqm(sdram_dqm),
  .sdram_clk(sdram_clk),
  .sdram_cke(sdram_cke), .sdram_csn(sdram_csn),	.sdram_wen(sdram_wen), .sdram_rasn(sdram_rasn), .sdram_casn(sdram_casn),
	.uart1_txd(uart1_txd), .uart1_rxd(uart1_rxd), .uart1_rts(uart1_rts), .uart1_cts(uart1_cts),
	.uart2_txd(uart2_txd), .uart2_rxd(uart2_rxd),	.uart2_rts(uart2_rts), .uart2_cts(uart2_cts),
	.flash_a(flash_a), .flash_d(flash_d),
  .flash_oen(flash_oen), .flash_wen(flash_wen),	.flash_cen(flash_cen), .flash_byte(flash_byte), .flash_ready(flash_ready),	.flash_rpn(flash_rpn), .flash_wpn(flash_wpn),
  .phy_mii_data(phy_mii_data), .phy_tx_clk(phy_tx_clk),	.phy_rx_clk(phy_rx_clk),	.phy_rx_data(phy_rx_data), .phy_dv(phy_dv), .phy_rx_er(phy_rx_er),	.phy_col(phy_col), .phy_crs(phy_crs),	.phy_tx_data(phy_tx_data), .phy_tx_en(phy_tx_en),	.phy_mii_clk(phy_mii_clk), .phy_100(phy_100),	.phy_rst_n(phy_rst_n),
  .gpio(gpio),
  .can_txd(can_txd), .can_rxd(can_rxd),
	.smsc_addr(smsc_addr), .smsc_data(smsc_data), .smsc_nbe(smsc_nbe), .smsc_resetn(smsc_resetn), .smsc_ardy(smsc_ardy), .smsc_nldev(smsc_nldev),	.smsc_nrd(smsc_nrd),	.smsc_nwr(smsc_nwr),	.smsc_ncs(smsc_ncs),	.smsc_aen(smsc_aen),	.smsc_lclk(smsc_lclk), .smsc_wnr(smsc_wnr), .smsc_rdyrtn(smsc_rdyrtn),	.smsc_cycle(smsc_cycle),	.smsc_nads(smsc_nads),
	.apb_clk(Clk), .apb_reset_l(Reset_),
	.apbi_paddr(PAddr), .apbi_pwdata(PWData), .apbi_penable(PEnable), .apbi_pwrite(PWrite),
	.apbi_psel_8(PSel8), .apbo_prdata_8(PRData8),
	.apbi_psel_10(PSel10), .apbo_prdata_10(PRData10),
	.apbi_psel_11(PSel11), .apbo_prdata_11(PRData11),
	.apbi_psel_12(PSel12), .apbo_prdata_12(PRData12),
	.apbi_psel_13(PSel13), .apbo_prdata_13(PRData13),
	.apbi_psel_14(PSel14), .apbo_prdata_14(PRData14)) ;

// See chipscope_ila_tut.pdf for details on how to generate the icon and ila cores
  wire [35:0] ChipScopeControl0;
  //-----------------------------------------------------------------
  //
  //  ICON core instance
  //
  //-----------------------------------------------------------------
  icon i_icon
    (
      .CONTROL0(ChipScopeControl0)
    );
  //-----------------------------------------------------------------
  //
  //  ILA core instance
  //
  //-----------------------------------------------------------------
  ila i_ila
    (
      .CONTROL(ChipScopeControl0),
      .CLK(Clk),
      .DATA(ChipScopeData),
      .TRIG0(ChipScopeTrig0)) ;	 
`else
// APBBusMaster simulation
APBBusMaster APBBusMaster1(Clk,Reset_,PAddr,PWData,PEnable,PWrite,
	PSel8,PRData8,
	PSel10,PRData10,
	PSel11,PRData11,
	PSel12,PRData12,
	PSel13,PRData13,
	PSel14,PRData14) ;
	
adc_tester ADC1(SPI_AD_SCK, SPI_AD_SDI, AD_CONV_ST, SPI_AD_SDO_TEST);
dac_tester DAC1(SPI_DAC_CLK, SPI_DAC_MOSI, DAC_LD, SPI_DAC_MISO);

assign SPI_SELECT = 0;

`endif


endmodule


