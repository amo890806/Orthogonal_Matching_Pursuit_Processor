`include "../sim/define.vh"
`include "adder.v"

module adder_tree (
    input clk,
    input rst,
    input mode,
    input [`VMU_DATA_WIDTH*`ADDER_TREE_OP_NUM-1:0] vec,
    output reg [`VMU_DATA_WIDTH-1:0] sum,
    output [(`VMU_DATA_WIDTH*`ADDER_TREE_OP_NUM >> 1)-1:0] sub_vec
);

reg [(`ADDER_TREE_OP_NUM >> 3)*`VMU_DATA_WIDTH-1:0] dout1_temp;

//STAGE 1
wire [(`ADDER_TREE_OP_NUM >> 3)*`VMU_DATA_WIDTH-1:0] dout1;
genvar i;
generate
    for(i=0; i<(`ADDER_TREE_OP_NUM >> 3); i=i+1)begin : stage1_adder_label
        adder a(
            .clk(clk),
            .rst(rst),
            .mode(mode),
            .din1(vec[`VMU_DATA_WIDTH*(8*i+1)-1 -: `VMU_DATA_WIDTH]), 
            .din2(vec[`VMU_DATA_WIDTH*(8*i+2)-1 -: `VMU_DATA_WIDTH]), 
            .din3(vec[`VMU_DATA_WIDTH*(8*i+3)-1 -: `VMU_DATA_WIDTH]), 
            .din4(vec[`VMU_DATA_WIDTH*(8*i+4)-1 -: `VMU_DATA_WIDTH]),
            .din5(vec[`VMU_DATA_WIDTH*(8*i+5)-1 -: `VMU_DATA_WIDTH]),
            .din6(vec[`VMU_DATA_WIDTH*(8*i+6)-1 -: `VMU_DATA_WIDTH]),
            .din7(vec[`VMU_DATA_WIDTH*(8*i+7)-1 -: `VMU_DATA_WIDTH]),
            .din8(vec[`VMU_DATA_WIDTH*(8*i+8)-1 -: `VMU_DATA_WIDTH]),
            .dout(dout1[`VMU_DATA_WIDTH*(i+1)-1 -: `VMU_DATA_WIDTH]),
            .dout_vec(sub_vec[4*`VMU_DATA_WIDTH*(i+1)-1 -: 4*`VMU_DATA_WIDTH])
        );
    end
endgenerate


always @(posedge clk or posedge rst) begin
    if(rst)begin
        dout1_temp <= 0;
    end
    else begin
        dout1_temp <= dout1;
    end
end


//STAGE 2
// wire [(`ADDER_TREE_OP_NUM >> 6)*`VMU_DATA_WIDTH-1:0] dout2;
wire [`VMU_DATA_WIDTH-1:0] dout2;
genvar j;
generate
    for(j=0; j<(`ADDER_TREE_OP_NUM >> 6); j=j+1)begin : stage2_adder_label
        adder a(
            .clk(clk),
            .rst(rst),
            .mode(mode),
            .din1(dout1_temp[`VMU_DATA_WIDTH*(8*j+1)-1 -: `VMU_DATA_WIDTH]), 
            .din2(dout1_temp[`VMU_DATA_WIDTH*(8*j+2)-1 -: `VMU_DATA_WIDTH]), 
            .din3(dout1_temp[`VMU_DATA_WIDTH*(8*j+3)-1 -: `VMU_DATA_WIDTH]), 
            .din4(dout1_temp[`VMU_DATA_WIDTH*(8*j+4)-1 -: `VMU_DATA_WIDTH]),
            .din5(dout1_temp[`VMU_DATA_WIDTH*(8*j+5)-1 -: `VMU_DATA_WIDTH]),
            .din6(dout1_temp[`VMU_DATA_WIDTH*(8*j+6)-1 -: `VMU_DATA_WIDTH]),
            .din7(dout1_temp[`VMU_DATA_WIDTH*(8*j+7)-1 -: `VMU_DATA_WIDTH]),
            .din8(dout1_temp[`VMU_DATA_WIDTH*(8*j+8)-1 -: `VMU_DATA_WIDTH]),
            .dout(dout2[`VMU_DATA_WIDTH*(j+1)-1 -: `VMU_DATA_WIDTH]),
            .dout_vec()
        );
    end
endgenerate

//STAGE 3
always @(posedge clk or posedge rst) begin
    if(rst)begin
        sum <= 0;
    end
    else begin
        // sum <= $signed(dout2[2*`VMU_DATA_WIDTH-1:`VMU_DATA_WIDTH]) + $signed(dout2[`VMU_DATA_WIDTH-1:0]);
        sum <= dout2;
    end
end
    
endmodule
