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


//基础条件分支(低3位funct3)
`define BR_BEQ    4'b0000 
`define BR_BNE    4'b0001  
`define BR_BLT    4'b0100  
`define BR_BGE    4'b0101  
`define BR_BLTU   4'b0110 
`define BR_BGEU   4'b0111  
//无条件跳转
`define BR_JAL    4'b1000 
`define BR_JALR   4'b1001 
//默认不跳转
`define BR_NONE   4'b1111


`define RF_WD_PC4    2'b00//选PC+4(JAL,JALR)
`define RF_WD_ALU    2'b01//选ALU结果(R-type,I-type,LUI,AUIPC)
`define RF_WD_DRAM   2'b10//选Data Memory(Load)


module DECODER (
    input                   [31 : 0]            inst,

    output      reg         [ 4 : 0]            alu_op,//

    output                  [ 3 : 0]            dmem_access,//

    output      reg         [31 : 0]            imm,//

    output                  [ 4 : 0]            rf_ra0,//
    output                  [ 4 : 0]            rf_ra1,//
    output                  [ 4 : 0]            rf_wa,//
    output                  [ 0 : 0]            rf_we,//
    output      reg         [ 1 : 0]            rf_wd_sel,//

    output                  [ 0 : 0]            alu_src0_sel,//
    output                  [ 0 : 0]            alu_src1_sel,//

    output                  [ 3 : 0]            br_type//
);
reg [4:0]  rf_ra0_reg;
reg [4:0]  rf_ra1_reg;
reg [4:0]  rf_wa_reg;
reg [3:0]  br_type_reg;
reg [3:0] dmem_access_reg;
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
        7'b0000011, 7'b1100111, 7'b0010011: imm = {{20{inst[31]}},inst[31:20]};
        7'b0100011: imm = {{20{inst[31]}},inst[31:25],inst[11:7]};
        7'b1100011: imm = {{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0};//B-type
        7'b0110111: imm = {inst[31:12],12'b0};
        7'b0010111: imm = {inst[31:12],12'b0};
        7'b1101111: imm = {{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0};
        default: imm = 0;
    endcase

    case (inst[6:0])
        //R-type
        7'b0110011: begin
            case ({inst[31:25], inst[14:12]})
                {7'b0000000, 3'b000}: alu_op = `ADD;
                {7'b0100000, 3'b000}: alu_op = `SUB;
                {7'b0000000, 3'b001}: alu_op = `SLL;
                {7'b0000000, 3'b010}: alu_op = `SLT;
                {7'b0000000, 3'b011}: alu_op = `SLTU;
                {7'b0000000, 3'b100}: alu_op = `XOR;
                {7'b0000000, 3'b101}: alu_op = `SRL;
                {7'b0100000, 3'b101}: alu_op = `SRA;
                {7'b0000000, 3'b110}: alu_op = `OR;
                {7'b0000000, 3'b111}: alu_op = `AND;
                default: alu_op = `ADD;
            endcase
        end

        //I-type
        7'b0010011: begin
            case (inst[14:12])  
                3'b000: alu_op = `ADD;  
                3'b010: alu_op = `SLT;  
                3'b011: alu_op = `SLTU;  
                3'b100: alu_op = `XOR;   
                3'b110: alu_op = `OR;   
                3'b111: alu_op = `AND;   
                3'b001: alu_op = `SLL;   
                3'b101: begin
                    if(inst[30] == 1'b0) 
                        alu_op = `SRL;
                    else                  
                        alu_op = `SRA;
                end
                default: alu_op = `ADD;
            endcase
        end

        //Load
        7'b0000011: alu_op = `ADD;

        //Store
        7'b0100011: alu_op = `ADD;

        //Branch
        7'b1100011: alu_op = `SUB;

        //LUI
        7'b0110111: alu_op = `SRC1;

        //AUIPC
        7'b0010111: alu_op = `ADD;

        //JAL
        7'b1101111: alu_op = `ADD;

        //JALR
        7'b1100111: alu_op = `ADD;

        default: alu_op = `ADD;
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

    //br_type
    case (inst[6:0])
        7'b1100011: begin//B-type
            case (inst[14:12])
                3'b000: br_type_reg = `BR_BEQ;
                3'b001: br_type_reg = `BR_BNE;
                3'b100: br_type_reg = `BR_BLT;
                3'b101: br_type_reg = `BR_BGE;
                3'b110: br_type_reg = `BR_BLTU;
                3'b111: br_type_reg = `BR_BGEU;
                default: br_type_reg = `BR_NONE;
            endcase
        end

        7'b1101111: br_type_reg = `BR_JAL;
        7'b1100111: br_type_reg = `BR_JALR;
        default: br_type_reg = `BR_NONE;
    endcase

    //rf_wd_sel
    case (inst[6:0])
        7'b0000011:          
            rf_wd_sel = `RF_WD_DRAM;//Load:选内存数据
        7'b1101111:          
            rf_wd_sel = `RF_WD_PC4;//JAL:选PC+4
        7'b1100111:          
            rf_wd_sel = `RF_WD_PC4;//JALR:选PC+4
        default:             
            rf_wd_sel = `RF_WD_ALU;//默认:选ALU结果(包含R-type,I-type,LUI,AUIPC)
    endcase

    //dmem_access
    case (inst[6:0])
        7'b0000011: begin//Load
            dmem_access_reg = {1'b0,inst[14:12]};//最高位0表示读，低三位funct3
        end
        7'b0100011: begin//Store
            dmem_access_reg = {1'b1,inst[14:12]};//最高位1表示写，低三位funct3
        end
        default: begin
            dmem_access_reg = 4'b0000;//非访存指令
        end
    endcase
end

assign rf_ra0 = rf_ra0_reg;
assign rf_ra1 = rf_ra1_reg;
assign rf_wa = rf_wa_reg;
assign rf_we = rf_we_reg;
assign br_type = br_type_reg;
assign alu_src0_sel = alu_src0_sel_reg;
assign alu_src1_sel = alu_src1_sel_reg;
assign dmem_access = dmem_access_reg;


endmodule