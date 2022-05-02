module MidiByteReader(
	input 		 clk_25,
	input 		 MIDI_RX,
	output reg 	 isByteAvailable = 0,
	output reg [7:0] byteValue = 0,
	output reg       debug = 0,		      
	output reg 	 waitingForSignal = 0,
	output reg 	 signalAvailable = 0,
	output reg 	 byteComplete = 0, 
);

localparam
  midiTicks                 = 12'd800,  // 25,000,000 / 31,250
  debounceTicks             = 12'd400,
  stateWaitingForSignal     = 8'd0,
  stateSignalAvailable      = 8'd1,
  stateByteComplete         = 8'd2;

  reg [7:0] midiState = stateWaitingForSignal;
  reg [7:0] bitNumber = 0;
  reg [11:0] midiCount = 0;
  reg [12:0] debounceCountDown = debounceTicks;

always @(posedge clk_25)
  begin
  case (midiState)
    stateWaitingForSignal:
      begin
        waitingForSignal<=1;
	signalAvailable<=0;
	byteComplete<=0;
        isByteAvailable <= 1'b0;
        if (MIDI_RX == 1'b0)
          begin
	    debounceCountDown <= debounceCountDown - 1'b1;
	    if (debounceCountDown == 12'b0)
	      begin
	        debounceCountDown <= debounceTicks;
		midiState <= stateSignalAvailable;
	        midiCount <= 1'b0;
		bitNumber <= 1'b0;
		byteValue <= 1'b0;
	      end
          end
	else
          debounceCountDown <= debounceTicks;
      end
    stateSignalAvailable:
      begin
        waitingForSignal<=0;
	signalAvailable<=1;
	byteComplete<=0;
	midiCount <= midiCount + 1'b1;
	      
        if (midiCount == midiTicks)
	  begin

	    midiCount <= 1'b0;
	    bitNumber <= bitNumber + 1'b1;
             debug <= MIDI_RX;
	
            if (MIDI_RX == 1'b1)
	      begin
	      byteValue <= byteValue | (1'b1 << bitNumber);
	    end
            
            if (bitNumber == 8'd7)
	      midiState <= stateByteComplete;					
	    end
        end
    stateByteComplete:
      begin
        waitingForSignal<=0;
	signalAvailable<=0;
	byteComplete<=1;
	midiCount <= midiCount + 1'b1;
			
        if (midiCount == midiTicks)
	  begin
	    isByteAvailable <= 1'b1;				
	    midiState <= stateWaitingForSignal;
	  end			
      end
  endcase
end

endmodule
