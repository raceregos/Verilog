// Code your design here
module blram(clk, rst, i_we, i_addr, i_ram_data_in, o_ram_data_out);
 
parameter SIZE = 6;
parameter DEPTH = 64;
parameter TEST_CASE = 1;
 
input clk; 
input rst;
input i_we;
input [SIZE-1:0] i_addr;
input [9:0] i_ram_data_in;
output reg [9:0] o_ram_data_out;
 
reg [9:0] memory[0:DEPTH-1];
 
always @(posedge clk) begin
  o_ram_data_out <= #1 memory[i_addr[SIZE-1:0]];
  if (i_we)
        memory[i_addr[SIZE-1:0]] <= #1 i_ram_data_in;
end 
 
initial begin
    if(TEST_CASE == 1) begin
		memory[0] = 10'b0000110010; // LOD 50, (ACC = *50), Hex = 32
		memory[1] = 10'b0010110011; // ADD 51, ACC = ACC + (*51), Hex = B3
		memory[2] = 10'b0001110100; // STO 52, (*52) = ACC, Hex = 74
		memory[3] = 10'b1001000000; // Halt, Hex = 240
		memory[50] = 10'b0000000101; // Hex = 5
		memory[51] = 10'b0000001010; // Hex = A
    end else if(TEST_CASE == 2) begin
		memory[0] = 10'b0000110010; // LOD 50, (ACC = *50), Hex = 32
		memory[1] = 10'b0100110011; // MUL 51, ACC = ACC * (*51), Hex = 133
		memory[2] = 10'b0001110100; // STO 52, (*52) = ACC, Hex = 74
		memory[3] = 10'b1001000000; // Halt, Hex = 240
		memory[50] = 10'b0000000101; // Hex = 5
		memory[51] = 10'b0000001010; // Hex = A
    end else if(TEST_CASE == 3) begin
		memory[0]= 10'b0000110011; // LOD 51, ACC = *51, Hex = 33
		memory[1]= 10'b0011110001; // SUB 49, ACC = ACC - *49, Hex = F1
		memory[2]= 10'b0111001010; // JMZ 10, 
		memory[3]= 10'b0000110000; // LOD 48, 
		memory[4]= 10'b0010110010; // ADD 50,
		memory[5]= 10'b0001110000; // STO 48,
		memory[6]= 10'b0000110001; // LOD 49, ACC = i, Hex = 31
		memory[7]= 10'b0010101110; // ADD 46, ACC = i + 1, Hex = AE
		memory[8]= 10'b0001110001; // STO 49, i = i + 1, Hex = 71
		memory[9]= 10'b0110000000; // JMP 0,180
		memory[10]= 10'b0000110000; // LOD 48, ACC = temp, Hex = 30
		memory[11]= 10'b0001110100; // STO 52, *52 = ACC, Hex = 74
		memory[12]= 10'b1001000000;// HLT
		
		memory[46]= 10'b1; // 1 number
		memory[48]= 10'b0; // Hex = 0, temp
		memory[49]= 10'b0; // Hex = 0, 
		memory[50]= 10'b0000000101; // Hex = 5
		memory[51]= 10'b0000001010; // Hex = A
 
    end
end 
 
endmodule

module avion_cpu #(
    parameter ADDRESS_WIDTH = 6,
    parameter DATA_WIDTH = 10
)(
    input clk, 
    input rst, 
    output reg [DATA_WIDTH-1:0] MDRIn, 
    output reg RAMWr, 
    output reg [ADDRESS_WIDTH-1:0] MAR, 
    input [DATA_WIDTH-1:0] MDROut, 
    output reg [5:0] PC
);

reg [DATA_WIDTH - 1:0] IR, IRNext;
reg [5:0] PCNext;
reg [9:0] ACC, ACCNext;
reg [2:0] state, stateNext;

always @(posedge clk) begin
    state <= #1 stateNext;
    PC    <= #1 PCNext;
    IR    <= #1 IRNext;
    ACC   <= #1 ACCNext;
end

always @(*) begin
    stateNext = state;
    PCNext    = PC;
    IRNext    = IR;
    ACCNext   = ACC;
    MAR       = 0;
    RAMWr     = 0;
    MDRIn     = 0;

    if (rst) begin
        stateNext = 0;
        PCNext    = 0;
        IRNext    = 0;
        ACCNext   = 0;
        MAR       = 0;
        RAMWr     = 0;
        MDRIn     = 0;
    end else begin
        case (state)

            // FETCH
            0: begin
                MAR = PC;
                RAMWr = 0;
                stateNext = 1;
            end

            // LOAD INSTRUCTION
            1: begin
                IRNext = MDROut;
                PCNext = PC + 1;
                stateNext = 2;
            end

            // DECODE
            2: begin
                if (IR[9:6] < 6) begin
                    MAR = IR[5:0];
                    stateNext = 3;
                end else if (IR[9:6] == 6) begin
                    PCNext = IR[5:0];
                    stateNext = 0;
                end else if (IR[9:6] == 7) begin
                    if (ACC == 0)
                        PCNext = IR[5:0];
                    stateNext = 0;
                end else if (IR[9:6] == 8) begin
                    stateNext = 0;
                end else if (IR[9:6] == 9) begin
                    stateNext = 4;
                end
            end

            // EXECUTE
            3: begin
                stateNext = 0;
                RAMWr = 0;
                MAR = 0;

                if (IR[9:6] == 0) begin
                    ACCNext = MDROut;
                end else if (IR[9:6] == 1) begin
                    MAR    = IR[5:0];
                    RAMWr  = 1;
                    MDRIn  = ACC;
                end else if (IR[9:6] == 2) begin
                    ACCNext = ACC + MDROut;
                end else if (IR[9:6] == 3) begin
                    ACCNext = ACC - MDROut;
                end else if (IR[9:6] == 4) begin
                    ACCNext = ACC * MDROut;
                end else if (IR[9:6] == 5) begin
                    if (MDROut != 0)
                        ACCNext = ACC / MDROut;
                    else
                        ACCNext = 0;
                end
            end

            // HALT
            4: begin
                stateNext = 4; // Stay in halt
            end

        endcase
    end
end

endmodule