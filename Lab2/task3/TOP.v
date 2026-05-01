module TOP (
    input                   [ 0 : 0]            clk,
    input                   [ 0 : 0]            rst,

    input                   [ 0 : 0]            enable,
    input                   [ 4 : 0]            in,
    input                   [ 1 : 0]            ctrl,

    output                  [ 3 : 0]            seg_data,
    output                  [ 2 : 0]            seg_an
);

reg [31:0] alu_src0, alu_src1, alu_res;
reg [4:0] alu_op;
reg [31:0] output_data;
wire [31:0] in_text = in[4]?{27'b1,in}:{27'b0,in};//符号拓展
wire [31:0] alu_res_wire;

always @(posedge clk) begin
    if(rst)begin
            alu_src0 <= 32'd0;
            alu_src1 <= 32'd0;
            alu_op   <= 5'd0;
            output_data <= 5'd0;
    end
    else if(enable) begin
        case (ctrl)
            2'B00:
                alu_op <= in[4:0];
            2'B01:
                alu_src0 <= in_text[31:0];
            2'B10:
                alu_src1 <= in_text[31:0];
            2'B11:
                output_data <= alu_res;
            default:;
        endcase
    end
end

Segment u_segment (
    .clk(clk),             
    .rst(rst),             
    .output_data(output_data), 
    .seg_data(seg_data),   
    .seg_an(seg_an)        
);

ALU u_alu (
    .alu_src0(alu_src0),
    .alu_src1(alu_src1),
    .alu_op(alu_op),
    .alu_res(alu_res_wire)
);

always @(posedge clk) begin
    alu_res <= alu_res_wire;
end

dist_mem_gen_0 u_mem (
  .a(a),      // input wire [5 : 0] a
  .d(d),      // input wire [15 : 0] d
  .clk(clk),  // input wire clk
  .we(we),    // input wire we
  .spo(spo)  // output wire [15 : 0] spo
);

endmodule