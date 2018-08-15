Message Decoder Problem
-----------------------

Exchange dessiminates data in a protocol specific to them. A sample
exchange protocol is defined below. 


MSG   | MSG     | MSG1 | MSG     | MSG2   | ... . | MSG     | MSGn |
COUNT | LENGTH1 |      | LENGTH2 |        |       | LENGTHn |      |

Details of the fields 

| Field      | Length   | Description                       |
|------------+----------+-----------------------------------|
| MSG count  | 2 byte   | number of messages in the payload |
|------------+----------+-----------------------------------|
| MSG Length | 2 byte   | length of the following message   |
|------------+----------+-----------------------------------|
| MSG        | Variable | Message description               |


Input interface definition

| Signal            | Width (bits) | Direction | Description                                       |
|-------------------+--------------+-----------+---------------------------------------------------|
| clk               |            1 | input     | posedge edge triggered                            |
|                   |              |           | clk                                               |
|-------------------+--------------+-----------+---------------------------------------------------|
| reset_n           |            1 | input     | active low reset                                  |
|-------------------+--------------+-----------+---------------------------------------------------|
| in_valid          |            1 | input     | high when incoming data is valid                  |
|                   |              |           | low otherwise                                     |
|-------------------+--------------+-----------+---------------------------------------------------|
| in_startofpayload |            1 | input     | high for 1 cycle, marks the beginning             |
|                   |              |           | of incoming payload should be qualified           |
|                   |              |           | with in_valid                                     |
|-------------------+--------------+-----------+---------------------------------------------------|
| in_endofpayload   |            1 | input     | high for 1 cycle, marks the end of                |
|                   |              |           | incoming payload, shoud be qualified with         |
|                   |              |           | in_valid                                          |
|-------------------+--------------+-----------+---------------------------------------------------|
| in_ready          |            1 | output    | Asserted by the module being designed to indicate |
|                   |              |           | it is ready to accept data (Read latency =1)      |
|-------------------+--------------+-----------+---------------------------------------------------|
| data              |           64 | input     | data                                              |
|-------------------+--------------+-----------+---------------------------------------------------|
| in_empty          |            3 | input     | always qualified when in_endofpacket is high.     |
|                   |              |           | indicates the number of empty bytes in the last   |
|                   |              |           | cycle of the incoming payload                     |
|-------------------+--------------+-----------+---------------------------------------------------|
| in_error          |            1 | input     | Used to indicate error in the incoming data       |
|                   |              |           | stream                                            |
|-------------------+--------------+-----------+---------------------------------------------------|
| out_data          |          256 | output    | extracted message data                            |
|-------------------+--------------+-----------+---------------------------------------------------|
| out_valid         |            1 | output    | high when out_data is valid, low otherwise        |
|-------------------+--------------+-----------+---------------------------------------------------|
| out_bytemask      |           32 | output    | used to indicate the number of valid bytes in the |
|                   |              |           | out_data, if out_data has 10 valid bytes, then    |
|                   |              |           | out_bytemask is 32'h0000_003F                     |

Assumptions
-----------

1. Maximum number of bytes in a single payload will nto exceed 1500 bytes
2. The minimum size of a message is 8 bytes and the maxinum size of a message is 32 bytes
3. in_error is always zero

Question 
1. Write an FSM for your design
2. Write synthesizable RTL for your moduel in SystemVerilog 
3. How would your design change if the range of the message changed from 8,32 bytes to 
   a. {1,32} bytes
   b. {8,64} bytes 
4. what is the critical path in your design
5. what's the fmax for the design (ballpark number)
6. what are the trade-offs of your design approach




