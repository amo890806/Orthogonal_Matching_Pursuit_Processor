`include "../sim/define.vh"
`include "multiplier.v"
`include "adder_tree.v"

module VMU (
    input clk,
    input rst,
    input vmu_en,
    input mode,
    input result_sel,
    input [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] vec1,
    input [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] vec2,
    output [`VMU_DATA_WIDTH-1:0] sum_result,
    output [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] mult_result,
    output [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] sub_result
);

wire [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] vec;
reg [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] vec_r1;
reg [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] vec_r2;
wire signed [`VMU_DATA_WIDTH-1:0] result;
wire [(`ADDER_TREE_OP_NUM*`VMU_DATA_WIDTH >> 1)-1:0] sub_vec1;
wire [(`ADDER_TREE_OP_NUM*`VMU_DATA_WIDTH >> 1)-1:0] sub_vec2;

integer j;

genvar i;
generate
    for(i=0; i<`VMU_OP_NUM; i=i+1)begin : multiplier_label
        wire [`VMU_DATA_WIDTH-1:0] vec_in1, vec_in2;
        assign vec_in1 = (mode == 0 && vmu_en) ? vec1[19*(i+1)-1 -: 19] : 0;
        assign vec_in2 = (mode == 0 && vmu_en) ? vec2[19*(i+1)-1 -: 19] : 0;
        multiplier m1(.clk(clk), .rst(rst), .din1(vec_in1), .din2(vec_in2), .dout(vec[19*(i+1)-1 -: 19]));
    end
endgenerate

always @(*) begin
    if(mode)begin
        if(vmu_en)begin
            for(j=0; j<(`ADDER_TREE_OP_NUM >> 1); j=j+1)begin
                vec_r1[2*`VMU_DATA_WIDTH*(j+1)-1 -: 2*`VMU_DATA_WIDTH] = {vec1[`VMU_DATA_WIDTH*(j+1)-1 -: `VMU_DATA_WIDTH], vec2[`VMU_DATA_WIDTH*(j+1)-1 -: `VMU_DATA_WIDTH]};
                vec_r2[2*`VMU_DATA_WIDTH*(j+1)-1 -: 2*`VMU_DATA_WIDTH] = {vec1[`VMU_DATA_WIDTH*(j+33)-1 -: `VMU_DATA_WIDTH], vec2[`VMU_DATA_WIDTH*(j+33)-1 -: `VMU_DATA_WIDTH]};
            end
        end
        else begin
            vec_r1 = 0;
            vec_r2 = 0;
        end
    end
    else begin
        vec_r1 = vec;
        vec_r2 = 0;
    end
end

adder_tree a_t1(.clk(clk), .rst(rst), .mode(mode), .vec(vec_r1), .sum(result), .sub_vec(sub_vec1));

genvar k;
generate
    for(k=0; k<(`VMU_OP_NUM >> 3); k=k+1)begin : subtracter_label
        adder a(
            .clk(clk),
            .rst(rst),
            .mode(mode),
            .din1(vec_r2[`VMU_DATA_WIDTH*(8*k+1)-1 -: `VMU_DATA_WIDTH]), 
            .din2(vec_r2[`VMU_DATA_WIDTH*(8*k+2)-1 -: `VMU_DATA_WIDTH]), 
            .din3(vec_r2[`VMU_DATA_WIDTH*(8*k+3)-1 -: `VMU_DATA_WIDTH]), 
            .din4(vec_r2[`VMU_DATA_WIDTH*(8*k+4)-1 -: `VMU_DATA_WIDTH]),
            .din5(vec_r2[`VMU_DATA_WIDTH*(8*k+5)-1 -: `VMU_DATA_WIDTH]),
            .din6(vec_r2[`VMU_DATA_WIDTH*(8*k+6)-1 -: `VMU_DATA_WIDTH]),
            .din7(vec_r2[`VMU_DATA_WIDTH*(8*k+7)-1 -: `VMU_DATA_WIDTH]),
            .din8(vec_r2[`VMU_DATA_WIDTH*(8*k+8)-1 -: `VMU_DATA_WIDTH]),
            .dout(),
            .dout_vec(sub_vec2[4*`VMU_DATA_WIDTH*(k+1)-1 -: 4*`VMU_DATA_WIDTH])
        );
    end
endgenerate

assign sum_result = (result_sel == 0) ? result : 0;
assign mult_result = (result_sel == 1) ? vec : 0;
assign sub_result = (mode == 1) ? {sub_vec2, sub_vec1} : 0;

endmodule