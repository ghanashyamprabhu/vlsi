module sma (/*AUTOARG*/ ) ;

   parameter DATA_INPUT_WIDTH = 16;
   parameter NUM_SAMPLES_TO_FILTER = 4;
   localparam BITS_ADDED_BY_FILTER_SUM = $clog2(NUM_SAMPLES_TO_FILTER);
   localparam SAMPLE_BUFFER_DEPTH_WIDTH  = $clog2(NUM_SAMPLES_TO_FILTER);
   
   input clk;
   input rstn;

   // input interface
   input logic [DATA_INPUT_WIDTH-1:0] in_data;
   input logic 			      in_data_valid;

   // output interface
   output logic [DATA_INPUT_WIDTH-1:0] out_data;
   output logic 		       out_data_valid;
   
   // internal signal declaration
   logic [SAMPLE_BUFFER_DEPTH_WIDTH-1:0] sample_counter;
   logic [DATA_INPUT_WIDTH+BITS_ADDED_BY_FILTER_SUM-1:0] sample_sum;
   logic [NUM_SAMPLES_TO_FILTER-1:0] 			 sample_memory[DATA_INPUT_WIDTH-1:0];
   logic [SAMPLE_BUFFER_DEPTH_WIDTH-1:0] 		 sample_memory_wr_addr;
   logic [DATA_INPUT_WIDTH-1:0] 			 sample_rd_data_from_memory;
   logic [DATA_INPUT_WIDTH-1:0] 			 decrement_sample_from_ram;
   
   // count upto samples
   always_ff @(posedge clk or negedge rstn)
     if(~rstn)
       sample_counter <= 'b0;
     else
       if(in_data_valid)
	 sample_counter <= sample_counter + 1'b1;

   // max sample reached indication
   // after this point any new sample will cause a new valid output 
   always_ff @ ( posedge clk or negedge rstn ) begin
      if(~rstn)
	max_sample_count_reached <= 1'b0;
      else
	if(in_data_valid)
	  if(&sample_counter) // all bits of sample counter are 1s reached max count
	    max_sample_count_reached <= 1'b1;
   end
   

   // read first, and write later memory model
   // packed array for memory modelling
   always_ff @ ( posedge clk or negedge rst ) begin
      if(~rstn) begin

	 // rd_data is zero
	 sample_rd_data_from_memory <= 'b0;
	 
	 // initialize all memory locations to zero 
	 for (int i=0; i<NUM_SAMPLES_TO_FILTER; i++) 
	   sample_memory[i] <= 'b0;
	 
      end else begin
	 
	 // first memory read out
	 sample_rd_data_from_memory <= sample_memory[sample_memory_wr_addr];

	 // update the memory location and increment write address
	 if(in_data_valid) begin
	    sample_memory[sample_counter] <= in_data;
	 end
      end // else: !if(~rstn)
   end

   // sample sum reg and sample sum comb logic
   // sample sum has higher bit width
   always_comb sample_sum_nxt = sample_sum_reg + in_data - decrement_sample_from_ram;

   always_ff @ ( posedge clk or negedge rstn ) begin
      if(~rstn)
	sample_sum_reg <= 'b0;
      else
	if(in_data_valid) // possibly can even forego this for optimization
	  sample_sum_reg <= sample_sum_nxt;
   end

   always_comb decrement_sample_from_ram = sample_rd_data_from_memory;
   
   // actual sum is trim down version of sample_sum by losing LSB bits can be flopped 
   always_ff @ (posedge clk or negedge rstn ) begin
      if(~rstn)
	out_data <= 'b0;
      else
	if(in_data_valid)
	  out_data <= sample_sum_nxt[DATA_INPUT_WIDTH+BITS_ADDED_BY_FILTER_SUM-1:-DATA_INPUT_WIDTH];
   end
   
   // output valid generation
   always_ff @ (posedge clk or negedge rstn ) begin
      if(~rstn)
	out_data_valid <= 1'b0;
      else
	// only start asserting output valid once sample counter reaches maximum 
	// value
	if(in_data_valid & ((&sample_counter) | max_sample_count_reached))
	  out_data_valid <= 1'b1;
	else
	  out_data_valid <= 1'b0;
   end

endmodule // sma
