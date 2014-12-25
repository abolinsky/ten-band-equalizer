`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:36:57 11/24/2008 
// Design Name: 
// Module Name:    adc_tester 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

// SPIPeripheral.v
// SPI Peripheral model - non-synthesizable

module adc_tester(SCK, SDI, CS_, SDO);
parameter TestSineWaveFile = "./TestSineWaveFile683_Hz.tb",
			 //TestSineWaveFile1 = "./TestSineWaveFile1025_Hz.tb";
			 TestSineWaveFile1 = "./TestSineWaveFile683_Hz.tb";

input   SCK;
input   SDI;
input   CS_;
output  SDO;

reg SDO;
reg [15:0] TestSineWaveChannelL[0:999] ;
reg [15:0] TestSineWaveChannelR[0:999] ;

integer i, j, ChanSelect ;

reg [15:0] SDIReg, SDOReg ;
initial
begin
  // Use the same values for each channel.  I assume the input hex values
  // are in 1.15.  So, before outputting them from the ADC, I convert them
  // to an unsigned value between 0 and 65535 to properly mimic the activity
  // of the actual ADC.
  $readmemh(TestSineWaveFile,TestSineWaveChannelL);
  $readmemh(TestSineWaveFile1,TestSineWaveChannelR);
  SDO = 0 ;
  SDOReg = 0 ;
  SDIReg = 0 ;
end

always @ (negedge CS_)
begin
  for (i = 0; i < 1000; i = i+1) begin
    for (ChanSelect = 0; ChanSelect < 2; ChanSelect = ChanSelect + 1) begin
	   // Flip the high order bit on the input to add 32768.
		if (SDIReg[15:14] == 2'b10) begin
			SDOReg = {!(TestSineWaveChannelL[i][15]), TestSineWaveChannelL[i][14:0]};
		end else if (SDIReg[15:14] == 2'b11) begin
			SDOReg = {!(TestSineWaveChannelR[i][15]), TestSineWaveChannelR[i][14:0]};
		end
	
		for (j = 15;j >= 0; j = j-1) begin
		  SDO = SDOReg[j] ;
        while (SCK == 0)
        begin
          #1 ;
        end
        SDIReg[j] = SDI ;
        while (SCK == 1)
        begin
          #1 ;
        end
      end
    end
  end
end
endmodule
