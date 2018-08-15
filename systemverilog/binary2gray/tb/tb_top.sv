module tb_top (/*AUTOARG*/) ;

   logic clk;
   logic rstn;

   parameter CLK_PERIOD = 10;
   parameter RESET_DELAY = 1000;
   parameter CODE_WIDTH = 4;

   /*AUTOREG*/
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [CODE_WIDTH-1:0] gray_code;		// From u_bin2gray of bin2gray.v
   wire			gray_code_valid;	// From u_bin2gray of bin2gray.v
   // End of automatics
   logic [CODE_WIDTH-1:0] binary_code;
   logic [CODE_WIDTH-1:0] binary_code_valid;
   			   
   // reset sequence 
   initial begin
      rstn <= 'b1;
      #100;
      rstn <= 1'b0;
      #RESET_DELAY;
      rstn <= 1'b1;
   end
   
   // clock generation sequence
   initial begin
      
      clk <= 1'b0;
      forever begin
	 clk <= #CLK_PERIOD ~clk;
      end
   end

   // test cases
   initial begin
//`include "tc1.vh"

// wait until reset de-assert
wait @posedge rstn;
binary_code_valid <= 1'b0;

wait @posedge clk;
binary_code <= 'd0;
binary_code_valid <= 1'b1;

wait @posedge clk;
binary_code <= 'd1;
binary_code_valid <= 1'b1;

wait @posedge clk;
binary_code <= 'd2;
binary_code_valid <= 1'b1;

wait @posedge clk;
binary_code <= 'd3;
binary_code_valid <= 1'b1;

wait @posedge clk;
binary_code <= 'd4;
binary_code_valid <= 1'b1;

wait @posedge clk;
binary_code <= 'd5;
binary_code_valid <= 1'b1;

wait @posedge clk;
binary_code <= 'd6;
binary_code_valid <= 1'b1;

wait @posedge clk;
binary_code <= 'd7;
binary_code_valid <= 1'b1;

wait @posedge clk;
binary_code <= 'd;
binary_code_valid <= 1'b1;

wait @posedge clk;
binary_code_valid <= 1'b0;

#10000; // terminal delay
$finish
      
   end

   // dut inst
   bin2gray 
     #(
       .CODE_WIDTH(CODE_WIDTH)
       )
   u_dut 
     (/*AUTOINST*/
      // Outputs
      .gray_code		(gray_code[CODE_WIDTH-1:0]),
      .gray_code_valid		(gray_code_valid),
      // Inputs
      .clk			(clk),
      .rstn			(rstn),
      .binary_code		(binary_code[CODE_WIDTH-1:0]),
      .binary_code_valid	(binary_code_valid)
      );

   
endmodule // tb_top

// Local Variables:
// verilog-library-directories:("." "../src/." "../tc/.")
// verilog-library-files:(".")
// verilog-library-extensions:(".v" ".h" ".sv")
// End:
