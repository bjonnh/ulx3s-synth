// Inspired from https://github.com/AndrewJones-PSU/I2S2Test/blob/master/I2S2Test.srcs/modules/I2SInterface.sv


// This will generate all the clocks by itself from a 25MHz
module I2Seasy(
        input        sclk,
        output       loutData,
        output       lrclk,
        output       audioclk,
        output       bclk,
        input [23:0] inLeft, // left signal to line out
        input [23:0] inRight, // right signal to line out
   );

    wire [3:0]   clocks;

    ecp5pll
       #(
         .in_hz(25000000),
         .out0_hz(12500000), .out0_tol_hz(0),
         .out1_hz( 6250000), .out1_tol_hz(0),
         .out2_hz( 6250000), .out2_tol_hz(10),
         .out3_hz( 6250000), .out3_tol_hz(0)
       )
    ecp5pll_inst
       (
        .clk_i(sclk),
        .clk_o(clocks)
       );

    Clock_divider  clockdivider_for_lrclk
        ( .clock_in(clocks[1]), .clock_out(lrclk), .div(64) );

    assign bclk = clocks[1];

    Clock_divider clockdivider_for_audioclk
        ( .clock_in(lrclk), .clock_out(audioclk), .div(2) );

    I2SInterface i2s_instance
       (
      .sclk(sclk),  // 25MHz
      .bclk(clocks[1]),  // 6.25MHz
      .lr(audioclk),         // 97.6565/2 KHz
      .loutData(loutData),
      .inLeft(inLeft),
      .inRight(inRight),
      );
endmodule

module I2SInterface(
        input sclk, // 25 MHz System clock
        input bclk, // 6.25 MHz Bit Clock
        input lr, // Left/Right Channel Select
        output loutData, // Line Out Data

        input [23:0] inLeft, // left signal to line out
        input [23:0] inRight, // right signal to line out

    );

    reg [63:0] outputShift;
    reg [1:0] bclkEdge; // track the rising/falling edge of the bit clock
    reg [1:0] lrEdge; // track the rising/falling edge of the left/right channel select
    reg frameSync; // track the rising/falling edge of the frame sync

    always @(posedge sclk)
    begin
        // frame syncing
        if (lrEdge == 2'b10)
            frameSync <= 1'b1;
        else if (bclkEdge == 2'b01)
            frameSync <= 1'b0;

        // output shifting
        if (bclkEdge == 2'b01)
        begin
            loutData <= outputShift[63];
            outputShift <= {outputShift[62:0], 1'b0};
        end
        else if (bclkEdge == 2'b00 && frameSync == 1'b1)
            outputShift <= {inLeft, 8'b0, inRight, 8'b0};

        // edge tracking
        bclkEdge <= {bclkEdge[0], bclk};
        lrEdge <= {lrEdge[0], lr};

    end
endmodule
