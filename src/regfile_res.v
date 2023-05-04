`include "../sim/define.vh"

module regfile_res (
    input clk,
    input rst,
    input [`REG_RES_ADDR_WIDTH-1:0] wr_addr,
    input wr_en,
    input rd_en, 
    input [`ROM_DATA_WIDTH-1:0] D,
    output reg [`ROM_DATA_WIDTH*`REG_RES_SIZE-1:0] Q
);

reg [`ROM_DATA_WIDTH-1:0] memory [0:`REG_RES_SIZE-1];

integer i;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        for(i=0; i<`REG_RES_SIZE; i=i+1)begin
            memory[i] <= 0;
        end
    end
    else begin
        if(wr_en)begin
            memory[wr_addr] <= D;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        Q <= 0;
    end
    else begin
        if(rd_en)begin
            for(i=0; i<`REG_RES_SIZE; i=i+1)begin
                Q[`ROM_DATA_WIDTH*(i+1)-1 -: `ROM_DATA_WIDTH] <= memory[i];
            end
        end
    end
end
    
endmodule