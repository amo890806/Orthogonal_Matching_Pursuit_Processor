`include "../sim/define.vh"

module multiplier (
    input clk,
    input rst,
    input signed [`VMU_DATA_WIDTH-1:0] din1,
    input signed [`VMU_DATA_WIDTH-1:0] din2,
    output [`VMU_DATA_WIDTH-1:0] dout
);

reg [2*`VMU_DATA_WIDTH-1:0] mult;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        mult <= 0;
    end
    else begin
        mult <= din1 * din2;
    end
end

assign dout = {mult[37], mult[31:14]};
    
endmodule