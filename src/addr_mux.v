`include "../sim/define.vh"

module addr_mux (
    input [`RAM_THETA_ADDR_WIDTH-1:0] addr1,
    input [`RAM_THETA_ADDR_WIDTH-1:0] addr2,
    input sel,
    output [`RAM_THETA_ADDR_WIDTH-1:0] addr
);

assign addr = (sel) ? addr2 : addr1;
    
endmodule