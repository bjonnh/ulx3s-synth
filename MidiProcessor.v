module MidiProcessor(
	input			 clk,
	input			 MIDI_RX,
	output reg		 isNoteOn,
	output reg [7:0] note,
	output reg [7:0] controllerNumber,
	output reg [7:0] controllerValue,
	output reg		 controllerReady
);

reg [3:0] status = 0;
reg [3:0] channel = 0;
reg [7:0] dataByte0 = 0;
reg [7:0] dataByte1 = 0;
reg [7:0] dataByte2 = 0;
reg [7:0] dataBytesReceivedCount = 0;
reg isDataByteAvailable = 0;
reg [7:0] note;
reg	controllerReady = 0;
reg controllerNumber = 0;
reg controllerValue = 0;


wire isByteAvailable;
wire [7:0] byteValue;

MidiByteReader midiByteReader(clk, MIDI_RX, isByteAvailable, byteValue);


always @(posedge clk)
begin
	if (isByteAvailable == 1'b1)
		begin
			if (byteValue < 8'h80)  // Data byte
				begin
					case (dataBytesReceivedCount)
						0:
							begin
								dataByte0 <= byteValue;
								dataBytesReceivedCount <= 8'd1;
								isDataByteAvailable <= 1'b1;
							end
						1:
							begin
								dataByte1 <= byteValue;
								dataBytesReceivedCount <= 8'd2;
								isDataByteAvailable <= 1'b1;
							end
						2:
							begin
								dataByte2 <= byteValue;
								dataBytesReceivedCount <= 8'd3;
								isDataByteAvailable <= 1'b1;
							end
					endcase
				end
			else  // Status byte
				begin
					status <= byteValue[7:4];
					channel <= byteValue[3:0];
					dataBytesReceivedCount <= 0;
				end
		end
	else if (isDataByteAvailable == 1'b1)
		begin
			isDataByteAvailable <= 1'b0;
		
			case (status)
				4'h8:  // Note Off
					if (dataBytesReceivedCount == 2)
					    begin
								begin
									dataBytesReceivedCount <= 0;
									isNoteOn <= 1'b0;
								end
						end
				4'h9:  // Note On
					case (dataBytesReceivedCount)
						1:
							note = dataByte0;
						2:
							begin
								dataBytesReceivedCount <= 0;

								if (dataByte1 == 0)
									begin
										// Zero velocity is like Note Off
										isNoteOn <= 1'b0;
									end
								else
									begin
										isNoteOn <= 1'b1;
									end
							end
					endcase
				4'hB:  // Controller Change
					case (dataBytesReceivedCount)
						1: begin
						   controllerReady <= 0;
						   controllerNumber <= dataByte0;
						end
						2:
							begin
							   dataBytesReceivedCount <= 0;
							   controllerValue <= dataByte1;
							   //controllerReady <= 1;
							end
					endcase
			endcase
		end // if (isDataByteAvailable == 1'b1)
end

endmodule
