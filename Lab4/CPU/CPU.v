module CPU (
    input                   [ 0 : 0]            clk,
    input                   [ 0 : 0]            rst,
    input                   [ 0 : 0]            global_en,

/* ------------------------------ Memory (inst) ----------------------------- */
    output                  [31 : 0]            imem_raddr,
    input                   [31 : 0]            imem_rdata,

/* ------------------------------ Memory (data) ----------------------------- */
    input                   [31 : 0]            dmem_rdata,
    output                  [ 0 : 0]            dmem_we,
    output                  [31 : 0]            dmem_addr,
    output                  [31 : 0]            dmem_wdata,

/* ---------------------------------- Debug --------------------------------- */
    output                  [ 0 : 0]            commit,
    output                  [31 : 0]            commit_pc,
    output                  [31 : 0]            commit_instr,
    output                  [ 0 : 0]            commit_halt,
    output                  [ 0 : 0]            commit_reg_we,
    output                  [ 4 : 0]            commit_reg_wa,
    output                  [31 : 0]            commit_reg_wd,
    output                  [ 0 : 0]            commit_dmem_we,
    output                  [31 : 0]            commit_dmem_wa,
    output                  [31 : 0]            commit_dmem_wd,

    input                   [ 4 : 0]            debug_reg_ra,
    output                  [31 : 0]            debug_reg_rd 
);

    wire [31:0] cur_pc, npc;
    wire [31:0] cur_inst;
    wire [ 4:0] alu_op;
    wire [31:0] imm;
    wire [ 4:0] rf_ra0, rf_ra1, rf_wa;
    wire        rf_we;
    wire        alu_src0_sel, alu_src1_sel;
    wire [31:0] rf_rd0, rf_rd1, rf_wd;
    wire [31:0] alu_src0_real, alu_src1_real;
    wire [31:0] alu_res;

    wire [31:0] pc_add4;
    wire [31:0] pc_offset;
    wire [31:0] pc_j;
    wire [ 1:0] npc_sel;
    wire [ 3:0] br_type;
    wire [ 3:0] dmem_access;
    wire [ 1:0] rf_wd_sel;
    wire [31:0] slu_rd_out;
    wire [31:0] slu_wd_out;

    //取指通路
    assign imem_raddr = cur_pc;     
    assign cur_inst   = imem_rdata; 

    //PC相关的计算(适配NPCMUX)
    assign pc_add4   = cur_pc + 32'd4;
    assign pc_offset = cur_pc + imm;
    assign pc_j      = {alu_res[31:1],1'b0}; 

    //数据访存通路 
    assign dmem_addr  = alu_res;
    assign dmem_wdata = slu_wd_out;
    
    assign dmem_we    = dmem_access[3];

    PC u_pc (
        .clk (clk),
        .rst (rst),
        .en  (global_en),
        .npc (npc),
        .pc  (cur_pc)
    );

    NPCMUX u_npcmux (
        .pc_add4  (pc_add4),
        .pc_offset(pc_offset),
        .pc_j     (pc_j),
        .npc_sel  (npc_sel),
        .npc      (npc)
    );

    DECODER u_decode (
        .inst        (cur_inst),
        .alu_op      (alu_op),
        .dmem_access (dmem_access),
        .imm         (imm),
        .rf_ra0      (rf_ra0),
        .rf_ra1      (rf_ra1),
        .rf_wa       (rf_wa),
        .rf_we       (rf_we),
        .rf_wd_sel   (rf_wd_sel),   
        .alu_src0_sel(alu_src0_sel),
        .alu_src1_sel(alu_src1_sel),
        .br_type     (br_type)     
    );

    REG_FILE u_reg_file (
        .clk         (clk),
        .rf_ra0      (rf_ra0),
        .rf_ra1      (rf_ra1),
        .rf_wa       (rf_wa),
        .rf_we       (rf_we),
        .rf_wd       (rf_wd), 
        .rf_rd0      (rf_rd0),
        .rf_rd1      (rf_rd1),
        .debug_reg_ra(debug_reg_ra),
        .debug_reg_rd(debug_reg_rd)
    );

    BRANCH u_branch (
        .br_type(br_type),
        .br_src0(rf_rd0),
        .br_src1(rf_rd1),
        .npc_sel(npc_sel)
    );

    SLU u_slu (
        .addr       (alu_res),
        .dmem_access(dmem_access),
        .rd_in      (dmem_rdata), 
        .wd_in      (rf_rd1),     
        .rd_out     (slu_rd_out),
        .wd_out     (slu_wd_out)  
    );

    MUX2 #(32) u_rf_wd_mux (
        .src0(pc_add4),
        .src1(alu_res),
        .src2(slu_rd_out),//SLU处理后的rd_out
        .src3(32'h0),//ZERO
        .sel (rf_wd_sel),
        .res (rf_wd)//连向rf_wd
    );

    MUX1 #(.WIDTH(32)) u_mux_alu0 (
        .src0(rf_rd0),       
        .src1(cur_pc),       
        .sel (alu_src0_sel), 
        .res (alu_src0_real)
    );

    MUX1 #(.WIDTH(32)) u_mux_alu1 (
        .src0(rf_rd1),       
        .src1(imm),          
        .sel (alu_src1_sel), 
        .res (alu_src1_real)
    );

    ALU u_alu (
        .alu_src0(alu_src0_real),
        .alu_src1(alu_src1_real),
        .alu_op  (alu_op),
        .alu_res (alu_res)
    );


    reg  [ 0 : 0]   commit_reg          ;
    reg  [31 : 0]   commit_pc_reg       ;
    reg  [31 : 0]   commit_instr_reg    ;
    reg  [ 0 : 0]   commit_halt_reg     ;
    reg  [ 0 : 0]   commit_reg_we_reg   ;
    reg  [ 4 : 0]   commit_reg_wa_reg   ;
    reg  [31 : 0]   commit_reg_wd_reg   ;
    reg  [ 0 : 0]   commit_dmem_we_reg  ;
    reg  [31 : 0]   commit_dmem_wa_reg  ;
    reg  [31 : 0]   commit_dmem_wd_reg  ;

    always @(posedge clk) begin
        if (rst) begin
            commit_reg          <= 1'B0;
            commit_pc_reg       <= 32'H0;
            commit_instr_reg    <= 32'H0;
            commit_halt_reg     <= 1'B0;
            commit_reg_we_reg   <= 1'B0;
            commit_reg_wa_reg   <= 5'H0;
            commit_reg_wd_reg   <= 32'H0;
            commit_dmem_we_reg  <= 1'B0;
            commit_dmem_wa_reg  <= 32'H0;
            commit_dmem_wd_reg  <= 32'H0;
        end
        else if (global_en) begin
            commit_reg          <= 1'B1;
            commit_pc_reg       <= cur_pc;      
            commit_instr_reg    <= cur_inst;        
            commit_halt_reg     <= (cur_inst == 32'h00100073);//ebreak     
            commit_reg_we_reg   <= rf_we;       
            commit_reg_wa_reg   <= rf_wa;       
            commit_reg_wd_reg   <= rf_wd;       
            commit_dmem_we_reg  <= dmem_we;                         
            commit_dmem_wa_reg  <= dmem_addr;                        
            commit_dmem_wd_reg  <= dmem_wdata;       
        end
    end

    assign commit           = commit_reg;
    assign commit_pc        = commit_pc_reg;
    assign commit_instr     = commit_instr_reg;
    assign commit_halt      = commit_halt_reg;
    assign commit_reg_we    = commit_reg_we_reg;
    assign commit_reg_wa    = commit_reg_wa_reg;
    assign commit_reg_wd    = commit_reg_wd_reg;
    assign commit_dmem_we   = commit_dmem_we_reg;
    assign commit_dmem_wa   = commit_dmem_wa_reg;
    assign commit_dmem_wd   = commit_dmem_wd_reg;

endmodule