`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//Written/designed by Alex Bolinsky - ahbolinsky@gmail.com
//
// CSE 465 - project 2
//////////////////////////////////////////////////////////////////////////////////
module fir_perif(
    input PSel,
    input PEnable,
    input PWrite,
    input [31:0] PWData,
    input Reset_,
    input Clk,
	 input ModuleEnable,
	 input [15:0] AttenuationIn,
	 input signed [15:0] XIn,
    output signed [31:0] PRData
    );

parameter RAMWidth = 16, TapsBits = 9, RAMAddrMax = 511, maxTaps = 281;

// Signals
wire LeonWrite, Reset;
wire signed[RAMWidth-1:0] HOut;
reg signed[RAMWidth-1:0] HIn;
reg HWr;
reg Ready;
reg bing, bingD;

// State encoding
parameter Init = 0,			
          Idle = 1,
			 ParseControl = 2,
			 SetTaps = 3,
			 SetCoeff = 4,
			 SetAtten = 5,
			 ConvolveA = 6,
			 ConvolveB = 7,
			 ConvolveC = 8;
          
// Registers
reg [3:0] CurrState, NextState ;
reg [31:0] StoredPWData, StoredPWDataR;
reg [TapsBits-1:0] NumTaps, NumTapsR, CounterH, CounterHR;
reg signed [31:0] StoredDotProd, StoredDotProdR;
reg signed [15:0] StoredAttenuation, StoredAttenuationR;
reg signed [31:0] Multiplier;
reg signed [15:0] StoredDotProd1_15D, StoredDotProd1_15 ;

// Combinational Logic
assign LeonWrite = PSel & PEnable & PWrite & ModuleEnable;
assign Reset = ~Reset_;
assign PRData[31] = Ready;
assign PRData[30:RAMWidth] = 0;
assign PRData[RAMWidth-1:0] = StoredDotProd[30:RAMWidth-1];  // rounding 2.30 to 1.15

// Instantiate RAM blocks
RAM #(TapsBits,RAMWidth,RAMAddrMax) hArray(Clk,HWr,CounterH,HIn,HOut) ;

// Combinational block for fsm
always @ *
begin

// Default behavior
	HWr = 0;
	HIn = 0;
	NextState = CurrState;
	StoredPWDataR = StoredPWData;
	StoredDotProdR = StoredDotProd;
	StoredAttenuationR = StoredAttenuation;
	NumTapsR = NumTaps;
	Ready = 0;
	CounterHR = CounterH;
	bingD = bing;
	StoredDotProd1_15D = StoredDotProd1_15;
  
// Next State definitions
  case (CurrState) 
    Init: 
		begin
      NextState = Idle;
		end
	 
    Idle:
		begin
		Ready = 1;
		bingD = 0;
		
		// Wait for Leon to write to peripheral
		if(LeonWrite)
			begin
			NextState = ParseControl;
			StoredPWDataR = PWData;
			end
		end
	 
	 ParseControl:
		begin
	   if(StoredPWData[2:0] == 0)  
			begin
				NextState = SetTaps;
			end
		else if(StoredPWData[2:0] == 1)
			begin
				NextState = SetCoeff;
			end
		else if(StoredPWData[2:0] == 2)
			begin
				NextState = SetAtten;
			end
		else if(StoredPWData[2:0] == 3)
			begin
				NextState = ConvolveA;
			end
		else
			begin
				NextState = Idle;
			end
		end
	 
	 SetTaps:
		begin
			NumTapsR = StoredPWData[11:3];
			NextState = Idle;
		end
	 
	 SetCoeff:
		begin
			// set some coeff's
			HWr = 1;
			HIn = StoredPWData[18:3];
			CounterHR = CounterH + 1;
			
			if (CounterH == NumTaps - 1)
			begin
			CounterHR = 0;
			end
			
			NextState = Idle;
		end
	 
	 SetAtten:
		begin
			StoredAttenuationR = AttenuationIn;
			NextState = Idle;
		end
	 
	 ConvolveA:
	   begin
			StoredDotProdR = 0; 			//reset dot prod
			NextState = ConvolveB;
		end
		
	 ConvolveB:
		begin
			// Do MAC
			StoredDotProdR = StoredDotProd + (XIn * HOut);
			
			CounterHR = CounterH + 1;
			
			if(CounterH == NumTaps - 1)
				begin														
					CounterHR = 0;
					//StoredDotProdR = StoredDotProd * StoredAttenuation;
					//StoredDotProdR = (StoredDotProd >>> 16) & 'h0000FFFF;
					NextState = ConvolveC;
				end
		end
		
	ConvolveC:
		begin
			if (StoredAttenuation[15] == 0) begin
				StoredDotProd1_15D = StoredDotProd[30:15] ;
				StoredDotProdR = StoredDotProd1_15 * StoredAttenuation; // / 'b0000000000000010;// * 'b0111111111111111; //[31:16] * StoredAttenuation;//[31:16];// * StoredAttenuation;
				bingD = 1;
			end 
			//else if (StoredAttenuation[15] == 1) begin
			else begin
				StoredDotProd1_15D = StoredDotProd[30:15] ;
				StoredDotProdR = StoredDotProd + 'h8000;
			end	
			NextState = Idle;
		end
		
    default: // Recovery state if you ever get lost
    begin
      NextState = Init;
    end
  endcase
end

// Clock block for fsm
always @ (posedge Clk)
begin
  if (Reset)
  begin
	 CounterH <= 0;
	 CurrState <= Init;
	 StoredPWData <= 0;
	 NumTaps <= 163; // change back to 279
	 StoredDotProd <= 0;
	 StoredAttenuation <= 'h8000;
	 //StoredAttenuation <= 'h4000; this is for 0.5 attenuation factor
	 Multiplier <= 0;
	 StoredDotProd1_15 <= 0;
  end
  else
  begin
	 CounterH <= CounterHR;
    CurrState <= NextState ;
	 StoredPWData <= StoredPWDataR ;
	 NumTaps <= NumTapsR;
	 StoredDotProd <= StoredDotProdR;
	 StoredAttenuation <= StoredAttenuationR;
	 StoredDotProd1_15 <= StoredDotProd1_15D;
	 bing <= bingD;
	if (CurrState == ConvolveB) begin
		Multiplier <= XIn * HOut;
	end
	else if (CurrState == ConvolveC) begin
		Multiplier <= StoredDotProd[31:16] * StoredAttenuation;
	end
	else begin
		Multiplier <= 0;
	end
  end
end

endmodule
