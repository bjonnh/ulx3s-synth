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

    reg [23:0] noteTicks;
    reg [7:0] modulationValue;
    reg note_on;
   reg 	byte_ready;
   reg 	debug;
   reg 	waiting;
   reg 	signal;
   reg 	complete;


   reg 	note_on;
   reg [23:0] noteTicks;

   reg signed [15:0] l,r;
   reg 	      phase_state = 0;
   reg [23:0] counter = 0;
   
    wire [11:0] pcm_trianglewave;
    // triangle wave generator /\/\/
    trianglewave trianglewave_instance
    (
      .clk(clk_25mhz),
      .noteTicks(noteTicks),
      .pcm(pcm_trianglewave)
    );


   
MidiProcessor midiprocessor(
	i_clk,
	gp[0],
	note_on,
	noteTicks,
	modulationValue,
	debug		  
);

   i2s_v i2s_out(i_clk, l, r, gn[0], gn[1], gn[2] );
   
assign   gn[3] = i_clk;
 wire [11:0] pcm = pcm_trianglewave;
   wire [23:0] pcm_24s;
    assign pcm_24s[23] = pcm[11];
    assign pcm_24s[22:11] = pcm;
    assign pcm_24s[10:0] = 11'b0;

//MidiByteReader midiByteReader(i_clk, gp[0], byte_ready, byteValue, debug,waiting, signal, complete);

always @(posedge i_clk) begin
  o_led[0] <= note_on;

   l <= pcm_24s[23:8] * note_on;
   r <= pcm_24s[23:8]  * note_on;
 
   
  if (counter == 0)
    begin
       if (phase_state == 1'b1)
	 phase_state <= 1'b0;
       else
	 phase_state <= 1'b1;

    counter <= 5000;
    end   
   
  else 
    counter <= counter - 1'b1;

   
   
   
end // always @ (posedge i_clk)

endmodule

module trianglewave
#(
  parameter C_pcm_bits = 12 // how many bits for PCM output
)
(
  input 			 clk, // required to run PWM
  input [23:0] noteTicks,
  output signed [C_pcm_bits-1:0] pcm // 12-bit unsigned PCM output
);

    reg [32+C_pcm_bits-1:0] R_counter; // PWM counter register
    reg R_direction;
    
    always @(posedge clk)
    begin
      if(R_direction == 1'b1)
        R_counter <= R_counter + 1;
      else
        R_counter <= R_counter - 1;
    end

    always @(posedge clk)
    begin
      if( R_counter[noteTicks+C_pcm_bits-1:noteTicks] == ~{12'd1770} && R_direction == 1'b0)
        R_direction <= 1'b1; // from now on, count forwards
      if( R_counter[noteTicks+C_pcm_bits-1:noteTicks] == 12'd1770 && R_direction == 1'b1)
        R_direction <= 1'b0; // from now on, count backwards
    end
    
    assign pcm = R_counter[noteTicks+C_pcm_bits-1:noteTicks];
endmodule
