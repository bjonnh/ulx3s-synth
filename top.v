// gp[0] is midi_in

module top(input clk_25mhz,
           input [4:0] 	gp, 
           output [4:0] gn,
           output [7:0] led,
           output 	wifi_gpio0);

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

    reg [23:0] l,r;

    MidiProcessor midiprocessor(i_clk, gp[0], note_on, noteTicks, modulationValue, debug);

    wire din, lrclk, bclk, audioclk;

    wire [23:0] audio;
    reg [23:0] factor;

    //SquareWave square_wave(audioclk, noteTicks, audio);
    SineWave sine_wave(bclk, noteTicks, audio);
    ADSR adsr(lrclk, note_on, factor);


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
      o_led[0] <= note_on;

      r <= $signed(audio * factor) * note_on;
      l <= $signed(audio * factor) * note_on;

    end
endmodule // top

module SquareWave(input clk, input [23:0] noteTicks, output [23:0] audio);
   wire clockaudio;
   wire [23:0] noteTicks;
   wire [23:0] audio= clockaudio ? 24'b1111111111111111111 : 24'b0;
   Clock_divider clockdivider_for_audioclk ( .clock_in(clk), .clock_out(clockaudio), .div(noteTicks) );
endmodule

module SineWave(input clk, input [23:0] noteTicks, output [23:0] audio);
    wire clk;
    reg [23:0] table [1023:0];
    initial $readmemh("sine.mem", table);
    reg[9:0] phase;
    wire [23:0] audio;

    wire  clockaudio;

    Clock_divider clockdivider_for_audioclk ( .clock_in(clk), .clock_out(clockaudio), .div(noteTicks) );
    always @(negedge clockaudio) begin
       phase <= phase+1;
       audio <= table[phase];

    end
endmodule

module ADSR(input clk, input gate, output [23:0] factor);
   wire clk;
   reg[8:0] phase;
   wire [23:0] factor;
   wire        gate;



   Clock_divider clockdivider_for_audioclk ( .clock_in(clk), .clock_out(clockaudio), .div(9) ); // need to recalibrate that
//   always @(posedge gate) begin
 //     phase <= 0;
  // end

   always @(posedge clkaudio) begin
      if (phase == 255)
                phase = 0;

      phase <= phase +1;
      factor <= phase;

   end

endmodule
