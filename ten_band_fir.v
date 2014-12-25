`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    16:28:08 11/07/2014
// Design Name:
// Module Name:    ten_band_fir
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module ten_band_fir(
	 	input Reset_,
		input Clk,
		input PSel,
		input PEnable,
		input PWrite,
		input [31:0] PAddr,
		input [31:0] PWData,
	 	input signed [15:0] BandOneData,
	 	input signed [15:0] BandTwoData,
	 	input signed [15:0] BandThreeData,
	 	input signed [15:0] BandFourData,
	 	input signed [15:0] BandFiveData,
	 	input signed [15:0] BandSixData,
	 	input signed [15:0] BandSevenData,
	 	input signed [15:0] BandEightData,
	 	input signed [15:0] BandNineData,
	 	input signed [15:0] BandTenData,
		input [1:0] RAMEnable,
		output [31:0] PRData,
		output [15:0] LeftSample, RightSample, Sample,
		output reg RAMXWr
	 	);

// Signals
reg Enable_1;
reg Enable_2;
reg Enable_3;
reg Enable_4;
reg Enable_5;
reg Enable_6;
reg Enable_7;
reg Enable_8;
reg Enable_9;
reg Enable_10;

wire signed [31:0] PRData_1;
wire signed [31:0] PRData_2;
wire signed [31:0] PRData_3;
wire signed [31:0] PRData_4;
wire signed [31:0] PRData_5;
wire signed [31:0] PRData_6;
wire signed [31:0] PRData_7;
wire signed [31:0] PRData_8;
wire signed [31:0] PRData_9;
wire signed [31:0] PRData_10;

reg [15:0] SampleOut;
wire [15:0] LeftSampleOut, RightSampleOut;
wire LeftXWr, RightXWr;

wire Write;
wire Reset;

// State encoding
parameter TakeIn = 0;

// Registers
reg [31:0] Added_Filter_Components, Added_Filter_ComponentsD;
reg CurrState, NextState;
reg [31:0] DataOut, DataOutD;

// Combinational Logic
assign Write = PEnable & PSel & PWrite;
assign PRData = DataOut;
assign Reset = ~Reset_;
assign Sample = SampleOut;
assign RightSample = RightSampleOut;
assign LeftSample = LeftSampleOut;


// Combinational Block
always @ * begin

	// Default Behavior
	NextState = CurrState;
	Enable_1 = 0;
	Enable_2 = 0;
	Enable_3 = 0;
	Enable_4 = 0;
	Enable_5 = 0;
	Enable_6 = 0;
	Enable_7 = 0;
	Enable_8 = 0;
	Enable_9 = 0;
	Enable_10 = 0;
	Added_Filter_ComponentsD[31] = 0;
	Added_Filter_ComponentsD[30:0] = Added_Filter_Components[30:0];
	DataOutD[31] = 0;
	DataOutD[30:0] = DataOut[30:0];

	case (CurrState)

		TakeIn: begin

			// DEMUXING PWDATA TO EACH/ALL FIR MODULES
			if (Write == 1 && PAddr[11:0] >= 'he10 && PAddr[11:0] <= 'heb0) begin // STAY IN TakeIn UNLESS THE ADDRESSES BELOW ARE SPECIFIED
				
				case (PAddr[11:0])
					'he10:	begin Enable_1 = 1; 	end
					'he20:	begin Enable_2 = 1; 	end
					'he30:	begin Enable_3 = 1; 	end
					'he40:	begin Enable_4 = 1; 	end
					'he50:	begin Enable_5 = 1; 	end
					'he60:	begin Enable_6 = 1; 	end
					'he70:	begin Enable_7 = 1; 	end
					'he80:	begin Enable_8 = 1; 	end
					'he90:	begin Enable_9 = 1; 	end
					'hea0:	begin Enable_10 = 1;  end
					'heb0:	begin // enable all
									Enable_1 = 1;
									Enable_2 = 1;
									Enable_3 = 1;
									Enable_4 = 1;
									Enable_5 = 1;
									//Enable_6 = 1;
									//Enable_7 = 1;
									//Enable_8 = 1;
									//Enable_9 = 1;
									//Enable_10 = 1;
								end
				default:		begin
									Enable_1 = 0;
									Enable_2 = 0;
									Enable_3 = 0;
									Enable_4 = 0;
									Enable_5 = 0;
									Enable_6 = 0;
									Enable_7 = 0;
									Enable_8 = 0;
									Enable_9 = 0;
									Enable_10 = 0;
								end
				endcase
			end
			
			// send ready bit corresponding only to filter that is specified by address
			case (PAddr[11:0])
					'he10:	begin 
						if (PRData_1[31] == 1) begin
							DataOutD[31] = 1;
						end
					end
					'he20:	begin 
						if (PRData_2[31] == 1) begin
							DataOutD[31] = 1;
						end
					end
					'he30:	begin 
						if (PRData_3[31] == 1) begin
							DataOutD[31] = 1;
						end
					end
					'he40:	begin 
						if (PRData_4[31] == 1) begin
							DataOutD[31] = 1;
						end
					end
					'he50:	begin 
						if (PRData_5[31] == 1) begin
							DataOutD[31] = 1;
						end
					end
					'he60:	begin 
						if (PRData_6[31] == 1) begin
							DataOutD[31] = 1;
						end
					end
					'he70:	begin 
						if (PRData_7[31] == 1) begin
							DataOutD[31] = 1;
						end
					end
					'he80:	begin 
						if (PRData_8[31] == 1) begin
							DataOutD[31] = 1;
						end
					end
					'he90:	begin 
						if (PRData_9[31] == 1) begin
							DataOutD[31] = 1;
						end
					end
					'hea0:	begin 
						if (PRData_10[31] == 1) begin
							DataOutD[31] = 1;
						end
					end
					default: begin
						DataOutD[31] = 0;
					end
			endcase
			
			if (Added_Filter_Components[31] == 1) begin
				DataOutD = Added_Filter_Components;
				NextState = TakeIn;
			end
		end
	endcase

	// SUMMING ALL FILTER OUTPUTS WHEN ALL ARE READY AND STORING THE RESULT IN A REGISTER
	if (PRData_1[31] & PRData_2[31] & PRData_3[31] & PRData_4[31] & PRData_5[31])
		 //& PRData_6[31] & PRData_7[31] & PRData_8[31] & PRData_9[31] & PRData_10[31]) 
		 begin
		Added_Filter_ComponentsD[31] = 1;
		//five band implementation.  uncomment line 220 for 10band.
		Added_Filter_ComponentsD[15:0] = 
					PRData_1[15:0] + PRData_2[15:0] + PRData_3[15:0] + PRData_4[15:0] + PRData_5[15:0];
					//+ PRData_6[15:0] + PRData_7[15:0] + PRData_8[15:0] + PRData_9[15:0] + PRData_10[15:0];
	end
	
	if (RAMEnable[1:0] == 'b01) begin
		SampleOut = LeftSampleOut;
		RAMXWr = LeftXWr;
	end
	//else if (~RAMEnable) begin
	else if (RAMEnable[1:0] == 'b10) begin
		SampleOut = RightSampleOut;
		RAMXWr = RightXWr;
	end
	else begin
		SampleOut = 0;
		RAMXWr = 0;
	end
end

// Synchronous Block
always @ (posedge Clk) begin

	if (Reset) begin
		CurrState <= TakeIn;
		Added_Filter_Components <= 0;
		DataOut <= 0;
	end

	else begin
		CurrState <= NextState;
		Added_Filter_Components <= Added_Filter_ComponentsD;
		DataOut <= DataOutD;
	end
end

XArray XLeft (
    .PSel(PSel), 
    .PEnable(PEnable), 
    .PWrite(PWrite), 
    .PWData(PWData), 
    .Reset_(Reset_), 
    .Clk(Clk), 
    .Enable(RAMEnable), 
    .SampleOut(LeftSampleOut),
	 .RAMXWr(LeftXWr)
    );

XArray XRight (
    .PSel(PSel), 
    .PEnable(PEnable), 
    .PWrite(PWrite), 
    .PWData(PWData), 
    .Reset_(Reset_), 
    .Clk(Clk), 
    .Enable(~RAMEnable), 
    .SampleOut(RightSampleOut),
	 .RAMXWr(RightXWr)
    );

fir_perif band_one (
    .Reset_(Reset_),
    .Clk(Clk),
    .PSel(PSel),
    .PEnable(PEnable),
    .PWrite(PWrite),
    .ModuleEnable(Enable_1),
    .AttenuationIn(BandOneData),
	 .XIn(SampleOut),
    .PWData(PWData),
    .PRData(PRData_1)
    );

fir_perif band_two (
    .Reset_(Reset_),
    .Clk(Clk),
    .PSel(PSel),
    .PEnable(PEnable),
    .PWrite(PWrite),
    .ModuleEnable(Enable_2),
    .AttenuationIn(BandTwoData),
	 .XIn(SampleOut),
    .PWData(PWData),
    .PRData(PRData_2)
    );

fir_perif band_three (
    .Reset_(Reset_),
    .Clk(Clk),
    .PSel(PSel),
    .PEnable(PEnable),
    .PWrite(PWrite),
    .ModuleEnable(Enable_3),
    .AttenuationIn(BandThreeData),
	 .XIn(SampleOut),
    .PWData(PWData),
    .PRData(PRData_3)
    );

fir_perif band_four (
    .Reset_(Reset_),
    .Clk(Clk),
    .PSel(PSel),
    .PEnable(PEnable),
    .PWrite(PWrite),
    .ModuleEnable(Enable_4),
    .AttenuationIn(BandFourData),
	 .XIn(SampleOut),
    .PWData(PWData),
    .PRData(PRData_4)
    );

fir_perif band_five (
    .Reset_(Reset_),
    .Clk(Clk),
    .PSel(PSel),
    .PEnable(PEnable),
    .PWrite(PWrite),
    .ModuleEnable(Enable_5),
    .AttenuationIn(BandFiveData),
	 .XIn(SampleOut),
    .PWData(PWData),
    .PRData(PRData_5)
    );

fir_perif band_six (
    .Reset_(Reset_),
    .Clk(Clk),
    .PSel(PSel),
    .PEnable(PEnable),
    .PWrite(PWrite),
    .ModuleEnable(Enable_6),
    .AttenuationIn(BandSixData),
	 .XIn(SampleOut),
    .PWData(PWData),
    .PRData(PRData_6)
    );

fir_perif band_seven (
    .Reset_(Reset_),
    .Clk(Clk),
    .PSel(PSel),
    .PEnable(PEnable),
    .PWrite(PWrite),
    .ModuleEnable(Enable_7),
    .AttenuationIn(BandSevenData),
	 .XIn(SampleOut),
    .PWData(PWData),
    .PRData(PRData_7)
    );

fir_perif band_eight (
    .Reset_(Reset_),
    .Clk(Clk),
    .PSel(PSel),
    .PEnable(PEnable),
    .PWrite(PWrite),
    .ModuleEnable(Enable_8),
    .AttenuationIn(BandEightData),
	 .XIn(SampleOut),
    .PWData(PWData),
    .PRData(PRData_8)
    );

fir_perif band_nine (
    .Reset_(Reset_),
    .Clk(Clk),
    .PSel(PSel),
    .PEnable(PEnable),
    .PWrite(PWrite),
    .ModuleEnable(Enable_9),
    .AttenuationIn(BandNineData),
	 .XIn(SampleOut),
    .PWData(PWData),
    .PRData(PRData_9)
    );

fir_perif band_ten (
    .Reset_(Reset_),
    .Clk(Clk),
    .PSel(PSel),
    .PEnable(PEnable),
    .PWrite(PWrite),
    .ModuleEnable(Enable_10),
    .AttenuationIn(BandTenData),
	 .XIn(SampleOut),
    .PWData(PWData),
    .PRData(PRData_10)
    );

endmodule
