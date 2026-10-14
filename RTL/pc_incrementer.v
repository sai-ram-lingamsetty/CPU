`timescale 1ns/1ps
module pc_incrementer(
    input wire [7:0] pc,
    output wire [7:0] pc_plus_1
);
    assign pc_plus_1 = pc + 8'b1;
endmodule
