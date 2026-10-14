`timescale 1ns/1ps

module instruction_decoder(
    input  wire [15:0] instruction,
    output wire [3:0]  opcode,
    output wire [2:0]  rd,
    output wire [2:0]  rs1,
    output wire [2:0]  rs2,
    output wire [2:0]  rs2_stype,  // S-type: rs2 sits at [11:9]
    output wire [2:0]  rs2_beq,    // B-type: rs2 sits at [5:3]
    output wire [7:0]  immediate,  // I/S-type: 6-bit sign-extended
    output wire [7:0]  beq_offset  // B-type: 3-bit sign-extended
);
    assign opcode     = instruction[15:12];
    assign rd         = instruction[11:9];  // R-type / I-type
    assign rs2_stype  = instruction[11:9];  // S-type (STORE): same bits as rd
    assign rs1        = instruction[8:6];
    assign rs2        = instruction[5:3];   // R-type
    assign rs2_beq    = instruction[5:3];   // B-type: same bits as rs2
    assign immediate  = {{2{instruction[5]}}, instruction[5:0]};  // 6-bit sign-ext
    assign beq_offset = {{5{instruction[2]}}, instruction[2:0]};  // 3-bit sign-ext
endmodule
