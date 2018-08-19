module debounce
  #(
    parameter TIMER_COUNT_WIDTH = 8
    )
   (
    // clocking and reset
   input  i_clk,
   input  i_rstn,
    
   // button inputs
   input  i_button,
   // output debounced button press signal
   output o_debounced_button
   );
   
   reg button_sync_reg;
   reg button_sync_rlast;
   reg different;
   reg ztimer;
   reg [TIMER_COUNT_WIDTH-1:0] timer_count;
   
   // synchronize the async button press event
   DFF2 u_DEMET (.i_async(i_button), .o_sync(button_sync_reg), .*);
   
   // register the last change that happened
   DFF u_rlast (.i_d(button_sync_reg), .o_q(button_sync_rlast), .*);
   
   // ztimer

   always @ ( posedge i_clk ) begin
      if(~i_rstn) begin
	 ztimer      <= 1'b1;
	 timer_count <= {TIMER_COUNT_WIDTH{1'b0}};
      end else 

	if(ztimer & different) begin // time start condition
	   ztimer <= 1'b0;
	   timer_count <= timer_count + 1'b1;
	end
	else if(!ztimer) begin
	   if(&timer_count) begin
	      ztimer <= 1'b1;
	      timer_count <= {TIMER_COUNT_WIDTH{1'b0}};
	   end
	end 
	else begin
	   ztimer <= 1'b1;
	   timer_count <= {TIMER_COUNT_WIDTH{1'b0}};
	end
   end
   
   // different flag. This flag sets first when the button_sync_rlast is not
   // equal to the output debounce state. This is where first time o_debounced_button
   // gets the value of button_sync_rlast
   // then on there is no change in this value until fsm re-transitions to 
   always @ ( posedge i_clk ) begin
      if(~i_rstn)
	different <= 1'b0;
      else
	different <= (different && (!ztimer)) || (button_sync_rlast != o_debounced_button);
   end
   
   // output debounced button
   always @ ( posedge i_clk ) begin
      if(~i_rstn)
	o_debounced_button <= 1'b0;
      else
	if(ztimer)
	  o_debounced_button <= button_sync_rlast;
   end
   
endmodule

   
			   
