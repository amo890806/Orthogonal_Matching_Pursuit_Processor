`timescale 1ns/10ps
`define CYCLE 6.0
`define COMPRESSED  "../sim/fixed_lena_compressed_bcs_hex.txt"
`define THETA  "../sim/fixed_theta_bcs_hex.txt"

`include "../sim/define.vh"
`include "../sim/RAM_Q.v"
`include "../sim/RAM_R.v"
`include "../sim/RAM_THETA.v"
`include "../sim/ROM_Y.v"
`include "../sim/RAM_INV_R.v"
`include "../sim/RAM_S.v"

module OMP_syn_tb;

reg [`ROM_DATA_WIDTH-1:0] y_data [0:`COL_NUM*`ROM_MEM_SIZE-1];
reg [`RAM_THETA_DATA_WIDTH-1:0] theta_data [0:`RAM_THETA_MEM_SIZE-1];

/********************* ROM & RAM *********************/

wire [`ROM_DATA_WIDTH-1:0] ROM_Y_Q;
wire [`ROM_ADDR_WIDTH-1:0] ROM_Y_A;
wire ROM_Y_OE;

wire [`RAM_Q_DATA_WIDTH-1:0] RAM_Q_Q;
wire [`RAM_Q_ADDR_WIDTH-1:0] RAM_Q_A;
wire RAM_Q_OE;
wire [`RAM_Q_DATA_WIDTH-1:0] RAM_Q_D;
wire RAM_Q_WE;

wire [36*`RAM_R_DATA_WIDTH-1:0] RAM_R_Q;
wire [`RAM_R_ADDR_WIDTH-1:0] RAM_R_A;
wire RAM_R_OE;
wire [`RAM_R_DATA_WIDTH-1:0] RAM_R_D;
wire RAM_R_WE;

wire [`RAM_THETA_DATA_WIDTH-1:0] RAM_THETA_Q;
wire [`RAM_THETA_ADDR_WIDTH-1:0] RAM_THETA_A;
wire RAM_THETA_OE;
wire [`RAM_THETA_DATA_WIDTH-1:0] RAM_THETA_D;
wire RAM_THETA_WE;

wire [36*`RAM_R_DATA_WIDTH-1:0] RAM_INV_R_Q;
wire [`RAM_R_ADDR_WIDTH-1:0] RAM_INV_R_A;
wire RAM_INV_R_OE;
wire [`RAM_R_DATA_WIDTH-1:0] RAM_INV_R_D;
wire RAM_INV_R_WE;
wire RAM_INV_R_Q_SEL;

wire [`RAM_S_DATA_WIDTH-1:0] RAM_S_Q;
wire [`RAM_S_ADDR_WIDTH-1:0] RAM_S_A;
wire RAM_S_OE;
wire [`RAM_S_DATA_WIDTH-1:0] RAM_S_D;
wire RAM_S_WE;

/********************* TOP *********************/

integer a, b, c, d, e, f, g, h, l;
integer i, j, k, x, y;
integer col_num;

reg clk;
reg rst;
reg start;
wire done;


ROM_Y rom_y(
    .CK(clk),
    .A(ROM_Y_A),
    .OE(ROM_Y_OE),
    .Q(ROM_Y_Q)
);

RAM_Q ram_q(
    .CK(clk),
    .A(RAM_Q_A),
    .WE(RAM_Q_WE),
    .OE(RAM_Q_OE),
    .D(RAM_Q_D),
    .Q(RAM_Q_Q)
);

RAM_THETA ram_theta(
    .CK(clk),
    .A(RAM_THETA_A),
    .WE(RAM_THETA_WE),
    .OE(RAM_THETA_OE),
    .D(RAM_THETA_D),
    .Q(RAM_THETA_Q)
);

RAM_R ram_r(
    .CK(clk),
    .A(RAM_R_A),
    .WE(RAM_R_WE),
    .OE(RAM_R_OE),
    .D(RAM_R_D),
    .Q(RAM_R_Q)
);

RAM_INV_R ram_inv_r(
    .CK(clk),
    .A(RAM_INV_R_A),
    .WE(RAM_INV_R_WE),
    .OE(RAM_INV_R_OE),
    .D(RAM_INV_R_D),
    .Q_SEL(RAM_INV_R_Q_SEL),
    .Q(RAM_INV_R_Q)
);

RAM_S ram_s(
    .CK(clk),
    .A(RAM_S_A),
    .WE(RAM_S_WE),
    .OE(RAM_S_OE),
    .D(RAM_S_D),
    .Q(RAM_S_Q)
);

OMP u_omp(
    .clk(clk),
    .rst(rst),
    .start(start),
    .ROM_Y_Q(ROM_Y_Q),
    .ROM_Y_A(ROM_Y_A),
    .ROM_Y_OE(ROM_Y_OE),
    .RAM_Q_Q(RAM_Q_Q),
    .RAM_Q_A(RAM_Q_A),
    .RAM_Q_OE(RAM_Q_OE),
    .RAM_Q_D(RAM_Q_D),
    .RAM_Q_WE(RAM_Q_WE),
    .RAM_R_Q(RAM_R_Q),
    .RAM_R_A(RAM_R_A),
    .RAM_R_OE(RAM_R_OE),
    .RAM_R_D(RAM_R_D),
    .RAM_R_WE(RAM_R_WE),
    .RAM_THETA_Q(RAM_THETA_Q),
    .RAM_THETA_A(RAM_THETA_A),
    .RAM_THETA_OE(RAM_THETA_OE),
    .RAM_THETA_D(RAM_THETA_D),
    .RAM_THETA_WE(RAM_THETA_WE),
    .RAM_INV_R_Q(RAM_INV_R_Q),
    .RAM_INV_R_A(RAM_INV_R_A),
    .RAM_INV_R_OE(RAM_INV_R_OE),
    .RAM_INV_R_D(RAM_INV_R_D),
    .RAM_INV_R_WE(RAM_INV_R_WE),
    .RAM_INV_R_Q_SEL(RAM_INV_R_Q_SEL),
    .RAM_S_Q(RAM_S_Q),
    .RAM_S_A(RAM_S_A),
    .RAM_S_OE(RAM_S_OE),
    .RAM_S_D(RAM_S_D),
    .RAM_S_WE(RAM_S_WE),
    .done(done)
);



always #(`CYCLE/2) clk = ~clk;

