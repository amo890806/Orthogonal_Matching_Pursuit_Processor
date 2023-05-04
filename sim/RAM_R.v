`resetall
`include "../sim/define.vh"

module RAM_R (
    input CK,
    input [`RAM_R_ADDR_WIDTH-1:0] A,
    input WE,
    input OE,
    input [`RAM_R_DATA_WIDTH-1:0] D,
    output reg [8*`RAM_R_DATA_WIDTH-1:0] Q
);

integer i;

reg [8*`RAM_R_ADDR_WIDTH-1:0] latched_A;
reg [`RAM_R_DATA_WIDTH-1:0] memory [0:`RAM_R_MEM_SIZE-1];

always @(posedge CK) begin
    if (WE) begin
        memory[A] <= D;
    end
    if(A < 8)begin
        for(i=0; i<8; i=i+1)begin
            latched_A[`RAM_R_ADDR_WIDTH*(i+1)-1 -: `RAM_R_ADDR_WIDTH] <= A*8+i;
        end
    end
    else begin
        latched_A = 0;
    end
end

always @(OE or latched_A) begin
    if (OE) begin
        for(i=0; i<8; i=i+1)begin
            Q[`RAM_R_DATA_WIDTH*(i+1)-1 -: `RAM_R_DATA_WIDTH] = memory[latched_A[`RAM_R_ADDR_WIDTH*(i+1)-1 -: `RAM_R_ADDR_WIDTH]];
        end
    end
    else begin
        Q = 151'hz;
    end
end
    
endmodule
