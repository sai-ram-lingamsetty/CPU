`timescale 1ns/1ps
module cpu(
    input wire clk,rst_n
);
    wire [7:0] pc_plus_1;
    wire [7:0] jump_target,branch_target;
    wire [7:0] pc_next;
    wire [7:0] pc_out;
    wire [15:0] instruction;
    wire [3:0] opcode;
    wire [2:0] rd,rs1,rs2;
    wire [7:0] immediate;
    wire alu_src,reg_write,branch,jump,mem_read,mem_write,mem_to_reg;
    wire [2:0] alu_op;
    wire [7:0] write_data,read_data1,read_data2;
    wire [7:0] alu_b;
    wire zero;
    wire [2:0] rs2_stype;
    wire [7:0] alu_out;
    wire [7:0] mem_load;
    wire branch_taken;
    wire [2:0] rs2_beq;
    wire [7:0] beq_offset;

    wire [2:0] rs2_actual;
    assign rs2_actual = mem_write ? rs2_stype : (branch? rs2_beq:rs2);

    pc_incrementer pc_inc(pc_out,pc_plus_1);
    pc_mux mux1(pc_plus_1,jump_target,branch_target,branch_taken,jump,pc_next);
    pc_reg ff(clk,rst_n,pc_next,pc_out);
    instruction_memory mem1(pc_out,instruction);
    instruction_decoder id(instruction,opcode,rd,rs1,rs2,rs2_stype,rs2_beq,immediate,beq_offset);
    control_unit cu(opcode,alu_src,reg_write,branch,jump,mem_read,mem_write,mem_to_reg,alu_op);
    register_file rf(clk,rst_n,rs1,rs2_actual,rd,reg_write,write_data,read_data1,read_data2);
    alu_mux mux2(alu_src,read_data2,immediate,alu_b);
    alu comb(read_data1,alu_b,alu_op,alu_out,zero);
    data_memory mem2(clk,mem_read,mem_write & rst_n,alu_out,read_data2,mem_load);  // no stores while in reset
    write_back_mux mux3(mem_to_reg,alu_out,mem_load,write_data);

    assign branch_target = pc_plus_1 + beq_offset;
    assign jump_target   = immediate;
    assign branch_taken  = branch & zero;

endmodule
