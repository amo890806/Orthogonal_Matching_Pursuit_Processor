`include "../sim/define.vh"

module adder (
    input clk,
    input rst,
    input mode,
    input signed [`VMU_DATA_WIDTH-1:0] din1,
    input signed [`VMU_DATA_WIDTH-1:0] din2,
    input signed [`VMU_DATA_WIDTH-1:0] din3,
    input signed [`VMU_DATA_WIDTH-1:0] din4,
    input signed [`VMU_DATA_WIDTH-1:0] din5,
    input signed [`VMU_DATA_WIDTH-1:0] din6,
    input signed [`VMU_DATA_WIDTH-1:0] din7,
    input signed [`VMU_DATA_WIDTH-1:0] din8,
    output [`VMU_DATA_WIDTH-1:0] dout,
    output reg [4*`VMU_DATA_WIDTH-1:0] dout_vec
);



wire signed [`VMU_DATA_WIDTH-1:0] add11, add12, add21, add22, add31, add32, add41, add42;
assign add11 = (mode == 1) ? (din1 == 0)?0:~din1+1 : din1;
assign add12 = din2;
assign add21 = (mode == 1) ? (din3 == 0)?0:~din3+1 : din3;
assign add22 = din4;
assign add31 = (mode == 1) ? (din5 == 0)?0:~din5+1 : din5;
assign add32 = din6;
assign add41 = (mode == 1) ? (din7 == 0)?0:~din7+1 : din7;
assign add42 = din8;

wire signed [`VMU_DATA_WIDTH-1:0] temp1, temp2, temp3, temp4;
assign temp1 = add11 + add12;
assign temp2 = add21 + add22;
assign temp3 = add31 + add32;
assign temp4 = add41 + add42;

assign dout = (mode == 1) ? 0 : temp1 + temp2 + temp3 + temp4;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        dout_vec <= 0;
    end
    else begin
        dout_vec <= (mode == 1) ? {temp4, temp3, temp2, temp1} : 0;
    end
end
    
endmodule