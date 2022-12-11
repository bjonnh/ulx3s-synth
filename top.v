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
   reg                  debug;
   reg                  waiting;
   reg                  signal;
   reg                  complete;


   reg                  note_on;
   wire [7:0]           note;

   reg signed [23:0]           l,r;

   wire [127:0]         noteRegister;

   MidiProcessor midiprocessor(clk_25mhz, gp[0], note_on, note, modulationValue, noteRegister, debug);

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


   VoiceDistributor voice_distributor(.mclk(clk_25mhz), .note_on(note_on), .note(note), .l(l1), .r(r1), .adsr_state(adsr_state));
   //wire [23:0]      sampleTicks;
   //MidiNoteNumberToSampleTicks midiNoteNumberToSampleTicks(.mclk(mclk), .midiNoteNumber(note), .noteSampleTicks(sampleTicks));

   //Voice voice1(.mclk(mclk), .gate_in(note_on), .noteTicks(sampleTicks), .l(l1), .r(r1), .free(free1), .adsr_state(adsr_state));

   always @(posedge mclk) begin
      o_led[0] <= note_on;
      o_led[1] <= !note_on;
      o_led[2] <= adsr_state == 3'd0;
      o_led[3] <= adsr_state == 3'd1;
      o_led[4] <= adsr_state == 3'd2;
      o_led[5] <= adsr_state == 3'd3;
      o_led[6] <= adsr_state == 3'd4;
      l <= l1;
      r <= r1;
   end
endmodule // top

module VoiceDistributor(input wire mclk,
                        input wire                note_on, input wire [7:0] note,
                        output wire signed [23:0] l, output wire signed [23:0] r,
                        output reg [2:0]          adsr_state);
   localparam                                voices=4;


   wire [23:0]                                    sampleTicks;

   reg [23:0]           lv[0:15],rv[0:15];

   reg             free1;

   reg [4:0]       i = 0;
   reg [4:0]       ishort = 0;
   reg         [7:0]    oldNote = 0;
   reg             voice_on [0:15];
   reg [7:0]       voice_note [0:15];
   wire [2:0]      voice_adsr [0:15];

   genvar voice_i;

   generate
      for (voice_i = 0; voice_i < voices; voice_i = voice_i + 1) begin : gen_loop
            Voice voice(.mclk(mclk), .gate_in(voice_on[voice_i]), .note(voice_note[voice_i]), .l(lv[voice_i]), .r(rv[voice_i]), .adsr_state(voice_adsr[voice_i]));
      end
   endgenerate

   always @(posedge mclk) begin
      adsr_state <= voice_adsr[0];

      for (ishort = 0 ; ishort < voices ; ishort = ishort + 1) begin
         if (!note_on && voice_note[ishort] == note && voice_adsr[ishort] != 0)
           voice_on[ishort] <= 1'b0;
      end
      if (note_on && voice_adsr[i] == 0) begin
         voice_note[i] <= note;
         voice_on[i] <= 1'b1;
      end
      if (note_on && voice_adsr[i] != 0 && voice_note[i] != note)
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



module Voice(input mclk, input gate_in, input wire [7:0] note, output wire signed [23:0] l, output wire signed [23:0] r, output free, output [2:0] adsr_state);
   wire mclk;
   reg [23:0] noteTicks;
   reg [15:0]  factor;
   reg signed [23:0] amplitude;
   wire [2:0]        adsr_state;
   wire signed [23:0] audio;
   wire signed [23:0] audio2;
   wire               free;

   MidiNoteNumberToSampleTicks midiNoteNumberToSampleTicks(.mclk(mclk), .midiNoteNumber(note), .noteSampleTicks(noteTicks));

   assign amplitude = { 9'b0, factor[15:0] }; // trick to make it signed

   assign free = (adsr_state == 0);

   //SquareWave square_wave(mclk, noteTicks, audiosquare);
   SineWave sine_wave(mclk, noteTicks, audio, zero);
   SineWave sine_wave2(mclk, $signed(1 + audio/8) * noteTicks/2, audio2, zero);
   ADSR adsr(mclk, gate_in, factor, adsr_state);

   always @(posedge mclk) begin
      l <=  audio2 * amplitude;
      r <=  audio2 * amplitude;
   end
endmodule


module SquareWave(input clk, input [23:0] noteTicks, output [23:0] audio);
   wire clockaudio, clocktick;
   wire [23:0] noteTicks;
   wire [23:0] audio= clockaudio ? 24'b11111111111 : 24'b0;
   Clock_divider clockdivider_for_clktick ( .clock_in(clk), .clock_out(clocktick), .div(8192) );
   Clock_divider clockdivider_for_audioclk ( .clock_in(clocktick), .clock_out(clockaudio), .div(noteTicks) );

endmodule

module SineWave(input clk, input [23:0] noteTicks, output [23:0] audio, output zero);
   localparam points=1024;
   wire       clk;
   reg [23:0] table [points-1:0];
      reg [9:0] phase;
      reg [32:0] tickCounter = 32'd0;

      wire signed [23:0] audio;
      wire               clockaudio;
         wire               zero;

      initial $readmemh("sine.mem", table);

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

module ADSR(input clk, input gate, output [15:0] factor, output [2:0] adsr_state);
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
endmodule
