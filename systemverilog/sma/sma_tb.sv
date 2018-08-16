module sma_tb ();

   localparam DATA_INPUT_WIDTH = 16;
   localparam NUM_SAMPLES_TO_FILTER = 4;
   
   logic clk;
   logic rstn;

   // dut signals
   logic [DATA_INPUT_WIDTH-1:0] in_data;
   logic 			in_data_valid;
   logic [DATA_INPUT_WIDTH-1:0] out_data;
   logic 			out_data_valid;

   // run clk
   initial begin
      clk <= 'b0;

      forever begin
	 #50 clk <= ~clk;
      end
   end

   initial begin
      rstn = 'b1;
      #1000;
      rstn = 'b0;

      #1000;
      rstn = 'b1;
   end

   // dut instance
   sma #(
	 .DATA_INPUT_WIDTH(DATA_INPUT_WIDTH),
	 .NUM_SAMPLES_TO_FILTER(NUM_SAMPLES_TO_FILTER)
	   ) 
   u_sma (.*);

   // test case
   initial begin
      in_data_valid <= 'b0;
      in_data <= 'b0;

      // wait until reset de-assert
      @(negedge rstn);
      @(posedge rstn);

      // wait for some 10 clocks after reset is de-asserted
      repeat (10) begin
	 @(posedge clk);
      end

      // run the test case
      for (int i = 0; i<256; i++) begin
	 @(posedge clk);
	 in_data_valid <= 1'b1;
	 in_data = DATA_INPUT_WIDTH'(i);
      end

      // de-assert valid 
      @(posedge clk);
      in_data_valid <= 1'b0;

      repeat (10) begin
	 @(posedge clk);
      end

      $finish;
   end
   
endmodule 	       
