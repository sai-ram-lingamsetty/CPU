`timescale 1ns/1ps

module pc_reg(
    input wire clk,
    input wire rst_n,
    input wire [7:0] pc_next,
    output reg [7:0] pc_out
);
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pc_out <= 8'b0;
        end else begin
            pc_out <= pc_next;
        end
    end

endmodule
