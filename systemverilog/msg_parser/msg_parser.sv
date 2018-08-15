module msg_parser (/*AUTOARG*/
		   // Outputs
		   in_ready, out_data, out_bytemask, out_valid,
		   // Inputs
		   clk, reset_n, in_valid, in_startofpayload, in_endofpayload, data
		   ) ;

   parameter DATA_WIDTH = 64;

   // clocking and reset
   input clk;
   input reset_n;

   // input data interface
   input logic in_valid;
   input logic in_startofpayload;
   input logic in_endofpayload;
   input logic [0:63] data;

   // output data interface
   output logic       in_ready;
   output logic [0:255] out_data;
   output logic [31:0] 	out_bytemask;
   output logic 	out_valid;
   
   // fsm type definition
   typedef enum 	logic [1:0]{
				    IDLE=2'b00,
				    PARSE_MSG_DATA=2'b01,
				    PARSE_MSG_HDR_SPLIT=2'b10,
				    PARSE_ALIGNED_HDR=2'b11
				    }parser_state_t;

   // define the fsm_state variable
   parser_state_t fsm_state;
   
   // data byte array
   logic [0:3] 		data_byte_array[7:0]; 
   logic [15:0] 	msg_bytes_consumed;
   logic [0:1] 		msg_length[7:0];
   logic [15:0] 	remaining_bytes_in_msg_nxt; // optimize later
   logic 		valid_bytes_in_backup_buffer;
   logic [15:0] 	bytes_in_backup_buffer;
   logic [0:3] 		backup_buffer[7:0];
   logic 		end_of_msg;
   logic [1:0] 		msg_count_bytes[7:0];   
   logic 		last_msg_in_payload;
   
   logic 		end_of_msg;
   logic [15:0] 	msg_counter;
   
   // convert bit stream to byte stream for easy indexing
   always_comb begin
      for(int i=0; i<8; i=i+1)
	data_byte_array[i] = data[i*8:+8];
   end
   
   // fsm description
   always_ff @ ( posedge clk ) begin
      if(~reset_n)
	fsm_state <= IDLE;
      else
	if(in_valid)
	  unique case(fsm_state) begin
	     
	     // IDLE state:
	     // wait for in_startofpayload and in_valid to start the payload
	     // invariably, in this state, message length is at data_arr[2:+2]
	     // message cnt at data_arr[0:+2]
	     // rest of msg data in [4:7]
	     
	     // since min message length is 8 bytes, move to PARSE_MSG
	     IDLE:
	       if(in_startofpayload)
		 fsm_state <= PARSE_MSG_DATA;
	       else
		 fsm_state <= IDLE;
	     
	     // PARSE_MSG_DATA
	     // In this state, there are the following possibilities
	     
	     // a. Remaining Bytes in message > 8, then continue parsing, stay 
	     //    in the same state PARSE_MSG_DATA
	     // b. Remaining Bytes in message = 8, then either of the following
	     //    a. This is last msg in payload, go to IDLE, also qualify with 
	     //       in_endofpayload, check for error as well
	     //    b. More messages to parse but now, header in next cycle 
	     //       aligned with the boundary, go to PARSE_ALIGNED_HDR
	     // c. Remaining Bytes in message < 8, then either of the following
	     //    a. This is last msg in paylaod, go to IDLE, also qualify with 
	     //       in_endofpayload, check for error as well
	     //    b. More messages to parse but now, header for nxt message also
	     //       in current cycle, backup data in the current cycle and use in 
	     //       next cycle
	     
	     PARSE_MSG_DATA:
	       if(in_endofpayload)
		 fsm_state <= IDLE;
	       else
		 if(remaining_bytes_in_msg_nxt > 8) 
		   fsm_state <= PARSE_MSG_DATA; 
		 else
		   if(last_msg_in_payload) // error condition
		     fsm_state <= IDLE;
		   else
		     // corner case: message ends at the boundary 
		     if(remaining_bytes_in_msg_nxt == 8)
		       fsm_state <= PARSE_MSG_HDR_ALIGNED;
	     // corner case: message ends one byte before boundary at data_byte_array[6]
		     else if(remaining_bytes_in_msg_nxt == 7) 
		       fsm_state <= PARSE_MSG_HDR_SPLIT;
		     else
		       fsm_state <= PARSE_MSG_DATA;
	     
	     // PARSE_MSG_HDR_SPLIT
	     // When in the PARSE_MSG_HDR_SPLIT state, since minimum msg length
	     // is 8 bytes, msg will end in the next cycle and we simply transition
	     // to PARSE_MSG_DATA
	     PARSE_MSG_HDR_SPLIT:
	       if(in_endofpayload) // error condition where parameters may mismatch
		 fsm_state <= IDLE;
	       else
		 fsm_state <= PARSE_MSG_DATA;
	     
	     // When in PARSE_MSG_HDR_ALIGNED, the message header is aligned to the 
	     // boundary, and msg will end in the next cycle, so we simply transition
	     // to PARSE_MSG_DATA
	     PARSE_MSG_HDR_ALIGNED:
	       if(in_endofpayload) // error condition where parameters may mismatch
		 fsm_state <= IDLE;
	       else
		 fsm_state <= PARSE_MSG_DATA;
	     
	     default:
	       fsm_state <= IDLE;
	  end endcase // case (fsm_state)
      // else stay in same state
   end
   
   // message bytes consumed
   always_ff @ ( posedge clk ) begin
      if(~resetn)
	msg_bytes_consumed <= 'b0;
      else
	if(in_valid)
	  unique case(fsm_state)
	    IDLE:
	      // In IDLE, data is 4 bytes, msg bytes consumed is set to 4 bytes
	      msg_bytes_consumed <= 'd4;
	    
	    // most conditions related to handling bytes consumed are updated
	    // in the PARSE_MSG_DATA state
	    PARSE_MSG_DATA:
	      if(in_endofpayload)
		msg_bytes_consumed <= 'd0;
	      else
		if(remaining_bytes_in_msg_nxt > 8)
		  // all 8 bytes in the clock cycle belong to msg payload, increment 
		  // msg bytes consumed by 8
		  msg_bytes_consumed <= msg_bytes_consumed + 'd8;
		else
		  // if current msg is last in the payload, reset msg byte payload to 0
		  if(last_msg_in_payload)
		    msg_bytes_consumed <= 'd0;
		  else
		    // corner case: message ends at the boundary
		    // we simply reset msg_bytes_consumed to 0, since msg is supposed to
		    // follow in the next cycle
		    if(remaining_bytes_in_msg_nxt == 8)
		      msg_bytes_consumed <= 'd0;
	    // corner case: message ends one byte before boundary at data_byte_array[6]
            // here, too message is yet to follow, so reset msg bytes consumed to 0
		    else if(remaining_bytes_in_msg_nxt == 7) 
		      msg_bytes_consumed <= 'd0;
		    else
		      // current message ends with remaining bytes indicating the bytes 
		      // occupied by the current message, so we decrement 2 bytes of header
		      // from the next message and remaining bytes from current message to
		      // get the bytes consumed in the next cycle
		      msg_bytes_consumed <= 'd8 -'d2 - remaining_bytes_in_msg_nxt;
	    
	    // In this state, header byte[0] occupies data_byte_array[0], all others are
	    // allocated to the message
	    PARSE_MSG_HDR_SPLIT:
	      if(in_endofpayload)
		msg_bytes_consumed <= 'd0;
	      else
		msg_bytes_consumed <= 'd7;

	    // In this state, header byte[0:1] occupies data_byte_array[0:1] all others
	    // are allocated to message
	    PARSE_MSG_HDR_ALIGNED:
	      if(in_endofpayload)
		msg_bytes_consumed <= 'd0;
	      else
		msg_bytes_consumed <= 'd6;
	    default:
	      msg_bytes_consumed <= msg_bytes_consumed;
	  endcase // case (fsm_state)
   end

   // message length update
   always_ff @ ( posedge clk ) begin
      if(~resetn)
	for(int i=0; i<2; i++)
	  msg_length[i] <= 'b0;
      else
	if(in_valid)
	  unique case(fsm_state)
	    IDLE:
	      // In IDLE, msg_length is available at data_byte_array[2:3]
	      msg_length <= data_byte_array[2:+2];
	    
	    PARSE_MSG_DATA:
	      if(in_endofpayload)
		msg_length <= 'd0;
	      else
		if(remaining_bytes_in_msg_nxt > 8)
		  // no change if there are more bytes in current message to parse
		  msg_length <= msg_length;
		else
		  // if current msg is last in the payload, reset msg length to 0, since
		  // state machine is moving to IDLE
		  if(last_msg_in_payload | in_endofpayload)
		    msg_length <= 'd0;
		  else
		    // next msg would be aligned, so reset msg_length to 0
		    if(remaining_bytes_in_msg_nxt == 8)
		      msg_length <= 'd0;
	    // next msg would be with split header, so pick up higher byte 
	    // from the data_byte_array[7]
		    else if(remaining_bytes_in_msg_nxt == 7) 
		      msg_length <= {data_byte_array[7],8'b0};
		    else
		      // current message ends with remaining bytes indicating the bytes 
		      // occupied by the current message, so we decrement 2 bytes of header
		      // from the next message and remaining bytes from current message to
		      // get the bytes consumed in the next cycle
		      msg_length <= data_byte_array[msg_header_byte_ptr:+2];
	    
	    PARSE_MSG_HDR_ALIGNED:
	      msg_length <= data_byte_array[0:1];
	    
	    PARSE_MSG_HDR_SPLIT:
	      msg_length <= {msg_length[1],data_byte_array[0]};
	    
	    default:
	      msg_length <= msg_length;
	  endcase
   end // always_ff @

   // remaining bytes 
   always_comb begin
      remaining_bytes_in_msg_nxt <= {msg_length[0],msg_length[1]} - msg_bytes_consumed;
   end

   // bytes in backup
   always @ ( posedge clk ) begin
      if(~resetn)
	valid_bytes_in_backup_buffer <= 1'b0;
      else
	if(in_valid)
	  unique case(fsm_state)
	    
	    // backup bytes only in case where you have two messages in a 
	    // clock cycle. 
	    PARSE_MSG_DATA:
	      if(in_endofpayload)
		valid_bytes_in_backup_buffer <= 1'b0;
	      else
		if(remaining_bytes_in_msg_nxt > 8)
		  valid_bytes_in_backup_buffer <= 1'b0;
		else
		  if(last_msg_in_payload)
		    valid_bytes_in_backup_buffer <= 1'b0;
		  else
		    // next msg would be aligned, so reset msg_length to 0
		    if(remaining_bytes_in_msg_nxt == 8)
		      valid_bytes_in_backup_buffer <= 1'b0;
	    // next msg would be with split header, so pick up higher byte 
	    // from the data_byte_array[7]
		    else if(remaining_bytes_in_msg_nxt == 7) 
		      valid_bytes_in_backup_buffer <= 1'b0;
		    else
		      valid_bytes_in_backup_buffer <= 1'b1;
	    default:
	      valid_bytes_in_backup_buffer <= 1'b0;
	  endcase
   end

   // bytes in backup buffer
   always_comb 
     bytes_in_backup_buffer = valid_bytes_in_backup_buffer ? msg_bytes_consumed: 'd0;

   // update backup bytes
   always_ff @ ( posedge clk ) begin
      if(~resetn)
	backup_buffer <= 'b0;
      else
	if(in_valid)
	  unique case(fsm_state)
	    
	    PARSE_MSG_DATA:
	      if(in_endofpayload)
		backup_buffer <= 'b0;
	      else
		if(remaining_bytes_in_msg_nxt > 8)
		  backup_buffer <= 'b0;
		else
		  if(last_msg_in_payload)
		    backup_buffer <= 'b0;
		  else
		    // corner case: message ends at the boundary 
		    if(remaining_bytes_in_msg_nxt == 8)
		      backup_buffer <= 'b0;
	    // corner case: message ends one byte before boundary at data_byte_array[6]
		    else if(remaining_bytes_in_msg_nxt == 7) 
		      backup_buffer <= 'b0;
		    else
		      backup_buffer <= data_byte_array;
	    default:
	      backup_buffer <= 'b0;
	  endcase
   end
   
   // end of msg indication
   always_comb begin
      unique case(fsm_state)
	IDLE:
	  end_of_msg = 1'b0;
	
	PARSE_MSG_DATA:
	  if(remaining_bytes_in_msg_nxt > 8)
	    end_of_msg = 1'b0;
	  else
	    end_of_msg = 1'b1;
	
	PARSE_MSG_HDR_SPLIT:
	  end_of_msg = 1'b0;

	PARSE_MSG_HDR_ALIGNED:
	  end_of_msg = 1'b0;
	default:
	  end_of_msg = 1'b0';
      endcase
   end

   // msg count parsing
   always_ff @ ( posedge clk ) begin
      if(~resetn)
	for(int i=0; i<2; i++)
	  msg_count_bytes[i] <= '0;
      else
	if(in_valid)
	  unique case(fsm_state)
	    IDLE: 
	      msg_count_bytes <= data_byte_array[0:1];
	    
	    PARSE_MSG_DATA:
	      if(in_endofpayload)
		msg_count_bytes <= '0;
	      else
		if(remaining_bytes_in_msg_nxt > 8)
		  msg_count_bytes <= msg_count_bytes;
		else
		  if(last_msg_in_payload)
		    msg_count_bytes <= '0;
		  else
		    msg_count_bytes <= msg_count_bytes;
	    default:
	      if(in_endofpayload)
		msg_count_bytes <= '0;
	      else
		msg_count_bytes <= msg_count_bytes;
	  endcase
   end

   // msg counter
   always_ff @ (posedge clk ) begin
      if(~resetn)
	msg_counter <= '0;
      else
	if(in_valid)
	  unique case(fsm_state)
	    IDLE:
	      if(in_startofpayload & in_valid)
		msg_counter <= msg_counter + 1'b1;
	    PARSE_MSG_DATA:
	      if(in_endofpayload)
		msg_counter <= '0;
	      else
		if(remaining_bytes_in_msg_nxt > 8)
		  msg_counter <= msg_counter;
		else
		  if(last_msg_in_payload)
		    msg_counter <= '0;
		  else
		    msg_counter <= msg_counter + 1'b1;
	    default:
	      if(in_endofpayload)
		msg_counter <= 'b0;
	      else
		msg_counter <= msg_counter;
	  endcase
   end
   
   // last_msg_in_payload
   always_comb last_msg_in_payload = (fsm_state == PARSE_MSG_DATA) & (remaining_bytes_in_msg_nxt <= 8) & (({msg_count_bytes[0],msg_count_bytes[1]}) == msg_counter);
   
   // end of msg indication is flopped to generate the out_valid signalling
   always_ff @ ( posedge clk ) begin
      if(~resetn)
	out_valid <= 1'b0;
      else
	out_valid <= end_of_msg;
   end
   
   // out data
   
   // out byte mask
   logic [63:0] bytemask [7:0];
   always_comb begin
      for(int i=0; i<32 ; i++)
	if(i+1 <= msg_count_bytes[7:0])
	  bytemask[i] = 8'hFF;
	else
	  bytemask[i] = '0;
   end

   // registered version
   always_ff @ ( posedge clk ) begin
      if(~resetn)
	out_bytemask <= 'b0;
      else
	if(end_of_msg) // simply use the msg length to append
	  for(int i=0; i<256;i++)
	    out_bytemask[(i+1)*8-1:-8] <= bytemask[i];
   end
   
   
endmodule // msg_parser

