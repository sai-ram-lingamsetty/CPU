`timescale 1ns/1ps
module control_unit(
    input wire [3:0] opcode,
    output reg alu_src,
    output reg reg_write,
    output reg branch,
    output reg jump,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg [2:0] alu_op
);
    always@(*) begin
        alu_src    = 1'b0;
        reg_write  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_op     = 3'd0;
        case(opcode)
            4'd0: begin //ADD
                alu_src    = 1'b0;
                reg_write  = 1'b1;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 3'd0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
            end
            4'd1: begin //SUB
                alu_src    = 1'b0;
                reg_write  = 1'b1;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 3'd1;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
            end
            4'd2: begin //AND
                alu_src    = 1'b0;
                reg_write  = 1'b1;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 3'd2;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
            end
            4'd3: begin //OR
                alu_src    = 1'b0;
                reg_write  = 1'b1;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 3'd3;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
            end
            4'd4: begin //ADDI
                alu_src    = 1'b1;
                reg_write  = 1'b1;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 3'd0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
            end
            4'd5: begin //BEQ
                alu_src    = 1'b0;
                reg_write  = 1'b0;
                branch     = 1'b1;
                jump       = 1'b0;
                alu_op     = 3'd1;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
            end
            4'd6: begin //JUMP
                alu_src    = 1'b0;
                reg_write  = 1'b0;
                branch     = 1'b0;
                jump       = 1'b1;
                alu_op     = 3'd0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
            end
            4'd7: begin //LOAD
                alu_src    = 1'b1;
                reg_write  = 1'b1;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 3'd0;
                mem_read   = 1'b1;
                mem_write  = 1'b0;
                mem_to_reg = 1'b1;
            end
            4'd8: begin //STORE
                alu_src    = 1'b1;
                reg_write  = 1'b0;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 3'd0;
                mem_read   = 1'b0;
                mem_write  = 1'b1;
                mem_to_reg = 1'b0;
            end
            4'd15: begin //NOP
                alu_src    = 1'b0;
                reg_write  = 1'b0;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 3'd0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
            end
        endcase
    end
endmodule
