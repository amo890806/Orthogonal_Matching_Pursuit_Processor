`include "../sim/define.vh"

`define IDLE 0
`define WRITE_REG_Y 1
`define WAIT_WRITE_REG_Y 2
`define CONTRIBUTE 3
`define WAIT_CONTRIBUTE 4
`define FIND_MAX 5
`define WRITE_THETA_TEMP 6
`define SUM_SQR_COL 7
`define SQRT 8
`define UPDATE_R_N_N 9
`define DIV 10
`define UPDATE_Q_N 11
`define READ_Q_COL 12
`define MULT_RES 13
`define WAIT_WRITE_REG_RES 14
`define UPDATE_RES 15
`define UPDATE_THETA 16
`define UPDATE_R_J_N 17
`define UPDATE_THETA_TEMP 18
`define BACK_SUBSTITUTION 19
`define WAIT_BACK_SUBSTITUTION 20
`define BS_MULT 21
`define WAIT_BS_MULT 22
`define WRITE_S 23
`define DONE 24

module controller (
    input clk,
    input rst,
    input start,
    output reg [`ROM_ADDR_WIDTH-1:0] ROM_Y_A,
    output reg ROM_Y_OE,
    output reg  [`RAM_Q_ADDR_WIDTH-1:0] RAM_Q_A,
    output reg  RAM_Q_OE,
    output reg  RAM_Q_WE,
    output reg [`RAM_R_ADDR_WIDTH-1:0] RAM_R_A,
    output reg RAM_R_OE,
    output reg RAM_R_WE,
    output reg [`RAM_THETA_ADDR_WIDTH-1:0] RAM_THETA_A,
    output reg RAM_THETA_OE,
    output reg [`RAM_THETA_DATA_WIDTH-1:0] RAM_THETA_D,
    output reg RAM_THETA_WE,
    output reg [`RAM_R_ADDR_WIDTH-1:0] RAM_INV_R_A,
    output reg RAM_INV_R_OE,
    output reg RAM_INV_R_WE,
    output reg RAM_INV_R_Q_SEL,
    output reg RAM_S_OE,
    output reg RAM_S_WE,
    output reg [`REG_ADDR_WIDTH-1:0] reg_wr_addr,
    output reg reg_wr_en,
    output reg reg_rd_en,
    output reg reg_load_en,
    output reg data_mux_en,
    output reg vmu_en,
    output reg load_theta_en,
    output reg rd_theta_en,
    output reg vmu_mode,
    output reg [`REG_IDX_DATA_WIDTH-1:0] vmu_idx,
    output reg max_en,
    output reg ram_theta_addr_sel,
    output reg [2:0] vec1_data_sel,
    output reg [2:0] vec2_data_sel,
    output reg result_sel,
    output reg [1:0] scaler_sel,
    output reg cordic_en,
    output reg cordic_sel,
    output reg cordic_result_sel,
    output reg bs_mult_en,
    output reg bs_clear_en,
    output reg [`REG_RES_ADDR_WIDTH-1:0] reg_res_wr_addr,
    output reg reg_res_wr_en,
    output reg reg_res_rd_en,
    output reg reg_idx_wr_en,
    output reg reg_idx_rd_en,
    output reg [`REG_IDX_ADDR_WIDTH-1:0] reg_idx_addr,
    output reg reg_div_wr_en,
    output reg reg_div_rd_en,
    output reg [`REG_DIV_ADDR_WIDTH-1:0] reg_div_addr,
    output reg ram_r_data_sel,
    output reg reg_theta_data_sel,
    output reg identity_flag,
    output reg done
);

integer i, j;

reg [4:0] state;
reg [1:0] vmu_idx_flag; 
reg [4:0] wait_cnt;
reg [5:0] iter_cnt;

always @(posedge clk or posedge rst) begin
    if(rst)begin
        state <= `IDLE;
    end
    else begin
        case (state)
            `IDLE: state <= (start) ? `WRITE_REG_Y : `IDLE;
            `WRITE_REG_Y: state <= (ROM_Y_A == 63) ? `WAIT_WRITE_REG_Y : `WRITE_REG_Y;
            `WAIT_WRITE_REG_Y: state <= `CONTRIBUTE;
            `CONTRIBUTE:  state <= (vmu_idx == 251)?`WAIT_CONTRIBUTE:`CONTRIBUTE;
            `WAIT_CONTRIBUTE: state <= (vmu_idx == 255) ? `FIND_MAX : `WAIT_CONTRIBUTE;
            `FIND_MAX: state <= `WRITE_THETA_TEMP;
            `WRITE_THETA_TEMP: state <= (iter_cnt == 0) ? `SUM_SQR_COL : `UPDATE_R_J_N;
            `SUM_SQR_COL: state <= (wait_cnt == 4) ? `SQRT : `SUM_SQR_COL;
            `SQRT: state <= (wait_cnt == 10) ? `UPDATE_R_N_N : `SQRT;
            `UPDATE_R_N_N: state <= `DIV;
            `DIV: state <= ((wait_cnt == 14))? `UPDATE_Q_N : `DIV;
            `UPDATE_Q_N: state <= (wait_cnt == 1) ? ((iter_cnt == `K-1)?`BACK_SUBSTITUTION:`READ_Q_COL) : `UPDATE_Q_N;
            `READ_Q_COL: state <= `MULT_RES;
            `MULT_RES: state <= ((wait_cnt == 2)) ? ((vmu_idx == 63)?`WAIT_WRITE_REG_RES:`READ_Q_COL) :`MULT_RES;
            `WAIT_WRITE_REG_RES: state <= (wait_cnt == 1)?`UPDATE_RES:`WAIT_WRITE_REG_RES;
            `UPDATE_RES: state <= (wait_cnt == 1) ? `UPDATE_THETA : `UPDATE_RES;
            `UPDATE_THETA: state <= `CONTRIBUTE;
            `UPDATE_R_J_N: state <= (wait_cnt == 4) ? `UPDATE_THETA_TEMP : `UPDATE_R_J_N;
            `UPDATE_THETA_TEMP: state <= (wait_cnt == 2) ? ((vmu_idx == iter_cnt-1)?`SUM_SQR_COL:`UPDATE_R_J_N) : `UPDATE_THETA_TEMP;
            `BACK_SUBSTITUTION: state <= (wait_cnt == 5 && iter_cnt == 0 && vmu_idx == 0) ? `WAIT_BACK_SUBSTITUTION :`BACK_SUBSTITUTION;
            `WAIT_BACK_SUBSTITUTION: state <= `BS_MULT; 
            `BS_MULT: state <= (vmu_idx == 63) ? `WAIT_BS_MULT : `BS_MULT;
            `WAIT_BS_MULT: state <= (wait_cnt == 3) ? ((iter_cnt == `K-1)?`WRITE_S:`BS_MULT) : `WAIT_BS_MULT;
            `WRITE_S: state <= (wait_cnt == 2) ? `DONE : `WRITE_S;
            `DONE: state <= `DONE;
        endcase
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        done <= 0;
    end
    else begin
        if(state == `DONE)begin
            done <= 1;
        end
    end
end

//COUNTER Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        iter_cnt <= 0;
    end
    else begin
        if(state == `UPDATE_Q_N)begin
            if(wait_cnt == 1)begin
                iter_cnt <= (iter_cnt == `K-1) ? iter_cnt : iter_cnt + 1;    
            end
        end
        else if(state == `BACK_SUBSTITUTION)begin
            if(vmu_idx == iter_cnt)begin
                iter_cnt <= (wait_cnt == 5) ? ((iter_cnt == 0)?0:iter_cnt-1) : iter_cnt;
            end
        end
        else if(state == `WAIT_BS_MULT)begin
            iter_cnt <= (wait_cnt == 3) ? ((iter_cnt == `K-1)?0:iter_cnt+1) : iter_cnt;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        wait_cnt <= 0;
    end
    else begin
        if(state == `CONTRIBUTE)begin
            wait_cnt <= (wait_cnt == 2) ? wait_cnt : wait_cnt+1;;
        end
        else if(state == `FIND_MAX)begin
            wait_cnt <= 0;
        end
        else if(state == `SUM_SQR_COL)begin
            wait_cnt <= (wait_cnt == 4) ? 0 : wait_cnt+1;
        end
        else if(state == `SQRT)begin
            wait_cnt <= (wait_cnt == 10) ? 0 : wait_cnt+1;
        end
        else if(state == `DIV)begin
            wait_cnt <= (wait_cnt == 14) ? 0 : wait_cnt+1;
        end
        else if(state == `UPDATE_Q_N)begin
            wait_cnt <= (wait_cnt == 1) ? 0 : wait_cnt+1;
        end
        else if(state == `MULT_RES)begin
            wait_cnt <= (wait_cnt == 2) ? 0 : wait_cnt+1;
        end
        else if(state == `WAIT_WRITE_REG_RES)begin
            wait_cnt <= (wait_cnt == 1) ? 0 : wait_cnt+1;
        end
        else if(state == `UPDATE_RES)begin
            wait_cnt <= (wait_cnt == 1) ? 0 : wait_cnt+1;
        end
        else if(state == `UPDATE_R_J_N)begin
            wait_cnt <= (wait_cnt == 4) ? 0 : wait_cnt+1;
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            wait_cnt <= (wait_cnt == 2) ? 0 : wait_cnt+1;
        end
        else if(state == `BACK_SUBSTITUTION)begin
            wait_cnt <= (wait_cnt == 5) ? 0 : wait_cnt+1;
        end
        else if(state == `WAIT_BS_MULT)begin
            wait_cnt <= (wait_cnt == 3) ? 0 : wait_cnt+1; 
        end
        else if(state == `WRITE_S)begin
            wait_cnt <= (wait_cnt == 2) ? 0 : wait_cnt+1; 
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        identity_flag <= 0;
    end
    else begin
        if(state == `BACK_SUBSTITUTION)begin
            identity_flag <= (iter_cnt == vmu_idx) ? 1 : 0;
        end
        else if(state == `WAIT_BACK_SUBSTITUTION)begin
            identity_flag <= 0;
        end
    end
end

//VMU Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        vmu_idx_flag <= 0;
    end
    else begin
        if(state == `CONTRIBUTE)begin
            vmu_idx_flag[0] <= (wait_cnt == 2) ? 1 : 0;
        end
        else if(state == `WAIT_CONTRIBUTE)begin
            if(vmu_idx == 254)begin
                vmu_idx_flag[0] <= 0;
            end
        end
        else if(state == `WRITE_THETA_TEMP)begin
            vmu_idx_flag[0] <= (iter_cnt > 0) ? 1 : 0;
        end
        else if(state == `DIV)begin
            vmu_idx_flag[0] <= (wait_cnt == 14)?1:0;
        end
        else if(state == `MULT_RES)begin
            if(vmu_idx == 63 && wait_cnt == 1)begin
                vmu_idx_flag[0] <= 0;
            end
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            if(wait_cnt == 1 && vmu_idx == iter_cnt-1)begin
                vmu_idx_flag[0] <= 0;
            end
        end
        else if(state == `BACK_SUBSTITUTION)begin
            if(iter_cnt == 0 && vmu_idx == 0)begin
                vmu_idx_flag[0] <= (wait_cnt == 3) ? 0 : 1;
            end
        end
        else if(state == `WAIT_BS_MULT)begin
            if(iter_cnt == `K-1)begin
                vmu_idx_flag[0] <= 0;
            end
        end
        vmu_idx_flag[1] <= vmu_idx_flag[0];
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        vmu_idx <= 0;
    end
    else begin
        if(vmu_idx_flag[1])begin
            if(state == `CONTRIBUTE || state == `WAIT_CONTRIBUTE)begin
                vmu_idx <= (vmu_idx == 255) ? 0 : vmu_idx+1;    
            end
            else if(state == `UPDATE_Q_N)begin
                vmu_idx <= (wait_cnt == 1 && iter_cnt == `K-1) ? iter_cnt : 0;
            end
            else if(state == `MULT_RES)begin
                if(wait_cnt == 2)begin
                    vmu_idx <= (vmu_idx == 63) ? 0 : vmu_idx+1;     
                end
            end
            else if(state == `UPDATE_THETA_TEMP)begin
                if(wait_cnt == 2)begin
                    vmu_idx <= (vmu_idx == iter_cnt-1) ? 0 : vmu_idx+1;
                end
            end
            else if(state == `BACK_SUBSTITUTION)begin
                if(wait_cnt == 5)begin
                    vmu_idx <= (vmu_idx == iter_cnt) ? ((iter_cnt == 0)?0:`K-1) : vmu_idx-1;
                end
            end
            else if(state == `BS_MULT)begin
                vmu_idx <= (vmu_idx == 63) ? 0 : vmu_idx+1;
            end
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        vmu_mode <= 0;
    end
    else begin
        if(state == `WAIT_WRITE_REG_RES)begin
            vmu_mode <= 1;
        end
        else if(state == `UPDATE_THETA)begin
            vmu_mode <= 0;
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            vmu_mode <= (wait_cnt == 2) ? 0 : 1;
        end
    end
