`timescale 1ns/1ps
module instruction_memory #(
    parameter INIT_FILE = "program.mem"   // relative to the simulator's working directory
)(
    input wire [7:0] address,
    output wire [15:0] instruction
);
    reg [15:0] mem [0:255];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    assign instruction = mem[address];
endmodule

