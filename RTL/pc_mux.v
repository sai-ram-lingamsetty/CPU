`timescale 1ns/1ps

module pc_mux(
    input wire [7:0] pc_plus_1,
    input wire [7:0] jump_target,
    input wire [7:0] branch_target,
    input wire branch_taken,
    input wire jump,
    output reg [7:0] pc_next
);

    always @(*) begin
        if(jump)
            pc_next = jump_target;
        else if(branch_taken)
            pc_next = branch_target;
        else
            pc_next = pc_plus_1;
    end

endmodule 
