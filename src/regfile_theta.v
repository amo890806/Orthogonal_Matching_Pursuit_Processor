`include "../sim/define.vh"

module regfile_theta (
    input clk,
    input rst,
    input load_en,
    input rd_en,
    input [`RAM_THETA_DATA_WIDTH-1:0] din,
    output reg [`RAM_THETA_DATA_WIDTH-1:0] dout
);

reg [`RAM_THETA_DATA_WIDTH-1:0] theta_temp;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        theta_temp <= 0;
    end
    else begin
        if(load_en)begin
            theta_temp <= din;
        end
    end
end

always @(*) begin
    if(rd_en)begin
        dout = theta_temp;
    end
    else begin
        dout = `RAM_THETA_DATA_WIDTH'hz;
    end
end
    
endmodule