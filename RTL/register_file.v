`timescale 1ns/1ps
module register_file(
    input wire clk,rst_n,
    input wire [2:0] rs1,
    input wire [2:0] rs2,
    input wire [2:0] rd,
    input wire write_en,
    input wire [7:0] write_data,
    output wire [7:0] read_data1,
    output wire [7:0] read_data2
);
    reg [7:0] mem [7:0];
    integer i;
    
    assign read_data1 = mem[rs1];
    assign read_data2 = mem[rs2];
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<8;i=i+1) begin
                mem[i] <= 8'd0;
            end
        end else if(write_en) begin
                mem[rd] <= write_data;
        end
    end

endmodule 
