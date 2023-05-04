`include "../sim/define.vh"

module regfile_div (
    input clk,
    input rst,
    input wr_en,
    input rd_en,
    input [`REG_DIV_ADDR_WIDTH-1:0] addr,
    input [`REG_DIV_DATA_WIDTH-1:0] D,
    output reg [`REG_DIV_DATA_WIDTH-1:0] Q
);

reg [`REG_DIV_DATA_WIDTH-1:0] memory [0:`REG_DIV_SIZE-1];

integer i;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        for(i=0; i<`REG_DIV_SIZE; i=i+1)begin
            memory[i] <= 0;
        end
    end
    else begin
        if(wr_en)begin
            memory[addr] <= D;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        Q <= 0;
    end
    else begin
        if(rd_en)begin
            Q <= memory[addr];
        end
    end
end

endmodule