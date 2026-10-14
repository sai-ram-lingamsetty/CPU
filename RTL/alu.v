`timescale 1ns/1ps

module alu(
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [2:0] alu_op,
    output reg [7:0] result,
    output wire zero
);
    assign zero = (result == 0);
    always@(*) begin
        case(alu_op)
            3'd0: result = a+b;
            3'd1: result = a-b;
            3'd2: result = a&b;
            3'd3: result = a|b;
            3'd4: result = a << 1;
            3'd5: result = a >> 1;
            default: result = 8'd0;    
        endcase
    end
endmodule
