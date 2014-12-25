// Simulation model for an APB bus master for Leon3
// Call APBCycle task to generate APB bus cycles to simulate the APB portion of the Leon2
// ReadData stores PRDataX after a read.

`resetall
`timescale 1ns/10ps

module APBBusMaster(Clk,Reset_,PAddr,PWData,PEnable,PWrite,
	                  PSel8,PRData8,
	                  PSel10,PRData10,
                     PSel11,PRData11,
                     PSel12,PRData12,
                     PSel13,PRData13,
                     PSel14,PRData14) ;

parameter PAMAX = 32, PDMAX = 32, ClkPeriod_2 = 16.67, ClkPeriod = (ClkPeriod_2*2), READ=0, WRITE=1 ;

output Clk ;
output Reset_ ;
output [PAMAX-1:0] PAddr ;
output [PDMAX-1:0] PWData ;
output PEnable, PWrite ;
output PSel8, PSel10, PSel11, PSel12, PSel13, PSel14 ;
input [PDMAX-1:0] PRData8, PRData10, PRData11,PRData12,PRData13,PRData14 ; 

reg Reset_, Clk ;
reg [PAMAX-1:0] PAddr ;
reg [PDMAX-1:0] PWData ;
reg PEnable, PWrite ;
reg PSel8, PSel10, PSel11, PSel12, PSel13, PSel14 ;
wire [PDMAX-1:0] PRData8, PRData10, PRData11,PRData12,PRData13,PRData14 ; 

reg [PDMAX-1:0] ReadData, ReadDataD; // Stores data after a read cycle
integer i ;

reg[7:0] garbage;
reg[16:0] sampleRate;
reg[4:0] numBitsPerSampleADC, numBitsPerSampleDAC;
reg[7:0] eightBits;
reg[11:0] inputHeader;
reg signed [15:0] taps [278:0];
reg [15:0] InitXInputs [999:0];

// APB Bus Master
initial
begin
	// Initialize APB signals to 0
	PAddr = 0 ;
	PWData = 0 ;
   PEnable = 0 ;
   PWrite = 0 ;
   PSel8 = 0 ; PSel10 = 0 ; PSel11 = 0 ; PSel12 = 0 ; PSel13 = 0 ; PSel14 = 0 ;

	// Generate Reset_
	Reset_=0;
	#(ClkPeriod_2+5) Reset_ = 1 ; // De-Assert Reset_ 5 ns after 1st rising edge
	#(ClkPeriod*10) ;
  
	// Start your APB bus cycles here
	
	garbage = 0;
	eightBits = 0;
	sampleRate = 299;
	inputHeader[11:0] = 0;
	
	//////////////////////////////////////////////////////////////////////////
	// FIR FILTERS																				//
	//////////////////////////////////////////////////////////////////////////	
	
	/*
	
	// Set Attenuations																		//
	//////////////////////////////////////////////////////////////////////////
	
	// Write Cycle PSel8 EC - set attenuation for first band
	APBCycle (WRITE,'h80000810,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for second band
	APBCycle (WRITE,'h80000820,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for third band
	APBCycle (WRITE,'h80000830,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for fourth band
	APBCycle (WRITE,'h80000840,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for fifth band
	APBCycle (WRITE,'h80000850,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for sixth band
	APBCycle (WRITE,'h80000860,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for seventh band
	APBCycle (WRITE,'h80000870,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for eighth band
	APBCycle (WRITE,'h80000880,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for ninth band
	APBCycle (WRITE,'h80000890,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for tenth band
	APBCycle (WRITE,'h800008a0,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - send all attenuation bands at once
	APBCycle (WRITE,'h800008b0,{garbage,garbage,garbage,garbage}) ;
	// Write Cycle PSel14 DSP - latch in attenuations
	APBCycle (WRITE,'h80000eb0,{28'h0000000,1'b0,3'b010}) ;
	
	*/
	
	// Load Coefficients																		//
	//////////////////////////////////////////////////////////////////////////	
	
	//"FilterCoeffBand_5_1.txt" is for 5band implemntation.  
	//Use FilterCoeffBand1.tb for 10band implemntation. also, change
	//number of taps for 163.
	
	//$readmemh("FilterCoeffBand1.tb", taps);
	$readmemh("FilterCoeffBand_5_1.txt", taps);
	//for (i=0; i<279; i=i+1) begin
	for (i=0; i<163; i=i+1) begin
		APBCycle (WRITE,'h80000e10,{taps[i], 3'b001});
		APBCycle (READ,'h80000e10,0) ;
		while (PRData14[PDMAX-1] == 0) begin
			APBCycle (READ,'h80000e10,0);
		end
	end
	
	//$readmemh("FilterCoeffBand2.tb", taps);
	$readmemh("FilterCoeffBand_5_2.txt", taps);
	//for (i=0; i<279; i=i+1) begin
	for (i=0; i<163; i=i+1) begin
		APBCycle (WRITE,'h80000e20,{taps[i], 3'b001});
		APBCycle (READ,'h80000e20,0) ;
		while (PRData14[PDMAX-1] == 0) begin
			APBCycle (READ,'h80000e20,0);
		end
	end
	
	//$readmemh("FilterCoeffBand3.tb", taps);
	$readmemh("FilterCoeffBand_5_3.txt", taps);
	//for (i=0; i<279; i=i+1) begin
	for (i=0; i<163; i=i+1) begin
		APBCycle (WRITE,'h80000e30,{taps[i], 3'b001});
		APBCycle (READ,'h80000e30,0) ;
		while (PRData14[PDMAX-1] == 0) begin
			APBCycle (READ,'h80000e30,0);
		end
	end
	
	//$readmemh("FilterCoeffBand4.tb", taps);
	$readmemh("FilterCoeffBand_5_4.txt", taps);
	//for (i=0; i<279; i=i+1) begin
	for (i=0; i<163; i=i+1) begin
		APBCycle (WRITE,'h80000e40,{taps[i], 3'b001});
		APBCycle (READ,'h80000e40,0) ;
		while (PRData14[PDMAX-1] == 0) begin
			APBCycle (READ,'h80000e40,0);
		end
	end
	
	//$readmemh("FilterCoeffBand5.tb", taps);
	$readmemh("FilterCoeffBand_5_5.txt", taps);
	//for (i=0; i<279; i=i+1) begin
	for (i=0; i<163; i=i+1) begin
		APBCycle (WRITE,'h80000e50,{taps[i], 3'b001});
		APBCycle (READ,'h80000e50,0) ;
		while (PRData14[PDMAX-1] == 0) begin
			APBCycle (READ,'h80000e50,0);
		end
	end
	
	/* Uncomment this section for 10 band implementation 
	$readmemh("FilterCoeffBand6.tb", taps);
	for (i=0; i<279; i=i+1) begin
		APBCycle (WRITE,'h80000e60,{taps[i], 3'b001});
		APBCycle (READ,'h80000e60,0) ;
		while (PRData14[PDMAX-1] == 0) begin
			APBCycle (READ,'h80000e60,0);
		end
	end
	
	$readmemh("FilterCoeffBand7.tb", taps);
	for (i=0; i<279; i=i+1) begin
		APBCycle (WRITE,'h80000e70,{taps[i], 3'b001});
		APBCycle (READ,'h80000e70,0) ;
		while (PRData14[PDMAX-1] == 0) begin
			APBCycle (READ,'h80000e70,0);
		end
	end
	
	$readmemh("FilterCoeffBand8.tb", taps);
	for (i=0; i<279; i=i+1) begin
		APBCycle (WRITE,'h80000e80,{taps[i], 3'b001});
		APBCycle (READ,'h80000e80,0) ;
		while (PRData14[PDMAX-1] == 0) begin
			APBCycle (READ,'h80000e80,0);
		end
	end
	
	$readmemh("FilterCoeffBand9.tb", taps);
	for (i=0; i<279; i=i+1) begin
		APBCycle (WRITE,'h80000e90,{taps[i], 3'b001});
		APBCycle (READ,'h80000e90,0) ;
		while (PRData14[PDMAX-1] == 0) begin
			APBCycle (READ,'h80000e90,0);
		end
	end
	
	$readmemh("FilterCoeffBand10.tb", taps);
	for (i=0; i<279; i=i+1) begin
		APBCycle (WRITE,'h80000ea0,{taps[i], 3'b001});
		APBCycle (READ,'h80000ea0,0) ;
		while (PRData14[PDMAX-1] == 0) begin
			APBCycle (READ,'h80000ea0,0);
		end
	end
	*/
	
	// Turn EC On																				//
	//////////////////////////////////////////////////////////////////////////
	
	// Write Cycle PSel8 EC - turn equalizer controller on
	APBCycle (WRITE,'h80000800,{16'h4F4E,16'h0000}) ;
	
	#(ClkPeriod*100000) ;
	
	// Set Attenuations																		//
	//////////////////////////////////////////////////////////////////////////
	
	// Write Cycle PSel8 EC - set attenuation for first band
	APBCycle (WRITE,'h80000810,{garbage,garbage,16'b0000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for second band
	APBCycle (WRITE,'h80000820,{garbage,garbage,16'b0000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for third band
	APBCycle (WRITE,'h80000830,{garbage,garbage,16'b0000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for fourth band
	APBCycle (WRITE,'h80000840,{garbage,garbage,16'b1000000000000000}) ;
	// Write Cycle PSel8 EC - set attenuation for fifth band
	APBCycle (WRITE,'h80000850,{garbage,garbage,16'b0100000000000000}) ;
	// Write Cycle PSel8 EC - send all attenuation bands at once
	APBCycle (WRITE,'h800008b0,{garbage,garbage,garbage,garbage}) ;
	// Write Cycle PSel14 DSP - latch in attenuations
	APBCycle (WRITE,'h80000eb0,{28'h0000000,1'b0,3'b010}) ;
	
	#(ClkPeriod*100000) ;
	
	// Write Cycle PSel8 EC - turn equalizer controller off
	APBCycle (WRITE,'h80000800,{16'h4F46,16'h0000}) ;
	
	#(ClkPeriod*100) ;
	
	// End your APB Bus cycles here

	$stop ;
end


// Don't modify below here

// Generate 30 MHz clock
initial
	Clk = 0 ;

always
	#(ClkPeriod_2) Clk = ~Clk ; // 30 MHz Clock

always @ *
begin
	ReadDataD = 0 ;
	if (PSel8)
		ReadDataD <= PRData8 ;
	else if (PSel10)
		ReadDataD <= PRData10 ;
	else if (PSel11)
		ReadDataD <= PRData11 ;
	else if (PSel12)
		ReadDataD <= PRData12 ;
	else if (PSel13)
		ReadDataD <= PRData13 ;
	else if (PSel14)
		ReadDataD <= PRData14 ;
end

always @ (posedge Clk)
begin
	if (PEnable)
	begin
		ReadData <= ReadDataD ;
	end
end
task APBCycle ;
// Generates an APB bus cycle for APB Channels 8,10 - 14 depending on value of Address
// See http://classes.engineering.wustl.edu/cse465/Lectures/Lecture%202%20-%20AMBA%20APB%20Bus.pdf
// for details on the APB bus cycles
// For details on the decoding of the APB bus signals, see leon3mpAPB 
// for the constants that set apb_iobar.
// In this configuration, the APB devices are selected with PAddr[31:20] = 0x800
// and PAddr[19:8] = apb_iobar.address & apb_iobar.mask.
// Also, see grlib user manual  section 5.5

	input Write ;
	input [PAMAX-1:0] Address ;
	input [PDMAX-1:0] WriteData ;
	begin
		PEnable = 0 ; PWrite = 0 ; 
		PSel8 = 0 ; PSel10 = 0 ; PSel11 = 0  ;PSel12 = 0 ; PSel13 = 0 ; PSel14 = 0 ;
      PAddr[31:20] = 0 ;
		PAddr = {12'b0,Address[19:0]} ;
		PWData = 0 ;
		if (Write)
		begin
			PWData = WriteData ;
			PWrite = 1 ;
		end
		if (PAddr[19:8]==8)
		begin
			PSel8 = 1 ;
			#ClkPeriod ;
			PEnable = 1 ;
			#ClkPeriod ;
		end
		else if (PAddr[19:8]==10)
		begin
			PSel10 = 1 ;
			#ClkPeriod ;
			PEnable = 1 ;
			#ClkPeriod ;
		end
		else if (PAddr[19:8]==11)
		begin
			PSel11 = 1 ;
			#ClkPeriod ;
			PEnable = 1 ;
			#ClkPeriod ;
		end
		else if (PAddr[19:8]==12)
		begin
			PSel12 = 1 ;
			#ClkPeriod ;
			PEnable = 1 ;
			#ClkPeriod ;
		end
		else if (PAddr[19:8]==13)
		begin
			PSel13 = 1 ;
			#ClkPeriod ;
			PEnable = 1 ;
			#ClkPeriod ;
		end
		else if (PAddr[19:8]==14)
		begin
			PSel14 = 1 ;
			#ClkPeriod ;
			PEnable = 1 ;
			#ClkPeriod ;
		end
		PEnable = 0 ;
		PSel8 = 0 ; PSel10 = 0 ; PSel11 = 0 ;PSel12 = 0 ; PSel13 = 0 ; PSel14 = 0 ;
		PWrite = 0 ;
		PAddr = 0 ;
		PWData = 0 ;
	end
endtask

endmodule
