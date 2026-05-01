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

/*
2'b00: npc = pc_add4; 
2'b01: npc = pc_offset;(B-type、JAL)
2'b10: npc = pc_j;(JALR)
*/
module BRANCH(
    input                   [ 3 : 0]            br_type,

    input                   [31 : 0]            br_src0,
    input                   [31 : 0]            br_src1,

    output      reg         [ 1 : 0]            npc_sel
);

always @(*) begin
    case(br_type)
        `BR_BEQ: begin
            if(br_src0 == br_src1)
                npc_sel = 2'b01;
            else
                npc_sel = 2'b00; 
        end
        
        `BR_BNE: begin
            if(br_src0 != br_src1)
                npc_sel = 2'b01;
            else
                npc_sel = 2'b00;
        end
        
        `BR_BLT: begin
            if($signed(br_src0) < $signed(br_src1))
                npc_sel = 2'b01;
            else
                npc_sel = 2'b00;
        end
        
        `BR_BGE: begin
            if($signed(br_src0) >= $signed(br_src1))
                npc_sel = 2'b01;
            else
                npc_sel = 2'b00;
        end
        
        `BR_BLTU: begin
            if(br_src0 < br_src1)
                npc_sel = 2'b01;
            else
                npc_sel = 2'b00;
        end
        
        `BR_BGEU: begin
            if(br_src0 >= br_src1)
                npc_sel = 2'b01;
            else
                npc_sel = 2'b00;
        end
        
        `BR_JAL: begin
            npc_sel = 2'b01;
        end
        
        `BR_JALR: begin
            npc_sel = 2'b10;
        end
        
        default: begin
            npc_sel = 2'b00; 
        end
    endcase
end
endmodule