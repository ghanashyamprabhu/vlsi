
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
