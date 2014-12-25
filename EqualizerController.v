`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:59:34 11/16/2014 
// Design Name: 
// Module Name:    EqualizerController 
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module EqualizerController(
    input Reset_,
    input Clk,
    input PSel,
    input PEnable,
    input PWrite,
    input [31:0] PAddr,
    input [31:0] PWData,
    input [31:0] DSPIn,
    input [31:0] ADCIn,
	 input [31:0] DACIn,
	 output [31:0] PRData,
    output reg ECSel12,
    output reg ECSel13,
    output reg ECSel14,
    output reg ECEnable,
    output reg ECWrite,
    output reg [31:0] ECAddr,
    output reg [31:0] ECData,
    output signed [15:0] BandOne,
    output signed [15:0] BandTwo,
    output signed [15:0] BandThree,
    output signed [15:0] BandFour,
    output signed [15:0] BandFive,
    output signed [15:0] BandSix,
    output signed [15:0] BandSeven,
    output signed [15:0] BandEight,
    output signed [15:0] BandNine,
    output signed [15:0] BandTen,
	 output reg [1:0] RAMEnable,
	 output ECOn
    );

// Signals
wire LeonWrite;		// PSel & PEnable & PWrite
reg AttenuationOut;	// Latches out attenuation factor to DSP

// Registers
reg [3:0] CurrentState, NextState;
reg ECControl, ECControlD;
reg signed [31:0] StoredADCIn, StoredADCInD;	
reg [31:0] StoredDACIn, StoredDACInD; 
reg [31:0] StoredDSPIn, StoredDSPInD; 

// 			  || Buffer in ||         || Buffer out ||
reg [15:0] BufferIn1, BufferIn1D, BufferOut1, BufferOut1D;
reg [15:0] BufferIn2, BufferIn2D, BufferOut2, BufferOut2D;
reg [15:0] BufferIn3, BufferIn3D, BufferOut3, BufferOut3D;
reg [15:0] BufferIn4, BufferIn4D, BufferOut4, BufferOut4D;
reg [15:0] BufferIn5, BufferIn5D, BufferOut5, BufferOut5D;
reg [15:0] BufferIn6, BufferIn6D, BufferOut6, BufferOut6D;
reg [15:0] BufferIn7, BufferIn7D, BufferOut7, BufferOut7D;
reg [15:0] BufferIn8, BufferIn8D, BufferOut8, BufferOut8D;
reg [15:0] BufferIn9, BufferIn9D, BufferOut9, BufferOut9D;
reg [15:0] BufferIn10, BufferIn10D, BufferOut10, BufferOut10D;

// Assigns
assign LeonWrite = PSel & PEnable & PWrite;
assign BandOne = BufferOut1;
assign BandTwo = BufferOut2;
assign BandThree = BufferOut3;
assign BandFour = BufferOut4;
assign BandFive = BufferOut5;
assign BandSix = BufferOut6;
assign BandSeven = BufferOut7;
assign BandEight = BufferOut8;
assign BandNine = BufferOut9;
assign BandTen = BufferOut10;
assign ECOn = ECControl;
assign PRData[31] = 0;
assign PRData[30] = ECControl;
assign PRData[29:27] = CurrentState;
assign PRData[26:16] = 0;
assign PRData[15:0] = StoredDSPIn[15:0];

// State Machine States
parameter 	Init = 0, 
				Request_ADC_Left = 1,
				Send_ADC_Left_To_DSP = 2,
				Send_DSP_To_DAC_Left = 3,
				Request_ADC_Right = 4,
				Send_ADC_Right_To_DSP = 5,
				Send_DSP_To_DAC_Right = 6,
				Disable_DAC_ADC = 7,
				Enable_DAC = 8,
				Enable_ADC = 9,
				DAC_Fast = 10;

// Combinational Block
always @ * begin
	
	// Default Statements
	NextState = CurrentState;
	ECSel12 = 0;
	ECSel13 = 0;
	ECSel14 = 0;
	ECEnable = 0;
	ECWrite = 0;
	ECData = 'hBEEF;
	ECAddr = 0;
	ECControlD = ECControl;
	StoredADCInD = StoredADCIn;
	StoredDACInD = StoredDACIn;
	StoredDSPInD = StoredDSPIn;
	RAMEnable = 'b01;
	
	// Pass Control to EC or leave Control with APB
	if (PWData[31:16] == 'h4F46) begin // Hex 'OF'
		ECControlD = 0;
	end
	else if (PWData[31:16] == 'h4F4E || ECControl == 1) begin // Hex 'ON'
		ECControlD = 1;
	end
	else begin
		ECControlD = 0;
	end
	
	// State Machine
	case (CurrentState) 
    
	 Disable_DAC_ADC: begin	// State 0
		if (ECControl == 1) begin
			ECSel12 = 1;
			ECSel13 = 1;
			ECWrite = 1;
			ECEnable = 1;
			ECData = 'h40000000;
			NextState = Enable_DAC;
		end
	 end
	 
	 Enable_DAC: begin
		StoredADCInD = ADCIn;
		if (StoredADCIn[31]) begin
			ECSel13 = 1;
			ECWrite = 1;
			ECEnable = 1;
			ECData = 'h80002578;
			NextState = Enable_ADC;
		end
	 end
	 
	 Enable_ADC: begin
		StoredADCInD = ADCIn;
		if (StoredADCIn[31]) begin
			ECSel12 = 1;
			ECWrite = 1;
			ECEnable = 1;
			ECData = 'h80002570;
			NextState = DAC_Fast;
		end
	 end
	 
	 DAC_Fast: begin
		StoredDACInD = DACIn;
		if (StoredDACIn[31]) begin
			ECSel13 = 1;
			ECWrite = 1;
			ECEnable = 1;
			ECData = 'h5F0000;
			RAMEnable = 'b01;
			NextState = Request_ADC_Left;
		end
	 end
	 
	 Request_ADC_Left: begin	// State 1
			ECSel12 = 1;	// Select ADC
			ECEnable = 1;
			ECWrite = 1;
			ECData[15:0] = 'h8000;
			StoredDSPInD = DSPIn;
			StoredADCInD = ADCIn;
			RAMEnable = 'b01;
			if (StoredADCIn[31]) begin
				NextState = Send_ADC_Left_To_DSP;
			end
	 end
	 
	 Send_ADC_Left_To_DSP: begin	// State 2
		ECSel14 = 1;	// Select DSP
		ECEnable = 1;
		ECWrite = 1;
		ECData[18:3] = StoredADCIn[15:0];
		ECData[2:0] = 'b011;		// Set op code to convolve
		ECAddr = 'h80000eb0;
		RAMEnable = 'b01;
		StoredDSPInD = DSPIn;
		if (StoredDSPIn[31]) begin
			RAMEnable = 'b10;
			NextState = Send_DSP_To_DAC_Left;
		end
	 end
	 
	 Send_DSP_To_DAC_Left: begin	// State 3
		ECSel13 = 1;
		ECEnable = 1;
		ECWrite = 1;
		ECData[23:16] = 'h30;	// Select Channel 0
		ECData[15:0] = StoredDSPIn[15:0];
		RAMEnable = 'b10;
		StoredDSPInD = DSPIn;
		StoredDACInD = DACIn;
		if (StoredDACIn[31] == 1) begin
			NextState = Request_ADC_Right;
		end
	 end
	 
	 Request_ADC_Right: begin	// State 4
		ECSel12 = 1;		// Select ADC
		ECEnable = 1;
		ECWrite = 1;
		ECData[15:0] = 'hc000;
		RAMEnable = 'b10;
		StoredDSPInD = DSPIn;
		StoredADCInD = ADCIn;
		if (StoredADCIn[31]) begin
			NextState = Send_ADC_Right_To_DSP;
		end
	 end
		
	 Send_ADC_Right_To_DSP: begin	// State 5
		ECSel14 = 1;		// Select DSP
		ECEnable = 1;
		ECWrite = 1;
		ECData[18:3] = StoredADCIn[15:0];
		ECData[2:0] = 'b011;		// Set op code to convolve
		ECAddr = 'h80000eb0;
		RAMEnable = 'b10;
		StoredDSPInD = DSPIn;
		if (StoredDSPIn[31] == 1) begin	
			RAMEnable = 'b01;
			NextState = Send_DSP_To_DAC_Right;
		end
	 end
	 
	 Send_DSP_To_DAC_Right: begin	// State 6
		ECSel13 = 1;
		ECEnable = 1;
		ECWrite = 1;
		ECData[23:16] = 'h31;	// Select Channel 1
		ECData[15:0] = StoredDSPIn[15:0];
		StoredDSPInD = DSPIn;
		StoredDACInD = DACIn;
		RAMEnable = 'b01;
		if (StoredDACIn[31] == 1) begin
			NextState = Request_ADC_Left;
		end
		/*
		else begin	// If not ready, use this available time to quickly set attenuation factors
			if (StoredDSPIn[31] == 1) begin
				ECSel14 = 1;
				ECEnable = 1;
				ECWrite = 1;
				ECAddr = 'heb0;
				ECData = 'h2;	// OP code for set attenuation factor
			end
		end
		*/
	 end
	 
	 default: begin
		NextState = CurrentState;
	 end
	endcase
end

// Synchronous Block
always @ (posedge Clk) begin
	if (~Reset_) begin
		CurrentState <= Disable_DAC_ADC;	
		ECControl <= 0;
		AttenuationOut <= 1;
		BufferIn1 <= 'h8000;
		BufferIn2 <= 'h8000;
		BufferIn3 <= 'h8000;
		BufferIn4 <= 'h8000;
		BufferIn5 <= 'h8000;
		BufferIn6 <= 'h8000;
		BufferIn7 <= 'h8000;
		BufferIn8 <= 'h8000;
		BufferIn9 <= 'h8000;
		BufferIn10 <= 'h8000;
	end
	else begin
		CurrentState <= NextState;
		StoredDACIn <= StoredDACInD;
		StoredADCIn <= StoredADCInD;
		StoredDSPIn <= StoredDSPInD;
		ECControl <= ECControlD;
		
		BufferIn1 <= BufferIn1D;
		BufferIn2 <= BufferIn2D;
		BufferIn3 <= BufferIn3D;
		BufferIn4 <= BufferIn4D;
		BufferIn5 <= BufferIn5D;
		BufferIn6 <= BufferIn6D;
		BufferIn7 <= BufferIn7D;
		BufferIn8 <= BufferIn8D;
		BufferIn9 <= BufferIn9D;
		BufferIn10 <= BufferIn10D;
	
		BufferOut1 <= BufferOut1D;
		BufferOut2 <= BufferOut2D;
		BufferOut3 <= BufferOut3D;
		BufferOut4 <= BufferOut4D;
		BufferOut5 <= BufferOut5D;
		BufferOut6 <= BufferOut6D;
		BufferOut7 <= BufferOut7D;
		BufferOut8 <= BufferOut8D;
		BufferOut9 <= BufferOut9D;
		BufferOut10 <= BufferOut10D;
			
		// Default values
		AttenuationOut <= 0;
			
		BufferIn1D <= BufferIn1;
		BufferIn2D <= BufferIn2;
		BufferIn3D <= BufferIn3;
		BufferIn4D <= BufferIn4;
		BufferIn5D <= BufferIn5;
		BufferIn6D <= BufferIn6;
		BufferIn7D <= BufferIn7;
		BufferIn8D <= BufferIn8;
		BufferIn9D <= BufferIn9;
		BufferIn10D <= BufferIn10;
		
		BufferOut1D <= BufferOut1;
		BufferOut2D <= BufferOut2;
		BufferOut3D <= BufferOut3;
		BufferOut4D <= BufferOut4;
		BufferOut5D <= BufferOut5;
		BufferOut6D <= BufferOut6;
		BufferOut7D <= BufferOut7;
		BufferOut8D <= BufferOut8;
		BufferOut9D <= BufferOut9;
		BufferOut10D <= BufferOut10;
		
		// Select one of 10 registers to store attenuation factors sent from Leon
		// Once address 'hb is targeted, assert signal to latch all values into the next buffer
		case (PAddr[11:0])
			'h810:	begin 
				BufferIn1D 		<= PWData[15:0]; 	
			end
			'h820:	begin 
				BufferIn2D 		<= PWData[15:0]; 	
			end
			'h830:	begin 
				BufferIn3D 		<= PWData[15:0]; 	
			end
			'h840:	begin 
				BufferIn4D 		<= PWData[15:0]; 	
			end
			'h850:	begin 
				BufferIn5D 		<= PWData[15:0]; 	
			end
			'h860:	begin 
				BufferIn6D 		<= PWData[15:0]; 	
			end
			'h870:	begin 
				BufferIn7D 		<= PWData[15:0]; 	
			end
			'h880:	begin 
				BufferIn8D 		<= PWData[15:0]; 	
			end
			'h890:	begin 
				BufferIn9D 		<= PWData[15:0]; 	
			end
			'h8a0:	begin 
				BufferIn10D 	<= PWData[15:0]; 	
			end
			'h8b0:	begin 
				AttenuationOut <= 1; 
			end
			default: begin
			end
		endcase
	
		// When the AttenuationOut bit is set, latch all values into second buffer
		if (AttenuationOut == 1) begin
			BufferOut1D <= BufferIn1;
			BufferOut2D <= BufferIn2;
			BufferOut3D <= BufferIn3;
			BufferOut4D <= BufferIn4;
			BufferOut5D <= BufferIn5;
			BufferOut6D <= BufferIn6;
			BufferOut7D <= BufferIn7;
			BufferOut8D <= BufferIn8;
			BufferOut9D <= BufferIn9;
			BufferOut10D <= BufferIn10;
		end
	end
end

endmodule
