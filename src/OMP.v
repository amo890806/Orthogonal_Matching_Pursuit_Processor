`include "../sim/define.vh"
`include "controller.v"
`include "regfile.v"
`include "addr_mux.v"
`include "data_mux.v"
`include "VMU.v"
`include "MAX.v"
`include "regfile_idx.v"
`include "regfile_theta.v"
`include "regfile_div.v"
`include "CORDIC.v"
`include "regfile_res.v"
`include "BS_MULT.v"

module OMP (
    input clk,
    input rst,
    input start,
    input [`ROM_DATA_WIDTH-1:0] ROM_Y_Q,
    output [`ROM_ADDR_WIDTH-1:0] ROM_Y_A,
    output ROM_Y_OE,
    input [`RAM_Q_DATA_WIDTH-1:0] RAM_Q_Q,
    output [`RAM_Q_ADDR_WIDTH-1:0] RAM_Q_A,
    output RAM_Q_OE,
    output [`RAM_Q_DATA_WIDTH-1:0] RAM_Q_D,
    output RAM_Q_WE,
    input [8*`RAM_R_DATA_WIDTH-1:0] RAM_R_Q,
    output [`RAM_R_ADDR_WIDTH-1:0] RAM_R_A,
    output RAM_R_OE,
    output [`RAM_R_DATA_WIDTH-1:0] RAM_R_D,
    output RAM_R_WE,
    input [`RAM_THETA_DATA_WIDTH-1:0] RAM_THETA_Q,
    output [`RAM_THETA_ADDR_WIDTH-1:0] RAM_THETA_A,
    output RAM_THETA_OE,
    output [`RAM_THETA_DATA_WIDTH-1:0] RAM_THETA_D,
    output RAM_THETA_WE,
    input [8*`RAM_R_DATA_WIDTH-1:0] RAM_INV_R_Q,
    output [`RAM_R_ADDR_WIDTH-1:0] RAM_INV_R_A,
    output RAM_INV_R_OE,
    output [`RAM_R_DATA_WIDTH-1:0] RAM_INV_R_D,
    output RAM_INV_R_WE,
    output RAM_INV_R_Q_SEL,
    input [`RAM_S_DATA_WIDTH-1:0] RAM_S_Q,
    output [`RAM_S_ADDR_WIDTH-1:0] RAM_S_A,
    output RAM_S_OE,
    output [`RAM_S_DATA_WIDTH-1:0] RAM_S_D,
    output RAM_S_WE,
    output done
);

wire [`REG_ADDR_WIDTH-1:0] reg_wr_addr;
wire reg_wr_en, reg_rd_en, reg_load_en, data_mux_en, vmu_en, vmu_theta_en;
wire max_en;
wire bs_mult_en, bs_clear_en;
wire load_theta_en;
wire ram_theta_addr_sel;
wire [2:0] vec1_data_sel, vec2_data_sel;
wire result_sel;
wire vmu_mode;
wire [`REG_IDX_DATA_WIDTH-1:0] vmu_idx;
wire [`ROM_DATA_WIDTH*`REG_SIZE-1:0] reg_y_Q;
wire [`VMU_DATA_WIDTH-1:0] sum_result;
wire [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] mult_result;
wire [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] sub_result;
wire [`VMU_ADDR_WIDTH-1:0] max_result_idx;
wire [`RAM_THETA_ADDR_WIDTH-1:0] max_addr;
wire [`REG_IDX_DATA_WIDTH-1:0] max_idx;
wire [`RAM_THETA_ADDR_WIDTH-1:0] theta_addr;
wire [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] vec1;
wire [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] vec2;
wire rd_theta_en;
wire [`RAM_THETA_DATA_WIDTH-1:0] reg_theta_Q;
wire [`RAM_THETA_DATA_WIDTH-1:0] reg_theta_D;
wire [`REG_RES_ADDR_WIDTH-1:0] reg_res_wr_addr;
wire reg_res_wr_en, reg_res_rd_en;
wire[`ROM_DATA_WIDTH*`REG_RES_SIZE-1:0] reg_res_Q;
wire reg_idx_wr_en, reg_idx_rd_en;
wire [`REG_IDX_DATA_WIDTH-1:0] reg_idx_Q;
wire [`REG_IDX_ADDR_WIDTH-1:0] reg_idx_addr;
wire reg_div_wr_en, reg_div_rd_en;
wire signed [`REG_DIV_DATA_WIDTH-1:0] reg_div_Q;
wire [`REG_DIV_ADDR_WIDTH-1:0] reg_div_addr;
wire [1:0] scaler_sel;
wire reg_theta_data_sel;
wire identity_flag;
wire signed [`VMU_DATA_WIDTH-1:0] sum_result_temp;
wire ram_r_data_sel;

wire [`CORDIC_DATA_WIDTH-1:0] cordic_in;
wire [`CORDIC_DATA_WIDTH-1:0] cordic_out;
wire cordic_en, cordic_sel, cordic_result_sel;

reg [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] scaler_vec;
reg [2*`RAM_R_DATA_WIDTH-1:0] RAM_INV_R_D_TEMP;

