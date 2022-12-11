import math
from config import FREQUENCY_MHZ, SAMPLE_SIZE

FREQUENCY_HZ = FREQUENCY_MHZ * 1_000_000

print("""
module MidiNoteNumberToSampleTicks(
    input wire mclk,
    input [7:0] midiNoteNumber,
    output reg [23:0] noteSampleTicks
);

always @(posedge mclk)
begin
	case (midiNoteNumber)
""")

for i in range(0, 128):
    freq = 440 / 32.0 * math.pow(2, (i - 9) / 12)
    ticks = FREQUENCY_HZ / freq / SAMPLE_SIZE
    print(f"\t\t8'h{i:02x}: noteSampleTicks <= 24'd{int(ticks)};  // {i}")

print("""
		default: noteSampleTicks <= 0;
	endcase
end

endmodule
""")
