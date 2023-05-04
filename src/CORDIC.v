`include "../sim/define.vh"

module CORDIC (
    input clk,
    input rst,
    input cordic_en,
    input cordic_sel,
    input cordic_result_sel,
    input signed [`CORDIC_DATA_WIDTH-1:0] din,
    output [`CORDIC_DATA_WIDTH-1:0] dout
);

parameter fixed_one = 16384;     // 1*2^14
parameter fixed_four = 65536;     // 4*2^14
parameter K = 9892; // 0.60374807*2^14

integer i;

reg signed [`CORDIC_DATA_WIDTH-1:0] x_pre;
reg signed [`CORDIC_DATA_WIDTH-1:0] y_pre;
reg signed [`CORDIC_DATA_WIDTH-1:0] x [0:`CORDIC_STAGE_NUM];
reg signed [`CORDIC_DATA_WIDTH-1:0] y [0:`CORDIC_STAGE_NUM];
reg signed [`CORDIC_DATA_WIDTH-1:0] z_div [0:`CORDIC_STAGE_NUM];
reg signed [`CORDIC_DATA_WIDTH-1:0] one [0:`CORDIC_STAGE_NUM];
reg signed [`CORDIC_DATA_WIDTH-1:0] x_shift [0:`CORDIC_STAGE_NUM-1];
reg signed [`CORDIC_DATA_WIDTH-1:0] y_shift [0:`CORDIC_STAGE_NUM-1];
reg signed [`CORDIC_DATA_WIDTH-1:0] z_shift [0:`CORDIC_STAGE_NUM-1];

reg signed [`CORDIC_STAGE_NUM-1:0] sign;
reg signed [2*`CORDIC_DATA_WIDTH-1:0] z_sqrt;

wire signed [`CORDIC_DATA_WIDTH-1:0] din_scale_four;
wire signed [2*`CORDIC_DATA_WIDTH-1:0] din_scale_four_temp;
assign din_scale_four_temp = din << 16;
assign din_scale_four = {din_scale_four_temp[2*`CORDIC_DATA_WIDTH-1], din_scale_four_temp[31:14]};

wire signed [`CORDIC_DATA_WIDTH-1:0] z_div_scale_four;
wire signed [2*`CORDIC_DATA_WIDTH-1:0] z_div_scale_four_temp;
assign z_div_scale_four_temp = z_div[`DIV_STAGE_NUM] << 16;
assign z_div_scale_four = {z_div_scale_four_temp[2*`CORDIC_DATA_WIDTH-1], z_div_scale_four_temp[31:14]};

always @(*) begin
    for(i=0; i<`CORDIC_STAGE_NUM; i=i+1)begin
        x_shift[i] = x[i] >>> i+1;
        y_shift[i] = y[i] >>> i+1;
        z_shift[i] = one[i] >>> i+1;
        sign[i] = (cordic_sel) ? !y[i][`CORDIC_DATA_WIDTH-1] : y[i][`CORDIC_DATA_WIDTH-1];
    end
end

//Pre x, y
always @(posedge clk or posedge rst) begin
    if(rst)begin
        x_pre <= 0;
        y_pre <= 0;
    end
    else begin
        if(cordic_sel)begin
            x_pre <= 0;
            y_pre <= 0;
        end
        else begin
            if(cordic_en)begin
                x_pre <= din + fixed_one;
                y_pre <= din - fixed_one;
            end
            else begin
                x_pre <= 0;
                y_pre <= 0;
            end
        end
    end
end


//Iteration
always @(posedge clk or posedge rst) begin
    if(rst)begin
        for(i=0; i<`CORDIC_STAGE_NUM+1; i=i+1)begin
            x[i] <= 0;
            y[i] <= 0;
            z_div[i] <= 0;
            one[i] <= 0;
        end
    end
    else begin
        if(cordic_sel)begin
            if(cordic_en)begin
                x[0] <= din_scale_four;
                y[0] <= fixed_one;
                z_div[0] <= 0;
                one[0] <= fixed_one;
            end
            else begin
                x[0] <= 0;
                y[0] <= 0;
                z_div[0] <= 0;
                one[0] <= 0;
            end
            for(i=0; i<`CORDIC_STAGE_NUM; i=i+1)begin
                x[i+1] <= x[i];
                y[i+1] <= sign[i] ? y[i]-x_shift[i] : y[i]+x_shift[i];
                z_div[i+1] <= sign[i] ? z_div[i]+z_shift[i] : z_div[i]-z_shift[i];
                one[i+1] <= one[i];
            end
        end
        else begin
            x[0] <= x_pre;
            y[0] <= y_pre;
            for(i=0; i<`SQRT_STAGE_NUM; i=i+1)begin
                x[i+1] <= sign[i] ? x[i]+y_shift[i] : x[i]-y_shift[i];
                y[i+1] <= sign[i] ? y[i]+x_shift[i] : y[i]-x_shift[i];
            end
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        z_sqrt <= 0;
    end
    else begin
        z_sqrt <= (cordic_result_sel)?0:x[`SQRT_STAGE_NUM]*K;
    end
end

assign dout = (cordic_result_sel) ? z_div_scale_four : {z_sqrt[2*`CORDIC_DATA_WIDTH-1], z_sqrt[31:14]};

    
endmodule