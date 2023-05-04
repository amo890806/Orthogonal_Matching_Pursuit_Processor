`resetall
`include "../sim/define.vh"

module RAM_S (
    input CK,
    input [`RAM_S_ADDR_WIDTH-1:0] A,
    input WE,
    input OE,
    input [`RAM_S_DATA_WIDTH-1:0] D,
    output reg [`RAM_S_DATA_WIDTH-1:0] Q
);

integer i;

reg [`RAM_S_ADDR_WIDTH-1:0] latched_A;
reg [`RAM_S_DATA_WIDTH-1:0] memory [0:`RAM_S_MEM_SIZE-1];

always @(posedge CK) begin
    if (WE) begin
        memory[A] <= D;
    end
    latched_A <= A;
end

always @(OE or latched_A) begin
    if (OE) begin
        Q = memory[latched_A];
    end
    else begin
        Q = `RAM_S_DATA_WIDTH'hz;
    end
end
    
endmodule