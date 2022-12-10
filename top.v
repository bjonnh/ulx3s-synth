// gp[0] is midi_in

module top(input           clk_25mhz,
           input  [4:0]    gp,
           output [4:0]    gn,
           output [7:0]    led,
           output          wifi_gpio0);


    // Tie GPIO0, keep board from rebooting
    assign wifi_gpio0 = 1'b1;
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

    MidiProcessor midiprocessor(clk_25mhz, gp[0], note_on, noteTicks, modulationValue, debug);

    wire din, lrclk, bclk, audioclk;

    wire signed [23:0] audio;
    wire signed [23:0] audiosquare;
    reg [15:0] factor;
    reg signed [23:0] amplitude;
    assign amplitude = { 9'b0, factor[15:0] }; // trick to make it signed

    reg        zero;
    reg        zeroCut;
    reg        reset;

    wire [2:0] adsr_state;


    SquareWave square_wave(clk_25mhz, noteTicks, audiosquare);
    SineWave sine_wave(clk_25mhz, noteTicks, audio, zero);
    ADSR adsr(clk_25mhz, note_on, reset, factor, adsr_state);
    reg        mclk;

    I2Seasy i2s_instance
       (
      .sclk(clk_25mhz),  // input 25MHz
      .mclk(mclk),
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
     assign gn[3] = mclk;



    always @(posedge mclk) begin
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
      o_led[2] <= adsr_state == 3'd0;
      o_led[3] <= adsr_state == 3'd1;
      o_led[4] <= adsr_state == 3'd2;
      o_led[5] <= adsr_state == 3'd3;
      o_led[6] <= adsr_state == 3'd4;

       r <= audio * amplitude;
       l <= audiosquare * amplitude;
      oldNoteTicks <= noteTicks;
    end
endmodule // top

module SquareWave(input clk, input [23:0] noteTicks, output [23:0] audio);
   wire clockaudio, clocktick;
   wire [23:0] noteTicks;
   wire [23:0] audio= clockaudio ? 24'b11111111111 : 24'b0;
   Clock_divider clockdivider_for_clktick ( .clock_in(clk), .clock_out(clocktick), .div(8192) );
   Clock_divider clockdivider_for_audioclk ( .clock_in(clocktick), .clock_out(clockaudio), .div(noteTicks) );

endmodule

module SineWave(input clk, input [23:0] noteTicks, output [23:0] audio, output zero);
   localparam points=8191;

    wire clk;
    reg [23:0] table [points-1:0];
    initial $readmemh("sine.mem", table);
    reg[12:0] phase;
    reg [32:0] tickCounter = 32'd0;

    wire signed [23:0] audio;
    wire clockaudio;
    wire zero;

    always @(posedge clk) begin
       tickCounter <= tickCounter + 32'd1;

       if (tickCounter>=noteTicks-1) begin
          tickCounter <= 32'd0;
          phase <= phase + 13'd1;
       end
       zero = (phase == 12'd4096);

       audio <= table[phase];
    end
endmodule

module ADSR(input clk, input gate, input reset,  output [15:0] factor, output [2:0] adsr_state);
   wire clk;
   reg[31:0] phase = 32'd0;
   reg signed [15:0] factor;
   wire               reset;

   wire       gate;
   reg        old = 0;
   reg        on = 0;
   reg [32:0] stepCount = 32'd0;

   localparam
             off_state = 3'd0,
             attack_state = 3'd1,
             decay_state = 3'd2,
             sustain_state = 3'd3,
             release_state = 3'd4;


   reg [2:0] state = off_state;
   wire [2:0] adsr_state;

   localparam
             attack_step = 32'd10000,
             attack_level = 15'd1024,
             decay_step = 32'd10000,
             sustain_level = 15'd512,
             release_step = 32'd10000;

   always @(posedge clk) begin
      adsr_state <= state;
      if (state != off_state) begin
         phase <= phase + 1;
         stepCount <= stepCount + 15'd1;
      end

      case(state)
        off_state: begin
           if (gate)
             state <= attack_state;
           factor <= 0;
           stepCount <= 0;
           phase <= 0;
        end
        attack_state: begin
           if (!gate) begin
              state <= release_state;
              stepCount <= 0;
              phase <= 0;
           end
           if (factor == attack_level) begin
              stepCount <= 0;
              phase <= 0;
              state <= decay_state;
           end

           if (stepCount > attack_step) begin
              factor <= factor + 15'd1;
              stepCount <= 32'd0;
           end
        end
        decay_state: begin
           if (!gate) begin
              state <= release_state;
              stepCount <= 0;
              phase <= 0;
           end
           if (factor == sustain_level) begin
              stepCount <= 0;
              phase <= 0;
              state <= sustain_state;
           end
           if (stepCount > decay_step) begin
              factor <= factor - 15'd1;
              stepCount <= 32'd0;
           end
        end
        sustain_state: begin
           if (!gate) begin
              state <= release_state;
              stepCount <= 0;
              phase <= 0;
           end
        end
        release_state: begin
           if (gate) begin
              state <= attack_state;
              stepCount <= 0;
              phase <= 0;
           end

           if (factor == 0)
             state <= off_state;
           if (stepCount > release_step) begin
              factor <= factor - 15'd1;
              stepCount <= 32'd0;
           end
        end
      endcase
   end
//   Clock_divider clockdivider_for_audioclk ( .clock_in(clk), .clock_out(clockaudio), .div(9) ); // need to recalibrate that
//   always @(posedge gate) begin
 //     phase <= 0;
  // end
/*   always @(posedge clk) begin
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
*/
endmodule
