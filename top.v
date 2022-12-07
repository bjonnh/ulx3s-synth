// gp[0] is midi_in

module top(input           clk_25mhz,
           input  [4:0]    gp,
           output [4:0]    gn,
           output [7:0]    led,
           output          wifi_gpio0);

    wire i_clk;

    // Tie GPIO0, keep board from rebooting
    assign wifi_gpio0 = 1'b1;
    assign i_clk= clk_25mhz;
    reg [7:0] o_led;
    reg [7:0]  byteValue;
   
    assign led= o_led;

    wire [23:0] noteTicks;
    reg [7:0] modulationValue;
    reg note_on;
    reg    byte_ready;
    reg    debug;
    reg    waiting;
    reg    signal;
    reg    complete;


    reg        note_on;
    reg [23:0] noteTicks;
    reg [23:0] oldNoteTicks;


    reg [23:0] l,r;

    MidiProcessor midiprocessor(i_clk, gp[0], note_on, noteTicks, modulationValue, debug);

    wire din, lrclk, bclk, audioclk;

    wire signed [23:0] audio;
    reg [15:0] factor;
    reg signed [23:0] amplitude;
    assign amplitude = { 9'b0, factor[15:0] }; // trick to make it signed

    reg        zero;
    reg        zeroCut;
    reg        reset;


    //SquareWave square_wave(audioclk, noteTicks, audio);
    SineWave sine_wave(i_clk, noteTicks, audio, zero);
    ADSR adsr(i_clk, note_on, reset, factor);

    I2Seasy i2s_instance
       (
      .sclk(i_clk),  // input 25MHz
      .bclk(bclk),   // output i_clk/4
      .lrclk(lrclk),         // output 97.6565 KHz
      .audioclk(audioclk), // output lrclk/2
      .loutData(din), // output
      .inLeft(l), // input
      .inRight(r), // input
      );

     assign gn[0] = din;
     assign gn[1] = bclk;
     assign gn[2] = lrclk;
     assign gn[3] = clk_25mhz;

    always @(posedge i_clk) begin
      // We start and stop when the signal crosses 0, this cause a small delay but removes a crack
      if (!note_on) begin
        oldNoteTicks <= 0;
        reset <= 0;
      end

      if (note_on)
        if (oldNoteTicks != noteTicks)
          reset <= 1;
        else
          reset <= 0;

      o_led[0] <= note_on;
      o_led[1] <= !note_on;

      r <= audio * amplitude;
      l <= audio * amplitude;
      oldNoteTicks <= noteTicks;
    end
endmodule // top

module SquareWave(input clk, input [23:0] noteTicks, output [23:0] audio);
   wire clockaudio;
   wire [23:0] noteTicks;
   wire [23:0] audio= clockaudio ? 24'b1111111111111111111 : 24'b0;
   Clock_divider clockdivider_for_audioclk ( .clock_in(clk), .clock_out(clockaudio), .div(noteTicks) );
endmodule

module SineWave(input clk, input [23:0] noteTicks, output [23:0] audio, output zero);
    wire clk;
    reg [23:0] table [1023:0];
    initial $readmemh("sine.mem", table);
    reg[9:0] phase;
    reg [32:0] tickCounter = 32'd0;

    wire signed [23:0] audio;
    wire clockaudio;
    wire zero;

    always @(posedge clk) begin
       tickCounter <= tickCounter + 32'd1;
       if (tickCounter>=noteTicks) begin
          tickCounter <= 32'd0;
          phase <= phase + 9'd1;
       end

       zero = (phase == 10'd512);

       audio <= table[phase];
    end
endmodule

module ADSR(input clk, input gate, input reset,  output [15:0] factor);
   wire clk;
   reg[31:0] phase = 32'd0;
   wire signed [15:0] factor;
   wire               reset;

   wire       gate;
   reg        old = 0;
   reg        on = 0;
   reg [32:0] stepCount = 32'd0;


   localparam
             attack = 32'd25400000,
             decay = 32'd2540000,
             release = 32'd25400000,
             steps = 32'd255;

   localparam
             attack_step = 32'd100000,
             decay_step = 32'd1000,
             release_step = 32'd100000;

//   Clock_divider clockdivider_for_audioclk ( .clock_in(clk), .clock_out(clockaudio), .div(9) ); // need to recalibrate that
//   always @(posedge gate) begin
 //     phase <= 0;
  // end
   always @(posedge clk) begin
      // Stop if gate=0
      if ((!gate) && (phase == 0)) begin
         on = 1'b0;
         old = 1'b0;
         phase = 1'b0;
         factor <= 23'b0;
         stepCount = 32'd0;
      end

      // Attack if gate=1
      if (gate || (phase >0)) begin
         // If we were stopped we start
         if ((old == 0) || reset) begin
            on = 1'b1;
            old = 1;
            phase = 0;
            factor <= 1;
            stepCount <= 0;
         end

         // If running we count
         if (on) begin
            if ((!gate) && (phase < attack+decay)) begin
              phase <= attack+decay+1;
              stepCount <= 0;
            end
            else begin
               phase <= phase + 1;
            //factor <= 255;
               stepCount <= stepCount + 1;
            end
            if (phase < attack) begin
              if (stepCount >= attack_step) begin
                 stepCount <= 32'd0;
                 factor <= factor + 1;
              end
            end
            if (phase >= attack && phase < attack+decay) begin
              if (stepCount > decay_step) begin
                stepCount <= 32'd0;
                if (factor >0)
                 factor <= factor - 1;
              end
            end
            if (phase >= attack+decay && phase < attack+decay+release) begin
              if (stepCount > release_step) begin
                stepCount <= 32'd0;
                if (factor >0)
                  factor <= factor - 1;
              end
            end

            if (phase >= attack+decay+release) begin
              on = 0;
              phase <= 0;
              factor <= 0;
            end
         end
         // If end of envelope we turn everything off
         // And we have to wait for a retrigger to set old to 0

      end
   end

endmodule