end

//CORDIC Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        cordic_en <= 0;
        cordic_sel <= 0;
        cordic_result_sel <= 0;
    end
    else begin
        if(state == `SUM_SQR_COL)begin
            cordic_en <= (wait_cnt == 3) ? 1 : 0;
        end
        else if(state == `SQRT)begin
            cordic_en <= (wait_cnt == 10) ? 1 : 0;
            cordic_sel <= (wait_cnt == 10) ? 1 : 0;
        end
        else if(state == `UPDATE_R_N_N)begin
            cordic_en <= 0;
            cordic_result_sel <= 1;
        end
        else if(state == `UPDATE_Q_N)begin
            cordic_sel <= 0;
            cordic_result_sel <= 0;
        end
    end
end

//ENABLE Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        data_mux_en <= 0;
    end
    else begin
        if(state == `CONTRIBUTE)begin
            data_mux_en <= 1;
        end
        else if(state == `WAIT_CONTRIBUTE)begin
            data_mux_en <= 0;
        end
        else if(state == `SUM_SQR_COL)begin
            data_mux_en <= (wait_cnt == 0) ? 1 : 0;
        end
        else if(state == `DIV)begin
            data_mux_en <= (wait_cnt == 14) ? 1 : 0;
        end
        else if(state == `UPDATE_Q_N)begin
            data_mux_en <= (wait_cnt == 1) ? ((iter_cnt == `K-1)?0:1) : 0;
        end
        else if(state == `MULT_RES)begin
            data_mux_en <= (wait_cnt == 2) ? ((vmu_idx == 63)?0:1) : 0;
        end
        else if(state == `WAIT_WRITE_REG_RES)begin
            data_mux_en <= (wait_cnt == 1)?1:0; 
        end
        else if(state == `UPDATE_RES)begin
            data_mux_en <= 0; 
        end
        else if(state == `UPDATE_R_J_N)begin
            data_mux_en <= (wait_cnt == 1 || wait_cnt == 4) ? 1 : 0;
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            data_mux_en <= (wait_cnt == 0) ? 1 : 0;
        end
        else if(state == `BACK_SUBSTITUTION)begin
            data_mux_en <= (wait_cnt == 1) ? 1 : 0;
        end
        else if(state == `BS_MULT)begin
            if(vmu_idx == 1)begin
                data_mux_en <= 1;
            end
        end
        else if(state == `WAIT_BS_MULT)begin
            if(wait_cnt == 1)begin
                data_mux_en <= 0;
            end
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        vmu_en <= 0;
    end
    else begin
        if(state == `CONTRIBUTE)begin
            vmu_en <= 1;
        end
        else if(state == `WAIT_CONTRIBUTE)begin
            vmu_en <= 0;
        end
        else if(state == `SUM_SQR_COL)begin
            vmu_en <= (wait_cnt == 0) ? 1 : 0;
        end
        else if(state == `DIV)begin
            vmu_en <= (wait_cnt == 14) ? 1 : 0;
        end
        else if(state == `UPDATE_Q_N)begin
            vmu_en <= (wait_cnt == 1) ? ((iter_cnt == `K-1)?0:1) : 0;
        end
        else if(state == `MULT_RES)begin
            vmu_en <= (wait_cnt == 2) ? ((vmu_idx == 63)?0:1) : 0;
        end
        else if(state == `WAIT_WRITE_REG_RES)begin
            vmu_en <= (wait_cnt == 1)?1:0; 
        end
        else if(state == `UPDATE_RES)begin
            vmu_en <= 0; 
        end
        else if(state == `UPDATE_R_J_N)begin
            vmu_en <= (wait_cnt == 1 || wait_cnt == 4) ? 1 : 0;
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            vmu_en <= (wait_cnt == 0) ? 1 : 0;
        end
        else if(state == `BACK_SUBSTITUTION)begin
            vmu_en <= (wait_cnt == 1) ? 1 : 0;
        end
        else if(state == `BS_MULT)begin
            if(vmu_idx == 1)begin
                vmu_en <= 1;
            end
        end
        else if(state == `WAIT_BS_MULT)begin
            if(wait_cnt == 1)begin
                vmu_en <= 0;
            end
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        max_en <= 0;
    end
    else begin
        if(state == `CONTRIBUTE || state == `WAIT_CONTRIBUTE)begin
            max_en <= vmu_idx_flag[0];
        end
    end
end


//SELECT Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        ram_theta_addr_sel <= 0;
    end
    else begin
        if(state == `WAIT_CONTRIBUTE)begin
            ram_theta_addr_sel <= (vmu_idx == 255) ? 1 : 0;
        end
        else if(state == `FIND_MAX)begin
            ram_theta_addr_sel <= 0;
        end
        else if(state == `UPDATE_RES)begin
            ram_theta_addr_sel <= (wait_cnt == 1) ? 1 : 0;
        end
        else if(state == `UPDATE_THETA)begin
            ram_theta_addr_sel <= 0;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        vec1_data_sel <= 0;
        vec2_data_sel <= 0;
    end
    else begin
        if(state == `SUM_SQR_COL)begin
            vec1_data_sel <= 1;
            vec2_data_sel <= 1;
        end
        else if(state == `DIV)begin
            vec2_data_sel <=  (wait_cnt == 14) ? 2 : 1;
        end
        else if(state == `UPDATE_Q_N)begin
            vec1_data_sel <= (wait_cnt == 1) ? 2 : 1;
        end
        else if(state == `READ_Q_COL)begin
            vec1_data_sel <= 3;
            vec2_data_sel <= 0;
        end
        else if(state == `MULT_RES)begin
            vec1_data_sel <= (wait_cnt == 2)?2:3;
            vec2_data_sel <= (wait_cnt == 2)?2:0;
        end
        else if(state == `WAIT_WRITE_REG_RES)begin
            vec1_data_sel <= 4;
            vec2_data_sel <= 3;
        end
        else if(state == `UPDATE_THETA)begin
            vec1_data_sel <= 0;
            vec2_data_sel <= 0;
        end
        else if(state == `UPDATE_R_J_N)begin
            vec2_data_sel <= (wait_cnt == 4) ? 2 : 1;
            vec1_data_sel <= 2;
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            vec1_data_sel <= 1;
            vec2_data_sel <= 4;
        end
        else if(state == `BACK_SUBSTITUTION)begin
            vec1_data_sel <= 5;
            vec2_data_sel <= 5;
        end
        else if(state == `BS_MULT)begin
            vec1_data_sel <= 2;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        result_sel <= 0;
    end
    else begin
        if(state == `WRITE_THETA_TEMP)begin
            result_sel <= 0;
        end
        else if(state == `UPDATE_Q_N)begin
            result_sel <= 1;
        end
        else if(state == `READ_Q_COL)begin
            result_sel <= 1;
        end
        else if(state == `MULT_RES)begin
            result_sel <= 0;
        end
        else if(state == `UPDATE_THETA)begin
            result_sel <= 0;
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            result_sel <= (wait_cnt == 2)?0:1;
        end
        else if(state == `BACK_SUBSTITUTION)begin
            result_sel <= 0;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        reg_theta_data_sel <= 0;
    end
    else begin
        if(state == `UPDATE_THETA_TEMP)begin
            reg_theta_data_sel <= (wait_cnt == 1) ? 1 : 0;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        scaler_sel <= 0;
    end
    else begin
        if(state == `UPDATE_Q_N)begin
            if(wait_cnt == 1)begin
                scaler_sel <= 1;
            end
        end
        else if(state == `UPDATE_THETA)begin
            scaler_sel <= 0;
        end
        else if(state == `UPDATE_R_J_N)begin
            scaler_sel <= 2;
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            scaler_sel <= (wait_cnt == 2) ? 0 : 2;
        end
    end
end

always @(posedge clk or posedge rst) begin
    if(rst)begin
        ram_r_data_sel <= 0;
    end
    else begin
        if(state == `UPDATE_R_J_N)begin
            ram_r_data_sel <= 1;
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            ram_r_data_sel <= (wait_cnt == 2) ? 0 : 1;
        end
    end
end

//RegFile_Y Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        reg_wr_addr <= 0;
        reg_wr_en <= 0;
        reg_rd_en <= 0;
        reg_load_en <= 0;
    end
    else begin
        if(state == `WRITE_REG_Y)begin
            reg_wr_addr <= ROM_Y_A;
            reg_wr_en <= 1;
        end
        else if(state == `WAIT_WRITE_REG_Y)begin
            reg_wr_en <= 0;
        end
        else if(state == `CONTRIBUTE)begin
            reg_rd_en <= 1;
        end
        else if(state == `WAIT_CONTRIBUTE)begin
            reg_rd_en <= 0;
        end
        else if(state == `READ_Q_COL)begin
            reg_rd_en <= 1;
        end
        else if(state == `MULT_RES)begin
            reg_rd_en <= 0;
        end
        else if(state == `WAIT_WRITE_REG_RES)begin
            reg_rd_en <= (wait_cnt == 1)?1:0;
        end
        else if(state == `UPDATE_RES)begin
            reg_rd_en <= 0;
            reg_load_en <= (wait_cnt == 0) ? 1 : 0;
        end
        else if(state == `UPDATE_THETA)begin
            reg_rd_en <= 1;
        end
    end
end

//RegFile Theta Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        load_theta_en <= 0;
        rd_theta_en <= 0;
    end
    else begin
        if(state == `FIND_MAX)begin
            load_theta_en <= 1;
        end
        else if(state == `WRITE_THETA_TEMP)begin
            load_theta_en <= 0;
        end
        else if(state == `SUM_SQR_COL)begin
            rd_theta_en <= (wait_cnt == 0)?1:0;
        end
        else if(state == `DIV)begin
            rd_theta_en <= (wait_cnt == 14)?1:0;
        end
        else if(state == `UPDATE_Q_N)begin
            rd_theta_en <= 0;
        end
        else if(state == `UPDATE_R_J_N)begin
            rd_theta_en <= (wait_cnt == 1)?1:0;
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            load_theta_en <= (wait_cnt == 1) ? 1 : 0;
            rd_theta_en <= (wait_cnt == 0)?1:0;
        end
        
    end
end

//BS_MULT Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        bs_mult_en <= 0;
        bs_clear_en <= 0;
    end
    else begin
        if(state == `BS_MULT)begin
            if(vmu_idx == 4)begin
                bs_mult_en <= 1;
            end
            else if(vmu_idx == 0)begin
                bs_mult_en <= 0;
            end

            bs_clear_en <= (vmu_idx == 1)?1:0;
        end
        else if(state == `WRITE_S)begin
            bs_mult_en <= 0;
            bs_clear_en <= (wait_cnt == 1) ? 1 : 0;
        end
    end
end

//RegFile IDX Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        reg_idx_rd_en <= 0;
        reg_idx_wr_en <= 0;
        reg_idx_addr <= 0;
    end
    else begin
        if(state == `WAIT_CONTRIBUTE)begin
            reg_idx_wr_en <= (vmu_idx == 255) ? 1 : 0;
            reg_idx_addr <= (vmu_idx == 255) ? iter_cnt  : reg_idx_addr;
        end
        else if(state == `FIND_MAX)begin
            reg_idx_wr_en <= 0;
        end
        else if(state == `BS_MULT)begin
            reg_idx_rd_en <= (vmu_idx == 2) ? 1 : 0;
            reg_idx_addr <= (vmu_idx == 2) ? iter_cnt : reg_idx_addr;
        end
    end 
end

//RegFile Div Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        reg_div_addr <= 0;
        reg_div_wr_en <= 0;
        reg_div_rd_en <= 0;
    end
    else begin
        if(state == `DIV)begin
            reg_div_wr_en <= (wait_cnt == 14) ? 1 : 0;
            reg_div_addr <= (wait_cnt == 14) ? iter_cnt : reg_div_addr;
        end
        else if(state == `UPDATE_Q_N)begin
            reg_div_wr_en <= 0;
        end
        else if(state == `BACK_SUBSTITUTION)begin
            reg_div_rd_en <= (wait_cnt == 2) ? 1 : 0;
            reg_div_addr <= iter_cnt;
        end
    end
end

//RegFile Residual Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        reg_res_wr_addr <= 0;
        reg_res_wr_en <= 0;
        reg_res_rd_en <= 0;
    end
    else begin
        if(state == `READ_Q_COL)begin
            reg_res_wr_en <= 0;
        end
        else if(state == `MULT_RES)begin
            reg_res_wr_addr <= vmu_idx; 
            reg_res_wr_en <= (wait_cnt == 2)?1:0;
        end
        else if(state == `WAIT_WRITE_REG_RES)begin
            reg_res_wr_en <= 0;
            reg_res_rd_en <= (wait_cnt == 0) ? 1 : 0;
        end
    end
end

//ROM_Y Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        ROM_Y_A <= 0;
        ROM_Y_OE <= 0;
    end
    else begin
        if(state == `WRITE_REG_Y)begin
            ROM_Y_OE <= 1;
            ROM_Y_A <= ROM_Y_A + 1;
        end
        else if(state == `WAIT_WRITE_REG_Y)begin
            ROM_Y_OE <= 0;
        end
        else if(state == `BS_MULT)begin
            if(vmu_idx == 4)begin
                ROM_Y_OE <= 1;
            end
            else if(vmu_idx == 0)begin
                ROM_Y_OE <= 0;
            end

            ROM_Y_A <= (vmu_idx > 3) ? ROM_Y_A+1 : 0;
        end
        else if(state == `WAIT_BS_MULT)begin
            ROM_Y_A <= ROM_Y_A + 1;
        end
        else if(state == `WRITE_S)begin
            ROM_Y_OE <= 0;
        end
    end
end

//RAM_THETA Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        RAM_THETA_A <= 0;
        RAM_THETA_OE <= 0;
        RAM_THETA_WE <= 0;
        RAM_THETA_D <= 0;
    end
    else begin
	    RAM_THETA_D <= 0;
        if(state == `WAIT_WRITE_REG_Y)begin
            for(i=0; i<64; i=i+1)begin
                RAM_THETA_A[14*(i+1)-1 -: 14] <= (i << 8);
            end
        end
        else if(state == `CONTRIBUTE)begin
            RAM_THETA_OE <= 1;
            for(i=0; i<64; i=i+1)begin
                RAM_THETA_A[14*(i+1)-1 -: 14] <= RAM_THETA_A[14*(i+1)-1 -: 14] + 1;
            end
        end
        else if(state == `WAIT_CONTRIBUTE)begin
            RAM_THETA_OE <= 0;
        end
        else if(state == `FIND_MAX)begin
            RAM_THETA_OE <= 1;
        end
        else if(state == `WRITE_THETA_TEMP)begin
            RAM_THETA_OE <= 0;
        end
        else if(state == `UPDATE_RES)begin
            RAM_THETA_WE <= (wait_cnt == 1) ? 1 : 0;
        end
        else if(state == `UPDATE_THETA)begin
            RAM_THETA_WE <= 0;
            for(i=0; i<64; i=i+1)begin
                RAM_THETA_A[14*(i+1)-1 -: 14] <= (i << 8);
            end
        end
    end
end

//RAM_Q Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        RAM_Q_A <= 0;
        RAM_Q_OE <= 0;
        RAM_Q_WE <= 0;
    end
    else begin
        if(state == `UPDATE_Q_N)begin
            if(wait_cnt == 0)begin
                RAM_Q_WE <= 1;
                for(j=0; j<`ROM_MEM_SIZE; j=j+1)begin
                    RAM_Q_A[9*(j+1)-1 -: 9] <= 8*j + iter_cnt;
                end
            end
            else if(wait_cnt == 1)begin
                RAM_Q_WE <= 0;
                RAM_Q_OE <= (iter_cnt == `K-1)?0:1;
            end
        end
        else if(state == `READ_Q_COL)begin
            RAM_Q_OE <= 0;
        end
        else if(state == `MULT_RES)begin
            RAM_Q_OE <= (wait_cnt == 2) ? ((vmu_idx == 63)?0:1) : 0;
        end
        else if(state == `UPDATE_R_J_N)begin
            if(wait_cnt == 0)begin
                for(j=0; j<`ROM_MEM_SIZE; j=j+1)begin
                    RAM_Q_A[9*(j+1)-1 -: 9] <= 8*j + vmu_idx;
                end
            end
            else if(wait_cnt == 1 || wait_cnt == 4)begin
                RAM_Q_OE <= 1;
            end
            else begin
                RAM_Q_OE <= 0;
            end
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            RAM_Q_OE <= 0;
            if(wait_cnt == 2)begin
                for(j=0; j<`ROM_MEM_SIZE; j=j+1)begin
                    RAM_Q_A[9*(j+1)-1 -: 9] <= 8*j + vmu_idx;
                end
            end
        end
        else if(state == `BS_MULT)begin
            if(vmu_idx == 1)begin
                RAM_Q_OE <= 1;
            end

            for(j=0; j<8; j=j+1)begin
                RAM_Q_A[9*(j+1)-1 -: 9] <= vmu_idx*8+j;
            end
        end
        else if(state == `WAIT_BS_MULT)begin
            if(wait_cnt == 1)begin
                RAM_Q_OE <= 0;
            end
        end
    end
end

//RAM_R Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        RAM_R_A <= 0;
        RAM_R_WE <= 0;
        RAM_R_OE <= 0;
    end
    else begin
        if(state == `SQRT)begin
            RAM_R_WE <= (wait_cnt == 10) ? 1 : 0;
            RAM_R_A <= 8*iter_cnt + iter_cnt;
        end
        else if(state == `UPDATE_R_N_N)begin
            RAM_R_WE <= 0;
        end
        else if(state == `UPDATE_R_J_N)begin
            if(wait_cnt == 4)begin
                RAM_R_WE <= 1;
                RAM_R_A <= 8*vmu_idx + iter_cnt;
            end
            else begin
                RAM_R_WE <= 0;
            end
        end
        else if(state == `UPDATE_THETA_TEMP)begin
            RAM_R_WE <= 0;
        end
        else if(state == `BACK_SUBSTITUTION)begin
            RAM_R_A <= iter_cnt;
            RAM_R_OE <= (wait_cnt == 1) ? 1 : 0;
        end
    end
end

//RAM_INV_R Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        RAM_INV_R_A <= 0;
        RAM_INV_R_OE <= 0;
        RAM_INV_R_WE <= 0;
        RAM_INV_R_Q_SEL <= 0;
    end
    else begin
        if(state == `BACK_SUBSTITUTION)begin
            RAM_INV_R_A <= (wait_cnt == 5) ? 8*iter_cnt+vmu_idx : vmu_idx;
            RAM_INV_R_OE <= (wait_cnt == 1) ? 1 : 0;
            RAM_INV_R_WE <= (wait_cnt == 5) ? 1 : 0;
        end
        else if(state == `WAIT_BACK_SUBSTITUTION)begin
            RAM_INV_R_WE <= 0;
            RAM_INV_R_Q_SEL <= 1;
        end
        else if(state == `BS_MULT)begin
            RAM_INV_R_A <= iter_cnt;
            if(vmu_idx == 1)begin
                RAM_INV_R_OE <= 1;
            end
        end
        else if(state == `WAIT_BS_MULT)begin
            if(wait_cnt == 1)begin
                RAM_INV_R_OE <= 0;
            end
        end
    end
end

//RAM_S Control
always @(posedge clk or posedge rst) begin
    if(rst)begin
        RAM_S_OE <= 0;
        RAM_S_WE <= 0;
    end
    else begin
	    RAM_S_OE <= 0;
        if(state == `BS_MULT)begin
            RAM_S_WE <= (vmu_idx == 1)?1:0;
        end
        else if(state == `WRITE_S)begin
            RAM_S_WE <= (wait_cnt == 1)?1:0;
        end
    end
end

endmodule