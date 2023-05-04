`resetall
`include "../sim/define.vh"

module ROM_Y (
    input CK,
    input [`ROM_ADDR_WIDTH-1:0] A,
    input OE,
    output reg [`ROM_DATA_WIDTH-1:0] Q
);

reg [`ROM_ADDR_WIDTH-1:0] latched_A;
reg [`ROM_DATA_WIDTH-1:0] memory [0:`ROM_MEM_SIZE-1];

always @(posedge CK) begin
    latched_A <= A;
end

always @(OE or latched_A) begin
    if(OE)begin
        Q = memory[latched_A];
    end
    else begin
        Q = `ROM_DATA_WIDTH'hz;
    end
end
    
endmodule