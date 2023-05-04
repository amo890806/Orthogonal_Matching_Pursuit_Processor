`include "../sim/define.vh"
`include "addr_decoder.v"

module MAX (
    input clk,
    input rst,
    input max_en,
    input signed [`VMU_DATA_WIDTH-1:0] value,
    input [`REG_IDX_DATA_WIDTH-1:0] idx,
    output [`RAM_THETA_ADDR_WIDTH-1:0] max_addr,
    output reg [`REG_IDX_DATA_WIDTH-1:0] max_idx
);

wire [`VMU_DATA_WIDTH-1:0] abs_value = (value[`VMU_DATA_WIDTH-1]) ? ((value == 0)?0:~(value)+1) : value;
reg signed [`VMU_DATA_WIDTH-1:0] max_value;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        max_idx <= 0;
        max_value <= 0;
    end
    else begin
        if(max_en)begin
            if(idx == 0)begin
                max_idx <= idx;
                max_value <= abs_value;
            end
            else begin
                if(abs_value > max_value)begin
                    max_idx <= idx;
                    max_value <= abs_value;
                end
            end
        end
    end
end

addr_decoder addr_decoder(
    .idx(max_idx),
    .addr(max_addr)
);
    
endmodule