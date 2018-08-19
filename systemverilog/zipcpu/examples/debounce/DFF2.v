// 2 DFF synchronizer component with sync reset
module DFF2 
  (
   input  i_clk,
   input  i_rstn,
   input  i_async, // async input signal
   output o_sync // synchronized output signal
   );
   
   reg [1:0] sync_ff_reg;
   
   // use a synchronous reset
   always @(posedge i_clk)
     if(~i_rstn) 
       sync_ff_reg <= 'b0;
     else
       sync_ff_reg <= {sync_ff_reg[0],i_async};

   assign o_sync = sync_ff_reg[1];
   
endmodule
