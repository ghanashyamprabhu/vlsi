module bin2gray (/*AUTOARG*/
   // Outputs
   gray_code, gray_code_valid,
   // Inputs
   clk, rstn, binary_code, binary_code_valid
   ) ;

   parameter CODE_WIDTH = 8;
   
   input clk;
   input rstn;

   input [CODE_WIDTH-1:0] binary_code;
   input 		  binary_code_valid;

   // inputs 
   output [CODE_WIDTH-1:0] gray_code;
   output 		   gray_code_valid; // pulse signal indicating valid data on gray_code
   
   // binary to gray code conversion takes one clock cycle
   // function bin2gray will convert the binary code to gray code
   always_ff @( posedge clk or negedge rstn ) begin
      if(~rstn)
	gray_code <= 'b0;
      else
	if(binary_code_valid) begin
	   // gray code msb is same as binary code msb
	   for (int i=CODE_WIDTH-1; i >=0; i=i-1) begin
	      
	      if(i == CODE_WIDTH-1)
		gray_code[CODE_WIDTH-1] <= binary_code[CODE_WIDTH-1];
	      else
		gray_code[i] <= binary_code[i] ^ binary_code[i+1];
	   end
	   
	end else
	  gray_code <= 'b0;
   end
   
   // flop to delay valid by 1 clock cycle
   always_ff @ ( posedge clk or negedge rstn ) begin
      if(~rstn)
	gray_code_valid <= 'b0;
      else
	gray_code_valid <= binary_code_valid;
   end
   
endmodule // bin2gray
