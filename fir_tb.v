// FSMLecture_tb.v
// Testbench for FSMLecture
`resetall
`timescale 1ns/10ps

module fir_tb() ;

parameter RAMWidth = 16, TapsBits = 9, RAMAddrWidth = 10, RAMAddrMax = 511, 
MaxTaps = 281, ClkPeriod_2 = 16.67, ClkPeriod = (ClkPeriod_2*2),
InitHFile = "hArray.tb", InitXFilePass = "xArrayPass.tb", InitXFileStop = "xArrayStop.tb" ;

reg Clk, Reset_, PWrite, PSel, PEnable ;
reg [31:0] PWData ;
reg InitRAM ;
wire [31:0] PRData ;

integer i ;
//// Array of values used to initialize RAM
reg signed [15:0] InitHInputs [60:0];
reg [15:0] InitXInputs [999:0];

// Instantiate DUT (Device Under Test)
fir_perif #(RAMWidth,TapsBits,RAMAddrMax,MaxTaps) U1 (
    .PSel(PSel), 
    .PEnable(PEnable), 
    .PWrite(PWrite), 
    .PWData(PWData), 
    .Reset_(Reset_), 
    .Clk(Clk), 
    .PRData(PRData)
    );

// Generate Clock
always
  #(ClkPeriod_2) Clk = ~Clk ; // 30 MHz Clock
  
initial
begin
 
   // Setup 
	Clk = 0;
	PWData = 0 ;
	PWrite = 0 ;
	PSel = 0 ;
	PEnable = 0 ;
	Reset_ = 0 ;
	#(ClkPeriod_2+5) Reset_ = 1 ; // De-Assert Reset_ after 1st rising edge
	#(ClkPeriod*10) ;

	// Set num taps
	PSel = 1;
	PEnable = 1;
	PWrite = 1;
	PWData[31:3] = 61;
	PWData[2] = 0;
	PWData[1] = 0;
	PWData[0] = 1;
	#(ClkPeriod*1) ;
	PSel = 0;
	PEnable = 0;
	PWrite = 0;
	while(!PRData[31])
		begin
			#(ClkPeriod);
		end
	
	// Set coeff	
	$readmemh(InitHFile,InitHInputs);
	for (i = 0; i < 61; i = i + 1)
	begin
		PSel = 1;
		PEnable = 1;
		PWrite = 1;
		PWData[31:19] = 0;
		PWData[18:3] = InitHInputs[i];
		PWData[2] = 0;
		PWData[1] = 1;
		PWData[0] = 0;
		$display("Initializing HArray to %d",PWData[18:3]) ;
		#(ClkPeriod*1) ;
		PSel = 0;
		PEnable = 0;
		PWrite = 0;
		while(!PRData[31])
			begin
				#(ClkPeriod);
			end
	end
	
	// Convolve
	$readmemh(InitXFilePass,InitXInputs);
	for (i = 0; i < 1000; i = i + 1)
	//for (i = 0; i < 32; i = i + 1)
	begin
		PSel = 1;
		PEnable = 1;
		PWrite = 1;
		PWData[31:19] = 0;
		PWData[18:3] = InitXInputs[i];
		PWData[2] = 1;
		PWData[1] = 0;
		PWData[0] = 0;
		//$display("Initializing XArray to %d",PWData[18:3]) ;
		#(ClkPeriod*1) ;
		PSel = 0;
		PEnable = 0;
		PWrite = 0;
		while(!PRData[31])
			begin
				#(ClkPeriod);
			end
		$display(PRData[15:0]) ;
	end
	
	
	$stop;

  // Loop 4 times, initializing RAM to a different value each iteration
//  for (i=0;i<4;i=i+1)
//  begin
//    RAMIn = InitRAMInputs[i] ; // Get new value for RAM initialization
//    $display("Initializing RAM to 0x%x",RAMIn) ; // Print to RAM value console
//    InitRAM = 1 ; // Start up FSM
//    #(ClkPeriod) InitRAM = 0 ;
//    // Wait until FSM is finished initializing the RAM
//    while (Busy)
//    begin
//      #(ClkPeriod) ;
//    end
//    #(ClkPeriod*10) ;
//  end
  
end  

endmodule

