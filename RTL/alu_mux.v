`timescale 1ns/1ps
module alu_mux(
    input wire alu_src,
    input wire [7:0] reg_data2,
    input wire [7:0] immediate,
    output wire [7:0] alu_b
);
    assign alu_b = alu_src ? immediate : reg_data2;
endmodule 
