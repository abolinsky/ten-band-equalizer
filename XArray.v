`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//Written/designed by Alex Bolinsky - ahbolinsky@gmail.com
//
// CSE 465 - project 4
//////////////////////////////////////////////////////////////////////////////////
module XArray(
    input PSel,
    input PEnable,
    input PWrite,
    input [31:0] PWData,
    input Reset_,
    input Clk,
	 input [1:0] Enable,
    output [15:0] SampleOut, 
	 output RAMXWr
    );

parameter RAMWidth = 16, TapsBits = 9, RAMAddrMax = 511, maxTaps = 281;

// Signals
wire LeonWrite, Reset;
wire signed[RAMWidth-1:0] XOut;
reg signed[RAMWidth-1:0] XIn;
reg XWr;
reg Ready;

// State encoding
parameter 	Init = 0,			
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
reg signed [31:0] StoredPWData, StoredPWDataR;
reg [TapsBits-1:0] NumTaps, NumTapsR, CounterH, CounterHR, CounterX, CounterXR;

// Combinational Logic
assign LeonWrite = PSel == 1 && PEnable == 1 && PWrite == 1 && (Enable == 'b01 || PWData[2:0] == 1 || PWData[2:0] == 0);
assign Reset = ~Reset_;
assign SampleOut = XOut;
assign RAMXWr = XWr;

// Instantiate RAM blocks
RAM #(TapsBits,RAMWidth,RAMAddrMax) xArray(Clk,XWr,CounterX,XIn,XOut) ;

// Combinational block for fsm
always @ *
begin

// Default behavior
	CounterHR = CounterH;
	XWr = 0;
	XIn = 0;
	NextState = CurrState;
	StoredPWDataR = StoredPWData;
	Ready = 0;
	CounterXR = CounterX;
	NumTapsR = NumTaps;
  
// Next State definitions
  case (CurrState) 
    Init: 
		begin
      NextState = Idle;
		end
	 
    Idle:
		begin
		Ready = 1;
		
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
		else if(StoredPWData[2:0] == 2 || StoredPWData[27:24] == 2)
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
			XWr = 1;
			XIn = 0;					
			CounterHR = CounterH + 1;
			CounterXR = CounterX + 1;
			if (CounterH == NumTaps - 1) begin
				CounterHR = 0;
			end
			if (CounterX == NumTaps - 1) begin
				CounterXR = 0;
			end
			NextState = Idle;
		end
	 
	 SetAtten:
		begin
			NextState = Idle;
		end
	 
	 ConvolveA:
	   begin
			XWr = 1;
			XIn = StoredPWData[18:3];
			NextState = ConvolveB;
			//$display("Xin: %h", XIn);
			
			//Write to old beginning, then +1 to get to new beginning value
			CounterXR = CounterX + 1;
			if(CounterX == NumTaps - 1) begin
				CounterXR = 0;
			end
		end
		
	 ConvolveB:
		begin
			CounterHR = CounterH + 1;
			CounterXR = CounterX + 1;
			if(CounterX == NumTaps - 1) begin
				CounterXR = 0;
			end
			if(CounterH == NumTaps - 1)
				begin														
					CounterHR = 0;
					
					//increment the X counter to point to old beginning
					CounterXR = CounterX + 1;
					if(CounterX == NumTaps - 1)
					begin
						CounterXR = 0;
					end
					
					NextState = ConvolveC;
				end
		end
	 
	 ConvolveC:
		begin
			NextState = Idle;
		end
	 
    default: begin // Recovery state if you ever get lost
		NextState = Init;
    end
  endcase
end

// Clock block for fsm
always @ (posedge Clk) begin
  if (Reset) begin
	 CounterH <= 0;
	 CounterX <= 0;
	 CurrState <= Init;
	 StoredPWData <= 0;
	 NumTaps <= 163; // change back to 279
  end
  else begin
	 CounterH <= CounterHR;
	 CounterX <= CounterXR;
    CurrState <= NextState ;
	 StoredPWData <= StoredPWDataR ;
	 NumTaps <= NumTapsR;
  end
end

endmodule