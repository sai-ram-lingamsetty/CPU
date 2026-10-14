`timescale 1ns/1ps
module data_memory(
    input wire clk,
    input wire mem_read,
    input wire mem_write,
    input wire [7:0] address,
    input wire [7:0] write_data,
    output wire [7:0] read_data
);
    reg [7:0] mem [255:0];

    integer j;
    initial begin
        for(j = 0; j < 256; j = j+1)
            mem[j] = 8'd0;
    end

    always @(posedge clk) begin
        if(mem_write)
            mem[address] <= write_data;
    end

    assign read_data = mem_read ? mem[address] : 8'd0;

endmodule
