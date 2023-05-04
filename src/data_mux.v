`include "../sim/define.vh"

module data_mux (
    input data_mux_en,
    input [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] data1, 
    input [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] data2,
    input [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] data3,
    input [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] data4,
    input [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] data5,
    input [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] data6,
    input [2:0] data_sel,
    output reg [`VMU_DATA_WIDTH*`VMU_OP_NUM-1:0] data
);

always @(*) begin
    if(data_mux_en)begin
        case (data_sel)
            0: data = data1; 
            1: data = data2;
            2: data = data3;
            3: data = data4; 
            4: data = data5; 
            5: data = data6; 
            default: data = 0;
        endcase
    end
    else begin
        data = 0;
    end
end
    
endmodule