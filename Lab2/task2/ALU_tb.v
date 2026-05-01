`define ADD  5'b00000
`define SUB  5'b00010  
`define SLT  5'b00100
`define SLTU 5'b00101
`define AND  5'b01001
`define OR   5'b01010
`define XOR  5'b01011
`define SLL  5'b01110  
`define SRL  5'b01111  
`define SRA  5'b10000 
`define SRC0 5'b10001  
`define SRC1 5'b10010  

module ALU_tb;
    reg [31:0] src0;
    reg [31:0] src1;
    reg [4:0]  sel;

    wire [31:0] alu_res;

    ALU uut (
        .alu_src0(src0),
        .alu_src1(src1),
        .alu_op(sel),
        .alu_res(alu_res)
    );

    initial begin
        src0 = 32'h2;
        src1 = 32'h2;
        
        sel = `ADD;  #20;
        sel = `SUB;  #20;
        sel = `SLT;  #20;
        sel = `SLTU; #20;
        sel = `AND;  #20;
        sel = `OR;   #20;
        sel = `XOR;  #20;
        sel = `SLL;  #20;
        sel = `SRL;  #20;
        sel = `SRA;  #20;
        sel = `SRC0; #20;
        sel = `SRC1; #20;

        $finish;
    end
endmodule