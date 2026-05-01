module PC (
    input                   [ 0 : 0]            clk,
    input                   [ 0 : 0]            rst,
    input                   [ 0 : 0]            en,
    input                   [31 : 0]            npc,

    output      reg         [31 : 0]            pc
);
always @(posedge clk) begin
    if (rst)
        pc <= 32'h00400000; 
    else begin
        if(en)
            pc <= npc;
        else
            pc <= pc;
    end
end

endmodule