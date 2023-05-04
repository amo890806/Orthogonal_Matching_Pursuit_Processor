`include "../sim/define.vh"

module addr_decoder (
    input [`REG_IDX_DATA_WIDTH-1:0] idx,
    output [`RAM_THETA_ADDR_WIDTH-1:0] addr
);

integer i;

reg [`RAM_THETA_ADDR_WIDTH-1:0] addr_temp;

always @(*) begin
    for(i=0; i<`ROM_MEM_SIZE; i=i+1)begin
        addr_temp[14*(i+1)-1 -: 14] = (i << 8) + idx;
    end
end

assign addr = addr_temp;
    
endmodule