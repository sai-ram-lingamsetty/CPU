`timescale 1ns/1ps

module write_back_mux(
    input wire mem_to_reg,
    input wire [7:0] alu_out,
    input wire [7:0] mem_load,
    output wire [7:0] write_data
);

    assign write_data = mem_to_reg ? mem_load : alu_out;
endmodule
