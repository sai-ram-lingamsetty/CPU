`timescale 1ns/1ps
module tb_cpu_full;

    localparam NUM_SEEDS  = 50;
    localparam NUM_CYCLES = 2000;

    reg clk   = 1'b0;
    reg rst_n = 1'b0;
    cpu dut (.clk(clk), .rst_n(rst_n));
    always #5 clk = ~clk;

    localparam OP_ADD  = 4'd0, OP_SUB = 4'd1, OP_AND = 4'd2, OP_OR  = 4'd3,
               OP_ADDI = 4'd4, OP_BEQ = 4'd5, OP_JMP = 4'd6, OP_LD  = 4'd7,
               OP_ST   = 4'd8, OP_NOP = 4'd15;

    function [15:0] enc_r;
        input [3:0] op; input [2:0] rd, rs1, rs2;
        enc_r = {op, rd, rs1, rs2, 3'b000};
    endfunction
    function [15:0] enc_i;
        input [3:0] op; input [2:0] rd, rs1; input [5:0] imm;
        enc_i = {op, rd, rs1, imm};
    endfunction
    function [15:0] enc_s;
        input [2:0] rs2, rs1; input [5:0] imm;
        enc_s = {OP_ST, rs2, rs1, imm};
    endfunction
    function [15:0] enc_b;
        input [2:0] rs1, rs2; input [2:0] off;
        enc_b = {OP_BEQ, 3'b000, rs1, rs2, off};
    endfunction
    function [15:0] enc_j;
        input [5:0] imm;
        enc_j = {OP_JMP, 6'b000000, imm};
    endfunction

    integer pass_cnt = 0;
    integer fail_cnt = 0;

    task chk_reg;
        input [2:0] r; input [7:0] exp; input [8*28-1:0] name;
        begin
            if (dut.rf.mem[r] === exp) begin
                pass_cnt = pass_cnt + 1;
                $display("  PASS [%0s] r%0d = %0d", name, r, dut.rf.mem[r]);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("  FAIL [%0s] r%0d = %0d, expected %0d", name, r, dut.rf.mem[r], exp);
            end
        end
    endtask

    task chk_mem;
        input [7:0] a; input [7:0] exp; input [8*28-1:0] name;
        begin
            if (dut.mem2.mem[a] === exp) begin
                pass_cnt = pass_cnt + 1;
                $display("  PASS [%0s] mem[%0d] = %0d", name, a, dut.mem2.mem[a]);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("  FAIL [%0s] mem[%0d] = %0d, expected %0d", name, a, dut.mem2.mem[a], exp);
            end
        end
    endtask

    task chk_pc;
        input [7:0] exp; input [8*28-1:0] name;
        begin
            if (dut.pc_out === exp) begin
                pass_cnt = pass_cnt + 1;
                $display("  PASS [%0s] PC = %0d", name, dut.pc_out);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("  FAIL [%0s] PC = %0d, expected %0d", name, dut.pc_out, exp);
            end
        end
    endtask

    task prog_clear;
        integer k;
        begin
            for (k = 0; k < 256; k = k + 1) begin
                dut.mem1.mem[k] = 16'hF000;
                dut.mem2.mem[k] = 8'h00;
            end
        end
    endtask

    task do_reset;
        begin
            rst_n = 1'b0;
            @(negedge clk);
            @(negedge clk);
        end
    endtask

    // Releases reset on a negedge so the next posedge executes ROM[0].
    task start;
        begin
            do_reset;
            rst_n = 1'b1;
        end
    endtask

    task run;
        input integer n;
        begin
            repeat (n) @(posedge clk);
            #1;
        end
    endtask

    task new_test;
        input [8*40-1:0] title;
        begin
            rst_n = 1'b0;
            prog_clear;
            $display("\n=== %0s ===", title);
        end
    endtask

    // Reference model, written from the ISA spec.
    reg [7:0] r_reg [0:7];
    reg [7:0] r_mem [0:255];
    reg [7:0] r_pc;

    task ref_reset;
        integer k;
        begin
            r_pc = 8'd0;
            for (k = 0; k < 8;   k = k + 1) r_reg[k] = 8'd0;
            for (k = 0; k < 256; k = k + 1) r_mem[k] = 8'd0;
        end
    endtask

    task ref_step;
        reg [15:0] ins;
        reg [3:0]  op;
        reg [2:0]  f_rd, f_rs1, f_rs2;
        reg [7:0]  imm, off, addr, npc;
        begin
            ins   = dut.mem1.mem[r_pc];
            op    = ins[15:12];
            f_rd  = ins[11:9];
            f_rs1 = ins[8:6];
            f_rs2 = ins[5:3];
            imm   = {{2{ins[5]}}, ins[5:0]};
            off   = {{5{ins[2]}}, ins[2:0]};
            npc   = r_pc + 8'd1;
            case (op)
                OP_ADD : r_reg[f_rd] = r_reg[f_rs1] + r_reg[f_rs2];
                OP_SUB : r_reg[f_rd] = r_reg[f_rs1] - r_reg[f_rs2];
                OP_AND : r_reg[f_rd] = r_reg[f_rs1] & r_reg[f_rs2];
                OP_OR  : r_reg[f_rd] = r_reg[f_rs1] | r_reg[f_rs2];
                OP_ADDI: r_reg[f_rd] = r_reg[f_rs1] + imm;
                OP_BEQ : if (r_reg[f_rs1] == r_reg[f_rs2]) npc = npc + off;
                OP_JMP : npc = imm;
                OP_LD  : begin addr = r_reg[f_rs1] + imm; r_reg[f_rd] = r_mem[addr]; end
                OP_ST  : begin addr = r_reg[f_rs1] + imm; r_mem[addr] = r_reg[f_rd]; end  // STORE data reg is [11:9]
                default: ;
            endcase
            r_pc = npc;
        end
    endtask

    integer rseed = 32'h1BADB002;
    reg [31:0] rx;

    task rand_instr;
        output [15:0] ins;
        reg [3:0] op;
        integer pick;
        begin
            rx   = $random(rseed);
            pick = rx[15:0] % 100;
            if (pick < 60) begin
                case (rx[26:24] % 7)
                    0: op = OP_ADD;  1: op = OP_SUB;  2: op = OP_AND;
                    3: op = OP_OR;   4: op = OP_ADDI; 5: op = OP_LD;
                    default: op = OP_ST;
                endcase
            end
            else if (pick < 75) op = OP_BEQ;
            else if (pick < 85) op = OP_JMP;
            else if (pick < 92) op = OP_NOP;
            else                op = 4'd9 + (rx[30:28] % 6);
            rx  = $random(rseed);
            ins = {op, rx[11:0]};
        end
    endtask

    integer s, c, a, k;
    integer rnd_fail_seeds;
    integer rnd_cycles_checked;
    reg     bad, stop;
    reg [15:0] tmp_ins;

    initial begin
        $dumpfile("cpu_full.vcd");
        $dumpvars(0, tb_cpu_full);

        $display("==================================================");
        $display("        CPU FULL TESTBENCH  -  START");
        $display("==================================================");

        new_test("T1  ADDI edge values");
        dut.mem1.mem[0] = enc_i(OP_ADDI, 1, 0, 6'd5);
        dut.mem1.mem[1] = enc_i(OP_ADDI, 2, 0, 6'd31);
        dut.mem1.mem[2] = enc_i(OP_ADDI, 3, 0, -6'sd1);
        dut.mem1.mem[3] = enc_i(OP_ADDI, 4, 0, -6'sd32);
        dut.mem1.mem[4] = enc_i(OP_ADDI, 5, 1, -6'sd5);
        dut.mem1.mem[5] = enc_i(OP_ADDI, 6, 2, 6'd31);
        dut.mem1.mem[6] = enc_i(OP_ADDI, 7, 3, 6'd1);
        start; run(7);
        chk_reg(1, 8'd5,   "ADDI +5");
        chk_reg(2, 8'd31,  "ADDI +31 max");
        chk_reg(3, 8'd255, "ADDI -1");
        chk_reg(4, 8'd224, "ADDI -32 min");
        chk_reg(5, 8'd0,   "ADDI rs1=r1,-5");
        chk_reg(6, 8'd62,  "ADDI rs1=r2,+31");
        chk_reg(7, 8'd0,   "ADDI wrap 255+1");

        new_test("T2  ADD SUB AND OR");
        dut.mem1.mem[0] = enc_i(OP_ADDI, 1, 0, 6'd31);
        dut.mem1.mem[1] = enc_i(OP_ADDI, 2, 0, -6'sd1);
        dut.mem1.mem[2] = enc_r(OP_ADD, 3, 1, 2);
        dut.mem1.mem[3] = enc_r(OP_SUB, 4, 1, 2);
        dut.mem1.mem[4] = enc_r(OP_SUB, 5, 2, 1);
        dut.mem1.mem[5] = enc_r(OP_AND, 6, 1, 2);
        dut.mem1.mem[6] = enc_r(OP_OR,  7, 1, 2);
        dut.mem1.mem[7] = enc_r(OP_ADD, 1, 1, 1);
        dut.mem1.mem[8] = enc_r(OP_SUB, 2, 2, 2);
        start; run(9);
        chk_reg(3, 8'd30,  "ADD overflow");
        chk_reg(4, 8'd32,  "SUB underflow");
        chk_reg(5, 8'd224, "SUB 255-31");
        chk_reg(6, 8'd31,  "AND");
        chk_reg(7, 8'd255, "OR");
        chk_reg(1, 8'd62,  "ADD r1,r1,r1");
        chk_reg(2, 8'd0,   "SUB r2,r2,r2");

        new_test("T2b AND/OR bit patterns");
        dut.mem1.mem[0] = enc_i(OP_ADDI, 1, 0, 6'd21);
        dut.mem1.mem[1] = enc_i(OP_ADDI, 2, 0, 6'd10);
        dut.mem1.mem[2] = enc_r(OP_AND, 3, 1, 2);
        dut.mem1.mem[3] = enc_r(OP_OR,  4, 1, 2);
        dut.mem1.mem[4] = enc_r(OP_AND, 5, 1, 1);
        dut.mem1.mem[5] = enc_r(OP_OR,  6, 2, 2);
        dut.mem1.mem[6] = enc_r(OP_SUB, 7, 1, 2);
        start; run(7);
        chk_reg(3, 8'd0,  "AND disjoint");
        chk_reg(4, 8'd31, "OR  disjoint");
        chk_reg(5, 8'd21, "AND a,a");
        chk_reg(6, 8'd10, "OR  b,b");
        chk_reg(7, 8'd11, "SUB 21-10");

        new_test("T3  LOAD / STORE");
        dut.mem1.mem[0]  = enc_i(OP_ADDI, 1, 0, 6'd7);
        dut.mem1.mem[1]  = enc_i(OP_ADDI, 2, 0, 6'd20);
        dut.mem1.mem[2]  = enc_s(1, 2, 6'd0);
        dut.mem1.mem[3]  = enc_s(1, 2, 6'd5);
        dut.mem1.mem[4]  = enc_s(2, 2, -6'sd4);
        dut.mem1.mem[5]  = enc_i(OP_LD, 3, 2, 6'd0);
        dut.mem1.mem[6]  = enc_i(OP_LD, 4, 2, 6'd5);
        dut.mem1.mem[7]  = enc_i(OP_LD, 5, 2, -6'sd4);
        dut.mem1.mem[8]  = enc_i(OP_LD, 6, 2, 6'd3);
        dut.mem1.mem[9]  = enc_s(1, 0, 6'd31);
        dut.mem1.mem[10] = enc_s(1, 0, -6'sd1);
        dut.mem1.mem[11] = enc_i(OP_LD, 7, 0, -6'sd1);
        start; run(12);
        chk_reg(3, 8'd7,  "LOAD 0(r2)");
        chk_reg(4, 8'd7,  "LOAD 5(r2)");
        chk_reg(5, 8'd20, "LOAD -4(r2)");
        chk_reg(6, 8'd0,  "LOAD untouched");
        chk_reg(7, 8'd7,  "LOAD -1(r0)=mem255");
        chk_reg(1, 8'd7,  "STORE keeps r1");
        chk_reg(2, 8'd20, "STORE keeps r2");
        chk_mem(8'd20,  8'd7,  "STORE 0(r2)");
        chk_mem(8'd25,  8'd7,  "STORE 5(r2)");
        chk_mem(8'd16,  8'd20, "STORE -4(r2) data=r2");
        chk_mem(8'd31,  8'd7,  "STORE 31(r0)");
        chk_mem(8'd255, 8'd7,  "STORE -1(r0)");
        chk_mem(8'd23,  8'd0,  "mem[23] untouched");

        new_test("T4  BEQ forward / not-taken");
        dut.mem1.mem[0]  = enc_i(OP_ADDI, 1, 0, 6'd5);
        dut.mem1.mem[1]  = enc_i(OP_ADDI, 2, 0, 6'd5);
        dut.mem1.mem[2]  = enc_b(1, 2, 3'd1);
        dut.mem1.mem[3]  = enc_i(OP_ADDI, 3, 0, 6'd9);
        dut.mem1.mem[4]  = enc_i(OP_ADDI, 4, 0, 6'd1);
        dut.mem1.mem[5]  = enc_i(OP_ADDI, 5, 0, 6'd3);
        dut.mem1.mem[6]  = enc_b(1, 5, 3'd2);
        dut.mem1.mem[7]  = enc_i(OP_ADDI, 6, 0, 6'd2);
        dut.mem1.mem[8]  = enc_b(1, 2, 3'd3);
        dut.mem1.mem[9]  = enc_i(OP_ADDI, 7, 0, 6'd1);
        dut.mem1.mem[10] = enc_i(OP_ADDI, 7, 0, 6'd1);
        dut.mem1.mem[11] = enc_i(OP_ADDI, 7, 0, 6'd1);
        dut.mem1.mem[12] = enc_i(OP_ADDI, 3, 0, 6'd4);
        start; run(9);
        chk_reg(3, 8'd4, "BEQ +1 skip, +3 land");
        chk_reg(4, 8'd1, "BEQ +1 target");
        chk_reg(6, 8'd2, "BEQ not taken falls thru");
        chk_reg(7, 8'd0, "BEQ +3 skipped 3 instrs");
        chk_pc(8'd13, "PC after 9 instrs");

        new_test("T4b BEQ offset 0 / unequal");
        dut.mem1.mem[0] = enc_i(OP_ADDI, 1, 0, 6'd1);
        dut.mem1.mem[1] = enc_b(1, 0, 3'd0);
        dut.mem1.mem[2] = enc_b(1, 1, 3'd0);
        dut.mem1.mem[3] = enc_i(OP_ADDI, 2, 0, 6'd9);
        start; run(4);
        chk_reg(2, 8'd9, "BEQ off=0 same path");
        chk_pc(8'd4, "PC after BEQ off=0");

        new_test("T4c BEQ equal at 0 / 255");
        dut.mem1.mem[0]  = enc_i(OP_ADDI, 1, 0, -6'sd1);
        dut.mem1.mem[1]  = enc_i(OP_ADDI, 2, 0, -6'sd1);
        dut.mem1.mem[2]  = enc_b(1, 2, 3'd1);
        dut.mem1.mem[3]  = enc_i(OP_ADDI, 3, 0, 6'd1);
        dut.mem1.mem[4]  = enc_r(OP_ADD, 4, 1, 1);
        dut.mem1.mem[5]  = enc_r(OP_ADD, 5, 4, 4);
        dut.mem1.mem[6]  = enc_b(0, 3, 3'd1);
        dut.mem1.mem[7]  = enc_i(OP_ADDI, 6, 0, 6'd1);
        dut.mem1.mem[8]  = enc_i(OP_ADDI, 7, 0, 6'd7);
        start; run(8);
        chk_reg(3, 8'd0, "BEQ 255==255 skip");
        chk_reg(6, 8'd0, "BEQ 0==0 skip");
        chk_reg(7, 8'd7, "BEQ landing instr");

        new_test("T4d BEQ backward (-4) loop");
        dut.mem1.mem[0] = enc_i(OP_ADDI, 1, 0, 6'd3);
        dut.mem1.mem[1] = enc_i(OP_ADDI, 2, 0, 6'd0);
        dut.mem1.mem[2] = enc_i(OP_ADDI, 2, 2, 6'd2);
        dut.mem1.mem[3] = enc_i(OP_ADDI, 1, 1, -6'sd1);
        dut.mem1.mem[4] = enc_b(1, 0, 3'd2);
        dut.mem1.mem[5] = enc_b(0, 0, -3'sd4);
        dut.mem1.mem[6] = enc_i(OP_ADDI, 3, 0, 6'd31);
        dut.mem1.mem[7] = enc_s(2, 0, 6'd30);
        dut.mem1.mem[8] = enc_j(6'd8);
        start; run(30);
        chk_reg(1, 8'd0, "loop counter = 0");
        chk_reg(2, 8'd6, "loop acc = 6");
        chk_reg(3, 8'd0, "dead code not executed");
        chk_mem(8'd30, 8'd6, "mem[30] = acc");
        chk_pc(8'd8, "halted at JUMP 8");

        new_test("T5  JUMP + PC wrap-around");
        dut.mem1.mem[0]   = enc_j(6'd5);
        dut.mem1.mem[1]   = enc_i(OP_ADDI, 1, 0, 6'd1);
        dut.mem1.mem[5]   = enc_i(OP_ADDI, 2, 0, 6'd2);
        dut.mem1.mem[6]   = enc_j(6'd31);
        dut.mem1.mem[31]  = enc_i(OP_ADDI, 3, 0, 6'd3);
        dut.mem1.mem[32]  = enc_j(-6'sd32);
        dut.mem1.mem[224] = enc_i(OP_ADDI, 4, 0, 6'd4);
        dut.mem1.mem[225] = enc_j(-6'sd1);
        dut.mem1.mem[255] = enc_i(OP_ADDI, 5, 0, 6'd5);
        start; run(8);
        chk_reg(1, 8'd0, "JUMP fwd skipped instr");
        chk_reg(2, 8'd2, "JUMP 5");
        chk_reg(3, 8'd3, "JUMP 31");
        chk_reg(4, 8'd4, "JUMP -32 -> 224");
        chk_reg(5, 8'd5, "JUMP -1  -> 255");
        chk_pc(8'd0, "PC wrapped 255 -> 0");

        new_test("T6  NOP / undefined opcodes");
        dut.mem1.mem[0] = enc_i(OP_ADDI, 1, 0, 6'd5);
        dut.mem1.mem[1] = 16'hF000;
        dut.mem1.mem[2] = 16'h92D9;
        dut.mem1.mem[3] = 16'hA2D9;
        dut.mem1.mem[4] = 16'hB2D9;
        dut.mem1.mem[5] = 16'hC2D9;
        dut.mem1.mem[6] = 16'hD2D9;
        dut.mem1.mem[7] = 16'hE2D9;
        dut.mem1.mem[8] = 16'hFABC;
        dut.mem1.mem[9] = enc_i(OP_ADDI, 2, 0, 6'd1);
        start; run(10);
        chk_reg(1, 8'd5, "r1 unchanged by NOPs");
        chk_reg(2, 8'd1, "r2 executes after NOPs");
        chk_reg(3, 8'd0, "undef op wrote nothing r3");
        chk_reg(4, 8'd0, "undef op wrote nothing r4");
        chk_reg(5, 8'd0, "undef op wrote nothing r5");
        chk_reg(6, 8'd0, "undef op wrote nothing r6");
        chk_reg(7, 8'd0, "undef op wrote nothing r7");
        chk_mem(8'd0,   8'd0, "no stray mem write @0");
        chk_mem(8'd217, 8'd0, "no stray mem write @0xD9");
        chk_pc(8'd10, "PC after NOP run");

        new_test("T7  don't-care fields");
        dut.mem1.mem[0] = enc_i(OP_ADDI, 1, 0, 6'd4);
        dut.mem1.mem[1] = enc_i(OP_ADDI, 2, 0, 6'd6);
        dut.mem1.mem[2] = {OP_ADD, 3'd3, 3'd1, 3'd2, 3'b111};
        dut.mem1.mem[3] = {OP_BEQ, 3'b111, 3'd1, 3'd1, 3'd1};
        dut.mem1.mem[4] = enc_i(OP_ADDI, 7, 0, 6'd9);
        dut.mem1.mem[5] = {OP_JMP, 6'b111111, 6'd8};
        dut.mem1.mem[6] = enc_i(OP_ADDI, 6, 0, 6'd1);
        dut.mem1.mem[8] = enc_i(OP_ADDI, 5, 0, 6'd5);
        start; run(7);
        chk_reg(3, 8'd10, "R-type ignores [2:0]");
        chk_reg(7, 8'd0,  "BEQ junk rd: no write");
        chk_reg(6, 8'd0,  "JUMP junk bits ok");
        chk_reg(5, 8'd5,  "JUMP landed at 8");

        new_test("T8  sum 1..5 loop");
        dut.mem1.mem[0] = enc_i(OP_ADDI, 1, 0, 6'd5);
        dut.mem1.mem[1] = enc_i(OP_ADDI, 2, 0, 6'd0);
        dut.mem1.mem[2] = enc_b(1, 0, 3'd3);
        dut.mem1.mem[3] = enc_r(OP_ADD, 2, 2, 1);
        dut.mem1.mem[4] = enc_i(OP_ADDI, 1, 1, -6'sd1);
        dut.mem1.mem[5] = enc_j(6'd2);
        dut.mem1.mem[6] = enc_s(2, 0, 6'd20);
        dut.mem1.mem[7] = enc_i(OP_LD, 3, 0, 6'd20);
        dut.mem1.mem[8] = enc_j(6'd8);
        start; run(60);
        chk_reg(1, 8'd0,  "counter = 0");
        chk_reg(2, 8'd15, "sum = 15");
        chk_reg(3, 8'd15, "reloaded sum = 15");
        chk_mem(8'd20, 8'd15, "mem[20] = 15");
        chk_pc(8'd8, "halted at 8");

        new_test("T9  original program.mem");
        dut.mem1.mem[0]  = 16'h4205;  dut.mem1.mem[1]  = 16'h4403;
        dut.mem1.mem[2]  = 16'h0650;  dut.mem1.mem[3]  = 16'h1850;
        dut.mem1.mem[4]  = 16'h2A50;  dut.mem1.mem[5]  = 16'h3C50;
        dut.mem1.mem[6]  = 16'h820A;  dut.mem1.mem[7]  = 16'h7E0A;
        dut.mem1.mem[8]  = 16'h5049;  dut.mem1.mem[9]  = 16'h421F;
        dut.mem1.mem[10] = 16'hF000;  dut.mem1.mem[11] = 16'h6000;
        start; run(11);
        chk_reg(1, 8'd5, "r1 = 5 (addr9 skipped)");
        chk_reg(2, 8'd3, "r2 = 3");
        chk_reg(3, 8'd8, "r3 = 8");
        chk_reg(4, 8'd2, "r4 = 2");
        chk_reg(5, 8'd1, "r5 = 1");
        chk_reg(6, 8'd7, "r6 = 7");
        chk_reg(7, 8'd5, "r7 = 5 (LOAD)");
        chk_mem(8'd10, 8'd5, "mem[10] = 5 (STORE)");
        chk_pc(8'd0, "JUMP 0 -> PC = 0");

        new_test("T10 reset mid-run");
        dut.mem1.mem[0] = enc_i(OP_ADDI, 1, 0, 6'd5);
        dut.mem1.mem[1] = enc_s(1, 0, 6'd3);
        dut.mem1.mem[2] = enc_j(6'd2);
        start; run(5);
        chk_reg(1, 8'd5, "pre-reset r1 = 5");
        chk_pc(8'd2, "pre-reset PC = 2");
        rst_n = 1'b0; #1;
        chk_reg(1, 8'd0, "post-reset r1 = 0");
        chk_pc(8'd0, "post-reset PC = 0");
        @(negedge clk); rst_n = 1'b1; run(2);
        chk_reg(1, 8'd5, "re-executes from 0");

        // Informational only, not counted as pass/fail.
        new_test("INFO design observations");
        dut.mem1.mem[0] = enc_i(OP_ADDI, 0, 0, 6'd5);
        dut.mem1.mem[1] = enc_i(OP_ADDI, 1, 0, 6'd0);
        start; run(2);
        $display("  INFO: r0 is writable -> r0 = %0d, r1 = %0d (r0 is NOT hard-wired to 0)",
                 dut.rf.mem[0], dut.rf.mem[1]);

        new_test("INFO store during reset");
        dut.mem1.mem[0] = enc_s(0, 0, 6'd3);
        rst_n = 1'b0;
        dut.mem2.mem[3] = 8'd99;
        @(negedge clk); @(negedge clk); @(negedge clk);
        $display("  INFO: ROM[0]=STORE executed while rst_n=0 -> mem[3] = %0d (99 means safe, 0 means overwritten)",
                 dut.mem2.mem[3]);

        $display("\n==================================================");
        $display("  RANDOM DIFFERENTIAL TEST: %0d programs x %0d cycles", NUM_SEEDS, NUM_CYCLES);
        $display("==================================================");
        rnd_fail_seeds     = 0;
        rnd_cycles_checked = 0;

        for (s = 0; s < NUM_SEEDS; s = s + 1) begin
            rst_n = 1'b0;
            for (a = 0; a < 256; a = a + 1) begin
                rand_instr(tmp_ins);
                dut.mem1.mem[a] = tmp_ins;
                dut.mem2.mem[a] = 8'h00;
            end
            ref_reset;
            start;
            stop = 1'b0;
            for (c = 0; c < NUM_CYCLES && !stop; c = c + 1) begin
                @(posedge clk);
                ref_step;
                #1;
                bad = (dut.pc_out !== r_pc);
                for (k = 0; k < 8; k = k + 1)
                    if (dut.rf.mem[k] !== r_reg[k]) bad = 1'b1;
                rnd_cycles_checked = rnd_cycles_checked + 1;
                if (bad) begin
                    stop = 1'b1;
                    rnd_fail_seeds = rnd_fail_seeds + 1;
                    fail_cnt = fail_cnt + 1;
                    $display("  FAIL random prog %0d cycle %0d: DUT pc=%0d model pc=%0d", s, c, dut.pc_out, r_pc);
                    for (k = 0; k < 8; k = k + 1)
                        $display("       r%0d  DUT=%0d  model=%0d %0s", k, dut.rf.mem[k], r_reg[k],
                                 (dut.rf.mem[k] !== r_reg[k]) ? "<-- MISMATCH" : "");
                end
            end
            if (!stop) begin
                for (a = 0; a < 256; a = a + 1)
                    if (dut.mem2.mem[a] !== r_mem[a]) begin
                        fail_cnt = fail_cnt + 1;
                        rnd_fail_seeds = rnd_fail_seeds + 1;
                        $display("  FAIL random prog %0d: mem[%0d] DUT=%0d model=%0d", s, a, dut.mem2.mem[a], r_mem[a]);
                        a = 256;
                    end
            end
        end
        if (rnd_fail_seeds == 0) begin
            pass_cnt = pass_cnt + 1;
            $display("  PASS random: %0d cycles compared (PC + 8 regs each cycle, full data mem per program)", rnd_cycles_checked);
        end

        $display("\n==================================================");
        $display("  SUMMARY : %0d passed, %0d failed", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("  *** ALL TESTS PASSED ***");
        else               $display("  *** SOME TESTS FAILED ***");
        $display("==================================================");
        $finish;
    end

    initial begin
        #20000000;
        $display("WATCHDOG TIMEOUT");
        $finish;
    end

endmodule
