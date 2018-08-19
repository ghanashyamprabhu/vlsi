// sync reset flipflop
module DFF
  (
   input i_clk,
   input i_rstn,
   input i_d,
   output reg o_q
   );

   // simple posedge triggered d-flip flop reg
   always @(posedge i_clk)
     if(~i_rstn)
       o_q <= 1'b0;
     else
       o_q <= i_d;
   
endmodule
