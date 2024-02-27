# VHDL-CPU
All work is my own. Any work that is not mine mentions the source:

The following lines of sequential code is the subject of my paper on CPU architecture.

(1) v <= a + b;
(2) w <= b * 2;
(3) x <= v - w;
(4) y <= v + w;
(5) z <= x * y;

Harvard and Von-Neumann CPU architectures, featuring a single core processor, are simulated via Modelsim in VHDL while running the above lines of code. In addition, an FPGA also runs the above lines.

Furthermore, the instruction cycle for all three types are successfully pipelined, and the performance of each CPU architecture is analysed and measured.

Instructions in the RAM are formatted as follows:
  4 bit opcode // 4 bit memory destination address  // 4 bit operand1 location in memory  // 4 bit operand 2 location in memory
  (1) The first 4 bits define the logical or arithmetic action that the ALU shall execute.
  (2) The next 4 bits define the address in memory, where the computed value shall be stored.
  (3) The next 4 bits define the location where operand1 shall be loaded from.
  (4) The final 4 bits define where operand2 shall be loaded from.
   