initial begin
    $readmemh(`COMPRESSED, y_data);
    $readmemh(`THETA, theta_data);
end

initial begin

    for(col_num = 0; col_num<1; col_num=col_num+1)begin

        for(x=0; x<`ROM_MEM_SIZE; x=x+1)begin
            rom_y.memory[x] = y_data[`ROM_MEM_SIZE*col_num+x];
        end

        for(y=0; y<`RAM_THETA_MEM_SIZE; y=y+1)begin
            ram_theta.memory[y] = theta_data[y];
        end

        $display("Reconstructing %dth Column", col_num);
        for(i=0; i<`RAM_Q_MEM_SIZE; i=i+1)begin
            ram_q.memory[i] = 0;
        end
        for(j=0; j<`RAM_R_MEM_SIZE; j=j+1)begin
            ram_r.memory[j] = 0;
            ram_inv_r.memory[j] = 0;
        end
        for(k=0; k<`RAM_S_MEM_SIZE; k=k+1)begin
            ram_s.memory[k] = 0;
        end
        clk = 0; rst = 0; start = 0;
        #`CYCLE rst = 1;
        #`CYCLE rst = 0;
        #`CYCLE start = 1;
        #`CYCLE start = 0;
        wait(done);
        for(k=0; k<`RAM_S_MEM_SIZE; k=k+1)begin
            $display("At ram_s[%d] = %h", k, ram_s.memory[k]);
        end

    end
    #(`CYCLE*10) $finish;
end

initial begin
	$sdf_annotate("./OMP_syn.sdf", u_omp);
	$fsdbDumpfile("../syn/OMP.fsdb");
	$fsdbDumpvars();
	
end

// initial begin
//     $dumpfile("OMP.vcd");
//     $dumpvars;
//     $dumpvars(0, omp);
//     for(a=0; a<`REG_SIZE; a=a+1)begin
//         $dumpvars(1, omp.regfile.memory[a]);
//     end
//     for(b=0; b<`REG_RES_SIZE; b=b+1)begin
//         $dumpvars(1, omp.regfile_res.memory[b]);
//     end
//     for(f=0; f<`REG_DIV_SIZE; f=f+1)begin
//         $dumpvars(1, omp.regfile_div.memory[f]);
//     end
//     $dumpvars(0, ram_q);
//     for(c=0; c<`RAM_Q_MEM_SIZE; c=c+1)begin
//         $dumpvars(1, ram_q.memory[c]);
//     end
//     $dumpvars(0, ram_inv_r);
//     for(d=0; d<`RAM_R_MEM_SIZE; d=d+1)begin
//         $dumpvars(1, ram_inv_r.memory[d]);
//     end
//     $dumpvars(0, ram_r);
//     for(e=0; e<`RAM_R_MEM_SIZE; e=e+1)begin
//         $dumpvars(1, ram_r.memory[e]);
//     end
//     $dumpvars(0, ram_s);
//     for(g=0; g<`RAM_S_MEM_SIZE; g=g+1)begin
//         $dumpvars(1, ram_s.memory[g]);
//     end
//     for(h=0; h<`CORDIC_STAGE_NUM+1; h=h+1)begin
//         $dumpvars(1, omp.cordic.x[h]);
//         $dumpvars(1, omp.cordic.y[h]);
//         $dumpvars(1, omp.cordic.z_div[h]);
//     end
// end

endmodule