assign cordic_in = (cordic_sel) ? cordic_out : sum_result;
assign reg_theta_D = (reg_theta_data_sel) ? sub_result : RAM_THETA_Q[`RAM_THETA_DATA_WIDTH-1:0];
assign RAM_Q_D = mult_result[`RAM_Q_DATA_WIDTH-1:0];
assign RAM_R_D = (ram_r_data_sel) ? sum_result : cordic_out;
assign sum_result_temp = (sum_result == 0) ? 0 : ~(sum_result)+1; 
assign RAM_INV_R_D = {RAM_INV_R_D_TEMP[37], RAM_INV_R_D_TEMP[31:14]};
assign RAM_S_A = reg_idx_Q;

integer i;

always @(*) begin
    case (scaler_sel)
        0:begin
            for(i=0; i<`VMU_OP_NUM; i=i+1)begin
                scaler_vec[`VMU_DATA_WIDTH*(i+1)-1 -: `VMU_DATA_WIDTH] = cordic_out;
            end
        end
        1:begin
            for(i=0; i<`VMU_OP_NUM; i=i+1)begin
                scaler_vec[`VMU_DATA_WIDTH*(i+1)-1 -: `VMU_DATA_WIDTH] = RAM_Q_Q[19*(vmu_idx+1)-1 -: 19];
            end
        end
        2:begin
            for(i=0; i<`VMU_OP_NUM; i=i+1)begin
                scaler_vec[`VMU_DATA_WIDTH*(i+1)-1 -: `VMU_DATA_WIDTH] = sum_result;
            end
        end 
        default: begin
            for(i=0; i<`VMU_OP_NUM; i=i+1)begin
                scaler_vec[`VMU_DATA_WIDTH*(i+1)-1 -: `VMU_DATA_WIDTH] = cordic_out;
            end
        end
    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        RAM_INV_R_D_TEMP <= 0;
    end
    else begin
        RAM_INV_R_D_TEMP <= (identity_flag) ? (sum_result_temp+16384)*reg_div_Q : sum_result_temp*reg_div_Q;
    end
end

controller controller(
    .clk(clk),
    .rst(rst),
    .start(start),
    .ROM_Y_A(ROM_Y_A),
    .ROM_Y_OE(ROM_Y_OE),
    .RAM_Q_A(RAM_Q_A),
    .RAM_Q_OE(RAM_Q_OE),
    .RAM_Q_WE(RAM_Q_WE),
    .RAM_R_A(RAM_R_A),
    .RAM_R_OE(RAM_R_OE),
    .RAM_R_WE(RAM_R_WE),
    .RAM_THETA_A(theta_addr),
    .RAM_THETA_OE(RAM_THETA_OE),
    .RAM_THETA_D(RAM_THETA_D),
    .RAM_THETA_WE(RAM_THETA_WE),
    .RAM_INV_R_A(RAM_INV_R_A),
    .RAM_INV_R_OE(RAM_INV_R_OE),
    .RAM_INV_R_WE(RAM_INV_R_WE),
    .RAM_INV_R_Q_SEL(RAM_INV_R_Q_SEL),
    .RAM_S_OE(RAM_S_OE),
    .RAM_S_WE(RAM_S_WE),
    .reg_wr_addr(reg_wr_addr),
    .reg_wr_en(reg_wr_en),
    .reg_rd_en(reg_rd_en),
    .reg_load_en(reg_load_en),
    .data_mux_en(data_mux_en),
    .vmu_en(vmu_en),
    .load_theta_en(load_theta_en),
    .rd_theta_en(rd_theta_en),
    .vmu_mode(vmu_mode),
    .vmu_idx(vmu_idx),
    .max_en(max_en),
    .ram_theta_addr_sel(ram_theta_addr_sel),
    .vec1_data_sel(vec1_data_sel),
    .vec2_data_sel(vec2_data_sel),
    .result_sel(result_sel),
    .scaler_sel(scaler_sel),
    .cordic_en(cordic_en),
    .cordic_sel(cordic_sel),
    .cordic_result_sel(cordic_result_sel),
    .bs_mult_en(bs_mult_en),
    .bs_clear_en(bs_clear_en),
    .reg_res_wr_addr(reg_res_wr_addr),
    .reg_res_wr_en(reg_res_wr_en),
    .reg_res_rd_en(reg_res_rd_en),
    .reg_idx_wr_en(reg_idx_wr_en),
    .reg_idx_rd_en(reg_idx_rd_en),
    .reg_idx_addr(reg_idx_addr),
    .reg_div_wr_en(reg_div_wr_en),
    .reg_div_rd_en(reg_div_rd_en),
    .reg_div_addr(reg_div_addr),
    .ram_r_data_sel(ram_r_data_sel),
    .reg_theta_data_sel(reg_theta_data_sel),
    .identity_flag(identity_flag),
    .done(done)
);

