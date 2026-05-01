module SLU (
    input                   [31 : 0]                addr,
    input                   [ 3 : 0]                dmem_access,

    input                   [31 : 0]                rd_in,
    input                   [31 : 0]                wd_in,

    output      reg         [31 : 0]                rd_out,
    output      reg         [31 : 0]                wd_out
);

wire [1:0] offset = addr[1:0];//二进制数截取3位以上必是4的倍数，此处为余数

//rd_out
always @(*) begin
    case (dmem_access[2:0])
        3'b000: begin//lb
            case (offset)
                2'b00: rd_out = {{24{rd_in[7]}},  rd_in[7:0]};
                2'b01: rd_out = {{24{rd_in[15]}}, rd_in[15:8]};
                2'b10: rd_out = {{24{rd_in[23]}}, rd_in[23:16]};
                2'b11: rd_out = {{24{rd_in[31]}}, rd_in[31:24]};
            endcase
        end
        3'b001: begin//lh
            case (offset)
                2'b00: rd_out = {{16{rd_in[15]}}, rd_in[15:0]};
                2'b10: rd_out = {{16{rd_in[31]}}, rd_in[31:16]};
                default: rd_out = rd_in;//非对齐不处理
            endcase
        end
        3'b010: rd_out = rd_in;//lw
        3'b100: begin//lbu
            case (offset)
                2'b00: rd_out = {24'b0, rd_in[7:0]};
                2'b01: rd_out = {24'b0, rd_in[15:8]};
                2'b10: rd_out = {24'b0, rd_in[23:16]};
                2'b11: rd_out = {24'b0, rd_in[31:24]};
            endcase
        end
        3'b101: begin//lhu
            case (offset)
                2'b00: rd_out = {16'b0, rd_in[15:0]};
                2'b10: rd_out = {16'b0, rd_in[31:16]};
                default: rd_out = rd_in;
            endcase
        end
        default: rd_out = rd_in;
    endcase
end

//wd_out
//最高位为1才代表要写内存
always @(*) begin
    if(dmem_access[3]) begin
        case (dmem_access[2:0])
            3'b000: begin//sb
                case (offset)
                    2'b00: wd_out = {rd_in[31:8],  wd_in[7:0]};
                    2'b01: wd_out = {rd_in[31:16], wd_in[7:0],  rd_in[7:0]};
                    2'b10: wd_out = {rd_in[31:24], wd_in[7:0],  rd_in[15:0]};
                    2'b11: wd_out = {wd_in[7:0],   rd_in[23:0]};
                endcase
            end
            3'b001: begin//sh
                case (offset)
                    2'b00: wd_out = {rd_in[31:16], wd_in[15:0]};
                    2'b10: wd_out = {wd_in[15:0],  rd_in[15:0]};
                    default: wd_out = wd_in;
                endcase
            end
            3'b010: wd_out = wd_in;//sw
            default: wd_out = wd_in;
        endcase
    end else begin
        wd_out = wd_in;
    end
end

endmodule