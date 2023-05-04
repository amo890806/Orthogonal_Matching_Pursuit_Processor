`include "../sim/define.vh"

module regfile (
    input clk,
    input rst,
    input load_en,
    input [`REG_ADDR_WIDTH-1:0] wr_addr,
    input wr_en,
    input rd_en,
    input [`ROM_DATA_WIDTH-1:0] D,
    input [`ROM_DATA_WIDTH*`REG_SIZE-1:0] PD,
    output reg [`ROM_DATA_WIDTH*`REG_SIZE-1:0] Q
);

reg [`ROM_DATA_WIDTH-1:0] memory [0:`REG_SIZE-1];

integer i;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        for(i=0; i<`REG_SIZE; i=i+1)begin
            memory[i] <= 0;
        end
    end
    else begin
        if(load_en)begin
            for(i=0; i<`REG_SIZE; i=i+1)begin
                memory[i] <= PD[`ROM_DATA_WIDTH*(i+1)-1 -: `ROM_DATA_WIDTH];
            end
        end
        else begin
            if(wr_en)begin
                memory[wr_addr] <= D;
            end
        end
    end
end

always @(*) begin
    if(rd_en)begin
        for(i=0; i<`REG_SIZE; i=i+1)begin
            Q[`ROM_DATA_WIDTH*(i+1)-1 -: `ROM_DATA_WIDTH] = memory[i];
        end
    end
    else begin
        Q = 1215'hz;
    end
end
    
endmodule