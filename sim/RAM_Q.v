`resetall
`include "../sim/define.vh"

module RAM_Q (
    input CK,
    input [`RAM_Q_ADDR_WIDTH-1:0] A,
    input WE,
    input OE,
    input [`RAM_Q_DATA_WIDTH-1:0] D,
    output reg [`RAM_Q_DATA_WIDTH-1:0] Q
);

reg [`RAM_Q_ADDR_WIDTH-1:0] latched_A;
reg [19-1:0] memory [0:`RAM_Q_MEM_SIZE-1];

integer i;

always @(posedge CK) begin
    if (WE) begin
        for(i=0; i<64; i=i+1)begin
            memory[A[9*(i+1)-1 -: 9]] <= D[19*(i+1)-1 -: 19];
        end
    end
    latched_A <= A;
end

always @(OE or latched_A) begin
    if (OE) begin
        for(i=0; i<64; i=i+1)begin
            Q[19*(i+1)-1 -: 19] = memory[latched_A[9*(i+1)-1 -: 9]];
        end
    end
    else begin
        Q = `RAM_Q_DATA_WIDTH'hz;
    end
end
    
endmodule