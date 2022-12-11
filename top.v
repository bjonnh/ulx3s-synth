// gp[0] is midi_in

module top(input           clk_25mhz,
           input [4:0]  gp,
           output [4:0] gn,
           output [7:0] led,
           output       wifi_gpio0);


   // Tie GPIO0, keep board from rebooting
   assign wifi_gpio0 = 1'b1;
   reg [7:0]            o_led;
   reg [7:0]            byteValue;
   
   assign led= o_led;

   wire [23:0]          noteTicks;
   reg [7:0]            modulationValue;
   reg                  note_on;
   reg                  byte_ready;

   reg                  note_on;
   wire [7:0]           note;
   wire [7:0]           controllerNumber;
   wire [7:0]           controllerValue;
   wire                 controllerReady;


   reg signed [23:0]           l,r;

   MidiProcessor midiprocessor(clk_25mhz, gp[0], note_on, note, controllerNumber, controllerValue, controllerReady);

   wire                 din, lrclk, bclk, audioclk;

   reg [2:0]            adsr_state;
   reg                  mclk;

   I2Seasy i2s_instance (.sclk(clk_25mhz),  // input 25MHz
                         .mclk(mclk), .bclk(bclk), .lrclk(lrclk), .audioclk(audioclk),
                         .loutData(din), // output
                         .inLeft(l), .inRight(r) );
   assign gn[0] = din;   assign gn[1] = bclk;   assign gn[2] = lrclk;   assign gn[3] = mclk;

   wire [2:0]           adsr_state;

   reg [23:0]           l1,r1;

   VoiceDistributor voice_distributor(.mclk(clk_25mhz), .note_on(note_on), .note(note),
                                      .controllerNumber(controllerNumber), .controllerValue(controllerValue), .controllerReady(controllerReady),
                                      .l(l1), .r(r1));

   always @(posedge mclk) begin
      o_led[0] <= note_on;
      o_led[1] <= !note_on;
      l <= l1;
      r <= r1;
   end
endmodule // top

module VoiceDistributor(input wire mclk,
                        input wire                note_on, input wire [7:0] note,
                        input wire [7:0] controllerNumber, input wire [7:0] controllerValue, input wire controllerReady,
                        output wire signed [23:0] l, output wire signed [23:0] r);
   localparam                                voices=4;


   wire [23:0]                                    sampleTicks;

   reg [23:0]           lv[0:15],rv[0:15];

   reg             free1;

   reg [4:0]       i = 0;
   reg [4:0]       ishort = 0;
   reg         [7:0]    oldNote = 0;
   reg [23:0]           noteTicks;

   reg             voice_on [0:voices];
   reg [7:0]       voice_note [0:voices];
   reg [23:0]      voice_noteTicks [0:voices];
   wire       voice_free [0:voices];
   genvar voice_i;

   generate
      for (voice_i = 0; voice_i < voices; voice_i = voice_i + 1) begin : gen_loop
            Voice voice(.mclk(mclk), .gate_in(voice_on[voice_i]), .noteTicks(voice_noteTicks[voice_i]),
                        .controllerNumber(controllerNumber), .controllerValue(controllerValue), .controllerReady(controllerReady),
                        .l(lv[voice_i]), .r(rv[voice_i]), .free(voice_free[voice_i]));
      end
   endgenerate

   MidiNoteNumberToSampleTicks midiNoteNumberToSampleTicks(.mclk(mclk), .midiNoteNumber(note), .noteSampleTicks(noteTicks));

   always @(posedge mclk) begin
      for (ishort = 0 ; ishort < voices ; ishort = ishort + 1) begin
         if (!note_on && voice_note[ishort] == note && !voice_free[ishort])
           voice_on[ishort] <= 1'b0;
      end
      if (note_on && voice_free[i]) begin
         voice_note[i] <= note;
         voice_noteTicks[i] <= noteTicks;
         voice_on[i] <= 1'b1;
      end
      if (note_on && !voice_free[i] && voice_note[i] != note)
        if (i==voices-1)
          i <= 0;
        else
          i = i + 1;


      l <= lv[0] + lv[1] + lv[2] + lv[3] + lv[4];
 // + lv[5] + lv[6] + lv[7] + lv[8] + lv[9] + lv[10] + lv[11] + lv[12] + lv[13] + lv[14] + lv[15];
      r <= rv[0] + rv[1] + rv[2] + rv[3] + rv[4];
