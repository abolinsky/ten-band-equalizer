// ram.v
// Instantiate a Ram of MaxAddr x DataWidth
// From xst.pdr/Chapter2 - RAM/ROMs / 
// Single Port RAM with Asynchronous Read
// Uses Distributed RAM only

`resetall
`timescale 1ns/10ps

module RAM (Clk, Wr, Addr, RAMIn, RAMOut);
parameter AddrWidth = 9, DataWidth = 16, MaxAddr = 511 ;
input Clk;
input Wr;
input [AddrWidth-1:0] Addr;
input [DataWidth-1:0] RAMIn;
output [DataWidth-1:0] RAMOut;
reg [DataWidth-1:0] mem [0:MaxAddr];

always @(posedge Clk)
begin
  if (Wr)
    mem[Addr] <= RAMIn;
end

assign RAMOut = mem[Addr];

endmodule
