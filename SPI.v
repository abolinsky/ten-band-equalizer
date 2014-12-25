`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineers: Alexander Bolinsky & Jeremy Tang
// 
// Create Date:    	10/21/2014 
// Module Name:    	SPIPeripheral 
// Project Name: 		Serial Peripheral Interface
// Description: 
//
// Revision: 0.01			
//////////////////////////////////////////////////////////////////////////////////

module SPIPeripheral(
    input Clk,
	 input Reset_,
	 input PSel,
	 input PEnable,
	 input PWrite,
	 input [31:0] PWData,
    output [31:0] PRData,
	 output SCK,
	 output SDI,
	 output CS,
	 input SDO
    );

// Signals
wire LeonWrite;
reg Ready, ReadyD;
reg Enabled, EnabledD;

// Registers
reg [4:0] CurrState, NextState;
reg [31:0] StoredPWData, StoredPWDataD;
reg StoredSDO;
reg [31:0] SDI_Data, SDI_DataD;
reg [23:0] SDO_Data, SDO_DataD;
reg [4:0] BitsPerSample, BitsPerSampleD;
reg [9:0] SampleRate, SampleRateD;
reg [9:0] CounterD, Counter;
reg [4:0] CounterBitsD, CounterBits;
reg CSreg, CSregD;
reg SDIreg, SDID;
reg SCKreg, SCKD;

// Combinational Logic
assign LeonWrite = PSel & PEnable & PWrite;
assign PRData[31] = Ready;
assign PRData[30] = Enabled; 
assign PRData[29:25] = CurrState[4:0];
assign PRData[24] = 0;
assign PRData[23:0] = SDO_Data[23:0];
assign CS = CSreg;
assign SDI = SDIreg;
assign SCK = SCKreg;

// States
parameter 	Init = 'h10, 
				InitParse = 'h11,
				ConvertReady = 'h12, 
				Convert = 'h13,
				ConvertWait = 'h14,
				Talk0 = 'h0,
				Talk1 = 'h1,
				Talk2 = 'h2,
				Talk3 = 'h3,
				Talk4 = 'h4,
				Talk5 = 'h5;

// Combinational Block (FSM)
always @ *
begin

// Default Behavior
	ReadyD = Ready;
	EnabledD = Enabled;
	NextState = CurrState;
	StoredPWDataD = StoredPWData;
	SDI_DataD = SDI_Data;
	SDO_DataD = SDO_Data;
	BitsPerSampleD = BitsPerSample;
	SampleRateD = SampleRate;
	CounterD = Counter;
	CounterBitsD = CounterBits;
	CSregD = CSreg;
	SDID = SDIreg;
	SCKD = SCKreg;

// Next State Definitions
  case (CurrState) 
    Init: 
		begin
			SampleRateD = 0;
			BitsPerSampleD = 0;
			SCKD = 0;
			CSregD = 1;
			SDID = 0;
			EnabledD = 0;
			SDO_DataD = 'hbadabada;
			SDI_DataD = 0;
			
			StoredPWDataD = PWData;
			ReadyD = 1;
			
			if (LeonWrite) begin
				ReadyD = 0;
				NextState = InitParse;
			end
		end
		
    InitParse: 
		begin
			if (StoredPWData[31] == 1 && StoredPWData[30] == 0) begin
				BitsPerSampleD = StoredPWData[4:0];
				SampleRateD = StoredPWData[21:5]-1;
				CounterD = StoredPWData[21:5]-1;
				EnabledD = 1;
				ReadyD = 1;
				NextState = ConvertReady;
			end
			else begin
				EnabledD = 0;
				ReadyD = 1;
				NextState = Init;
			end
		end
	
	 ConvertReady:
		begin
			// transition when counter <= 0
			if (Counter == 0) begin
				CounterBitsD = BitsPerSample-1;
				CounterD = SampleRate;
				ReadyD = 0;
				CSregD = 0;
				SCKD = 0;
				NextState = Talk0;
			end
			else begin
				CounterD = Counter - 1;
				if (LeonWrite) begin
					StoredPWDataD = PWData;
					ReadyD = 0;
					NextState = Convert;
				end
			end		
		end
		
	 Convert:
		begin
				SDI_DataD = StoredPWData;
				// transition when counter <= 0
				if (Counter == 0) begin
					CounterBitsD = BitsPerSample-1;
					CounterD = SampleRate;
					CSregD = 0;
					SCKD = 0;
					NextState = Talk0;
				end
				else begin
					CounterD = Counter - 1;
					NextState = ConvertWait;
				end
		end
		
	 ConvertWait:
		begin
			// transition when counter <= 0
			if (Counter == 0) begin
				CounterBitsD = BitsPerSample-1;
				CounterD = SampleRate;
				CSregD = 0;
				SCKD = 0;
				NextState = Talk0;
			end
			else begin
				CounterD = Counter - 1;
			end
		end

	 Talk0:
		begin
			// write SDI bit i
			SDID = SDI_Data[CounterBits];
			CounterD = Counter - 1;
			NextState = Talk1;
		end
		
	 Talk1:
		begin
			// nothing
			CounterD = Counter - 1;
			NextState = Talk2;
		end
	 
	 Talk2:
		begin
			// set SCK high
			SCKD = 1;
			CounterD = Counter - 1;
			NextState = Talk3;
		end
	 
	 Talk3:
		begin
			// nothing
			CounterD = Counter - 1;
			NextState = Talk4;
		end
	 
	 Talk4:
		begin
			// read SDO bit i
			SDO_DataD[CounterBits] = StoredSDO;
			CounterD = Counter - 1;
			NextState = Talk5;
		end
		
	 Talk5:
		begin
			// set SCK low
			SCKD = 0;
			if (CounterBits > 0) begin
				CounterBitsD = CounterBits - 1;
				CounterD = Counter - 1;
				NextState = Talk0;
			end
			else begin // get out of Talk
				ReadyD = 1;
				CSregD = 1;
				CounterD = Counter - 1;
				NextState = ConvertReady;
			end
		end
  endcase
end

// Synchronous Block
always @ (posedge Clk)
begin
  if (~Reset_ || StoredPWData[30] == 1)
  begin
    CurrState <= Init;
	 StoredPWData <= 0;
	 StoredSDO <= 0;
	 SampleRate <= 0;
	 BitsPerSample <= 0;
	 SCKreg <= 0;
	 CSreg <= 1;
	 SDIreg <= 0;
	 Ready <= 1;
	 Enabled <= 0;
	 Counter <= 1;
	 
	 SDO_Data <= 0;
	 SDI_Data <= 0;
  end
  else
  begin
    CurrState <= NextState ;
	 StoredPWData <= StoredPWDataD ;
	 StoredSDO <= SDO;
	 SampleRate <= SampleRateD;
	 BitsPerSample <= BitsPerSampleD;
	 SCKreg <= SCKD;
	 CSreg <= CSregD;
	 SDIreg <= SDID;
	 Ready <= ReadyD;
	 Enabled <= EnabledD;
	 Counter <= CounterD;
	 CounterBits <= CounterBitsD;
	 SDO_Data <= SDO_DataD;
	 SDI_Data <= SDI_DataD;
  end
end

endmodule
