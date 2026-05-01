`define ADD                 5'B00000    
`define SUB                 5'B00010   
`define SLT                 5'B00100
`define SLTU                5'B00101
`define AND                 5'B01001
`define OR                  5'B01010
`define XOR                 5'B01011
`define SLL                 5'B01110   
`define SRL                 5'B01111    
`define SRA                 5'B10000  
`define SRC0                5'B10001
`define SRC1                5'B10010

module DECODE (
    input                   [31 : 0]            inst,

    output                  [ 4 : 0]            alu_op,//
    output                  [31 : 0]            imm,//

    output                  [ 4 : 0]            rf_ra0,//
    output                  [ 4 : 0]            rf_ra1,//
    output                  [ 4 : 0]            rf_wa,//
    output                  [ 0 : 0]            rf_we,//

    output                  [ 0 : 0]            alu_src0_sel,//
    output                  [ 0 : 0]            alu_src1_sel//
);
reg [4:0]  rf_ra0_reg;
reg [4:0]  rf_ra1_reg;
reg [4:0]  rf_wa_reg;
reg [4:0]  alu_op_reg;
reg [31:0] imm_reg;
reg rf_we_reg;
reg alu_src0_sel_reg;
reg alu_src1_sel_reg;


always @(*) begin
    rf_ra0_reg = inst[19:15];
    rf_ra1_reg = inst[24:20];
    rf_wa_reg  = inst[11:7];
    
    case (inst[6:0])
        7'b1100011: rf_we_reg = 0;//B-type
        7'b0100011: rf_we_reg = 0;//S-type
        7'b0001111: rf_we_reg = 0;//fence、fence.i
        7'b1110011: begin
            if(inst[11:7] == 5'b00000)
                rf_we_reg = 0;//ecall、ebreak
            else
                rf_we_reg = 1;
        end
        default: rf_we_reg = 1;
    endcase

    case (inst[6:0])
        7'b0000011, 7'b1100111, 7'b0010011: imm_reg = {{20{inst[31]}},inst[31:20]};
        7'b0100011: imm_reg = {{20{inst[31]}},inst[31:25],inst[11:7]};
        7'b1100011: imm_reg = {{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0};//B-type
        7'b0110111: imm_reg = {inst[31:12],12'b0};
        7'b0010111: imm_reg = {inst[31:12],12'b0};
        7'b1101111: imm_reg = {{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0};
        default: imm_reg = 0;
    endcase

    case (inst[6:0])
        //R-type
        7'b0110011: begin
            case ({inst[31:25], inst[14:12]})
                {7'b0000000, 3'b000}: alu_op_reg = `ADD;
                {7'b0100000, 3'b000}: alu_op_reg = `SUB;
                {7'b0000000, 3'b001}: alu_op_reg = `SLL;
                {7'b0000000, 3'b010}: alu_op_reg = `SLT;
                {7'b0000000, 3'b011}: alu_op_reg = `SLTU;
                {7'b0000000, 3'b100}: alu_op_reg = `XOR;
                {7'b0000000, 3'b101}: alu_op_reg = `SRL;
                {7'b0100000, 3'b101}: alu_op_reg = `SRA;
                {7'b0000000, 3'b110}: alu_op_reg = `OR;
                {7'b0000000, 3'b111}: alu_op_reg = `AND;
                default: alu_op_reg = `ADD;
            endcase
        end

        //I-type
        7'b0010011: begin
            case (inst[14:12])  
                3'b000: alu_op_reg = `ADD;  
                3'b010: alu_op_reg = `SLT;  
                3'b011: alu_op_reg = `SLTU;  
                3'b100: alu_op_reg = `XOR;   
                3'b110: alu_op_reg = `OR;   
                3'b111: alu_op_reg = `AND;   
                3'b001: alu_op_reg = `SLL;   
                3'b101: begin
                    if(inst[30] == 1'b0) 
                        alu_op_reg = `SRL;
                    else                  
                        alu_op_reg = `SRA;
                end
                default: alu_op_reg = `ADD;
            endcase
        end

        //Load
        7'b0000011: alu_op_reg = `ADD;

        //Store
        7'b0100011: alu_op_reg = `ADD;

        //Branch
        7'b1100011: alu_op_reg = `SUB;

        //LUI
        7'b0110111: alu_op_reg = `SRC1;

        //AUIPC
        7'b0010111: alu_op_reg = `ADD;

        //JAL
        7'b1101111: alu_op_reg = `ADD;

        //JALR
        7'b1100111: alu_op_reg = `ADD;

        default: alu_op_reg = `ADD;
    endcase

    case (inst[6:0])
        //I-type(arithmetic,loads,JALR),S-type,AUIPC,JAL,LUI需要立即数
        7'b0010011, 7'b0000011, 7'b0100011, 7'b1100111, 7'b0110111: begin
            alu_src0_sel_reg = 1'b0;
            alu_src1_sel_reg = 1'b1;
        end
        //AUIPC,JAL需要PC和立即数
        7'b0010111, 7'b1101111: begin
            alu_src0_sel_reg = 1'b1;
            alu_src1_sel_reg = 1'b1;
        end
        default: begin
            alu_src0_sel_reg = 1'b0;
            alu_src1_sel_reg = 1'b0;
        end
    endcase
end

assign rf_ra0 = rf_ra0_reg;
assign rf_ra1 = rf_ra1_reg;
assign rf_wa = rf_wa_reg;
assign alu_op = alu_op_reg;
assign imm = imm_reg;
assign rf_we = rf_we_reg;
assign alu_src0_sel = alu_src0_sel_reg;
assign alu_src1_sel = alu_src1_sel_reg;



endmodule