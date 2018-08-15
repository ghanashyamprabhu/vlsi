Question: 
Design a scalable gray counter without using Karnaugh map boolean expression for each bit. 

Solution: 
I found this interesting solution from Altera(Intel) 

The solution is to use a additional bit that toggles every clock cycle as the lsb of our 
gray counter that is initialized to 0 the beginning. 

Let's start with a 4 bit example Q[3:0] and additional bit at Q[-1] (negative indices 
are ugly). Let's use Q[GRAY_COUNTER_WIDTH:0], actual counter is Q[GRAY_COUNTER_WIDTH:1]

For every count we also calculate a signal NO_ONES_BELOW for every bit index. So at 
every index of the counter Q, it checks if there are any more 1's below this index. If
yes, it sets the NO_ONES_BELOW[i] = 0, else sets it to 1

The logic is to flip the bit if we detect a *10..0 pattern else simply flip the next bit
after this index where the first 1 was detected

Additionally, the logic needs to be slightly changed for the lsb otherwise the counter 
saturates halfway

see verilog for the exact description

below is a current state next state description of the same 

|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
| Sl NO | Q3  | Q2  | Q1  | Q0 | P3 | P2 | P1 | P0 | N3 | N2 | N1 | N0 | comments                                      |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
|       |     |     |     |    |  0 |  0 |  0 |  0 |  1 |  1 |  1 |  1 | Initialize P to 0, N will be all 1s           |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
|     0 | 0   | 0   | 0   |  0 |  0 |  0 |  0 |  1 |  0 |  0 |  0 |  1 | At every clock, invert P0.                    |
|       |     |     |     |    |    |    |    |    |    |    |    |    | P1 onwards, P[i] = Q[i] ^ (Q[i-1] & N[i-1])   |
|       |     |     |     |    |    |    |    |    |    |    |    |    | Once P is calculated, calcuate N again for P  |
|       |     |     |     |    |    |    |    |    |    |    |    |    | N[0]=1 since no more bits avaiable after N[0] |
|       |     |     |     |    |    |    |    |    |    |    |    |    | N[i]= N[i-1] & ~P[i-1]                        |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
|     1 | _0_ | _0_ | _0_ |  1 |  0 |  0 |  1 |  0 |  0 |  0 |  1 |  1 |                                               |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
|     2 | _0_ | _0_ | _1_ |  0 |  0 |  1 |  1 |  1 |  0 |  0 |  0 |  1 |                                               |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
|     3 | _0_ | _1_ | _1_ |  1 |  0 |  1 |  0 |  0 |  0 |  1 |  1 |  1 |                                               |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
|     4 | _0_ | _1_ | _0_ |  0 |  1 |  1 |  0 |  1 |  0 |  0 |  0 |  1 |                                               |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
|     5 | _1_ | _1_ | _0_ |  1 |  1 |  1 |  1 |  0 |  0 |  0 |  1 |  1 |                                               |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
|     6 | _1_ | _1_ | _1_ |  0 |  1 |  0 |  1 |  1 |  0 |  0 |  0 |  1 |                                               |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
|     7 | _1_ | _0_ | _1_ |  1 |  1 |  0 |  0 |  0 |  1 |  1 |  1 |  1 |                                               |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|
|     8 | _1_ | _0_ | _0_ |  0 |    |    |    |    |    |    |    |    |                                               |
|-------+-----+-----+-----+----+----+----+----+----+----+----+----+----+-----------------------------------------------|




        
