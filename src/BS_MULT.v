`include "../sim/define.vh"

module BS_MULT (
    input clk,
    input rst,
    input bs_mult_en,
    input bs_clear_en,
    input [`BS_MULT_DATA_WIDTH-1:0] din1,
    input [`BS_MULT_DATA_WIDTH-1:0] din2,
    output reg signed [`BS_MULT_DATA_WIDTH-1:0] dout
);

wire [`BS_MULT_DATA_WIDTH-1:0] din1_r;
wire [`BS_MULT_DATA_WIDTH-1:0] din2_r;
wire signed [`BS_MULT_DATA_WIDTH-1:0] temp;
assign din1_r = (bs_mult_en) ? din1 : 0;
assign din2_r = (bs_mult_en) ? din2 : 0;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        dout <= 0;
    end
    else begin
        if(bs_clear_en)begin
            dout <= 0;
        end
        else begin
            dout <= dout + temp;
        end
    end
end

multiplier m1(.clk(clk), .rst(rst), .din1(din1_r), .din2(din2_r), .dout(temp));


    
endmodule