regfile regfile(
    .clk(clk),
    .rst(rst),
    .load_en(reg_load_en),
    .wr_addr(reg_wr_addr),
    .wr_en(reg_wr_en),
    .rd_en(reg_rd_en),
    .D(ROM_Y_Q),
    .PD(sub_result),
    .Q(reg_y_Q)
);

regfile_idx regfile_idx(
    .clk(clk),
    .rst(rst),
    .wr_en(reg_idx_wr_en),
    .rd_en(reg_idx_rd_en),
    .addr(reg_idx_addr),
    .D(max_idx),
    .Q(reg_idx_Q)
);

regfile_theta regfile_theta(
    .clk(clk),
    .rst(rst),
    .load_en(load_theta_en),
    .rd_en(rd_theta_en),
    .din(reg_theta_D),
    .dout(reg_theta_Q)
);

regfile_div regfile_div(
    .clk(clk),
    .rst(rst),
    .wr_en(reg_div_wr_en),
    .rd_en(reg_div_rd_en),
    .addr(reg_div_addr),
    .D(cordic_out),
    .Q(reg_div_Q)
);

regfile_res regfile_res(
    .clk(clk),
    .rst(rst),
    .wr_addr(reg_res_wr_addr),
    .wr_en(reg_res_wr_en),
    .rd_en(reg_res_rd_en), 
    .D(sum_result),
    .Q(reg_res_Q)
);

addr_mux addr_mux(
    .addr1(theta_addr),
    .addr2(max_addr),
    .sel(ram_theta_addr_sel),
    .addr(RAM_THETA_A)
);

data_mux data_mux1(
    .data_mux_en(data_mux_en),
    .data1(RAM_THETA_Q), 
    .data2(reg_theta_Q),
    .data3(RAM_Q_Q),
    .data4(mult_result),
    .data5(reg_y_Q),
    .data6({1064'b0, RAM_R_Q}),
    .data_sel(vec1_data_sel),
    .data(vec1)
);

data_mux data_mux2(
    .data_mux_en(data_mux_en),
    .data1(reg_y_Q), 
    .data2(reg_theta_Q),
    .data3(scaler_vec),
    .data4(reg_res_Q),
    .data5(mult_result),
    .data6({1064'b0, RAM_INV_R_Q}),
    .data_sel(vec2_data_sel),
    .data(vec2)
);

VMU vmu(
    .clk(clk),
    .rst(rst),
    .vmu_en(vmu_en),
    .mode(vmu_mode),
    .result_sel(result_sel),
    .vec1(vec1),
    .vec2(vec2),
    .sum_result(sum_result),
    .mult_result(mult_result),
    .sub_result(sub_result)
);

MAX max(
    .clk(clk),
    .rst(rst),
    .max_en(max_en),
    .value(sum_result),
    .idx(vmu_idx),
    .max_addr(max_addr),
    .max_idx(max_idx)
);

CORDIC cordic(
    .clk(clk),
    .rst(rst),
    .cordic_en(cordic_en),
    .cordic_sel(cordic_sel),
    .cordic_result_sel(cordic_result_sel),
    .din(cordic_in),
    .dout(cordic_out)
);

BS_MULT  bs_mult(
    .clk(clk),
    .rst(rst),
    .bs_mult_en(bs_mult_en),
    .bs_clear_en(bs_clear_en),
    .din1(sum_result),
    .din2(ROM_Y_Q),
    .dout(RAM_S_D)
);

endmodule