// + rv[5] + rv[6] + rv[7] + rv[8] + rv[9] + rv[10] + rv[11] + rv[12] + rv[13] + rv[14] + rv[15];

   end
endmodule



module Voice(input mclk, input gate_in, input wire [23:0] noteTicks,
             input wire [7:0]          controllerNumber, input wire [7:0] controllerValue, input wire controllerReady,
             output wire signed [23:0] l, output wire signed [23:0] r, output free);
   wire mclk;


   reg [15:0]  factor;
   reg [15:0]  op1_factor;
   reg [15:0]  op2_factor;
   reg signed [23:0] amplitude;
   wire [2:0]        adsr_state;
   wire signed [23:0] op1_audio;
   wire signed [23:0] op2_audio;
   wire signed [23:0] audio;
   wire               free;

   reg [7:0]          divider = 0;

   assign amplitude = { 9'b0, factor[15:0] }; // trick to make it signed

   assign free = (adsr_state == 0);

   //SquareWave square_wave(mclk, noteTicks, audiosquare);
   SineWave sine_wave_op2(mclk, noteTicks/4, op2_audio);
   SineWave sine_wave_op1(mclk, noteTicks/2 + (op2_audio*op2_factor)/1024, op1_audio);
   SineWave sine_wave2(mclk, noteTicks + (op1_audio*op1_factor)/1024, audio);
   ADSR adsr(.clk(mclk), .gate(gate_in),
             .attack_step(16'd2500), . attack_level(16'd1024),
             .decay_step(16'd2500),
             .sustain_level(16'd512),
             .release_step(16'd1000),
             .factor(factor),
             .adsr_state(adsr_state));
   ADSR adsr_op1(.clk(mclk), .gate(gate_in),
             .attack_step(16'd2500), . attack_level(16'd1024),
             .decay_step(16'd2500),
             .sustain_level(16'd1),
             .release_step(16'd1000),
             .factor(op1_factor));
   ADSR adsr_op2(.clk(mclk), .gate(gate_in),
             .attack_step(16'd5000), . attack_level(16'd1024),
             .decay_step(16'd5000),
             .sustain_level(16'd1),
             .release_step(16'd1000),
             .factor(op2_factor));


   always @(posedge mclk) begin
      l <=  audio * amplitude * 4;
      r <=  audio * amplitude * 4;
   end
endmodule


module SquareWave(input clk, input [23:0] noteTicks, output [23:0] audio);
   wire clockaudio, clocktick;
   wire [23:0] noteTicks;
   wire [23:0] audio= clockaudio ? 24'b11111111111 : 24'b0;
   Clock_divider clockdivider_for_clktick ( .clock_in(clk), .clock_out(clocktick), .div(8192) );
   Clock_divider clockdivider_for_audioclk ( .clock_in(clocktick), .clock_out(clockaudio), .div(noteTicks) );

endmodule

module SineWave(input clk, input [23:0] noteTicks, output [23:0] audio);
   localparam points=1024;
   wire       clk;
   reg [23:0] table [points-1:0];
      reg [9:0] phase;
      reg [32:0] tickCounter = 32'd0;

      wire signed [23:0] audio;
      wire               clockaudio;

      initial $readmemh("sine.mem", table);

         always @(posedge clk) begin
            tickCounter <= tickCounter + 32'd1;

            if (tickCounter>=noteTicks-1) begin
               tickCounter <= 32'd0;
               phase <= phase + 13'd1;
            end

            audio <= table[phase];
            end
endmodule

module ADSR(input clk, input gate,
            input [15:0]  attack_step, input [15:0] attack_level,
            input [15:0]  decay_step,
            input [15:0]  sustain_level,
            input [15:0]  release_step,
            output [15:0] factor, output [2:0] adsr_state);
   wire clk;
   reg [31:0] phase = 32'd0;
   reg signed [15:0] factor;

   wire              gate;
   reg               old = 0;
   reg               on = 0;
   reg [32:0]        stepCount = 32'd0;

   localparam
                     off_state = 3'd0,
                     attack_state = 3'd1,
                     decay_state = 3'd2,
                     sustain_state = 3'd3,
                     release_state = 3'd4;


   reg [2:0]         state = off_state;
   reg [2:0]         adsr_state;

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
              factor <= factor + 16'd1;
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
              factor <= factor - 16'd1;
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
              factor <= factor - 16'd1;
              stepCount <= 32'd0;
           end
        end
      endcase
   end
endmodule
