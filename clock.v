// Adapted from https://www.fpga4student.com/2017/08/verilog-code-for-clock-divider-on-fpga.html
module Clock_divider
(
    clock_in,
    clock_out,
    div
);
    input clock_in;
    output reg clock_out;
    reg[27:0] counter=28'd0;
    input reg [27:0] div;

    always @(posedge clock_in)
    begin
        counter <= counter + 28'd1;
        if(counter>=(div-1))
            counter <= 28'd0;
        clock_out <= (counter<div/2)?1'b1:1'b0;
    end
endmodule
