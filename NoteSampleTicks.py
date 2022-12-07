import math

FREQUENCY_MHZ = 25.0
SAMPLE_SIZE = 1024
FREQUENCY_HZ = FREQUENCY_MHZ * 1_000_000

print("""
module MidiNoteNumberToSampleTicks(
	input [7:0] midiNoteNumber,
	output reg [23:0] noteSampleTicks
);

always @(midiNoteNumber)
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
#
# using System;
# using System.Collections.Generic;
# using System.IO;
#
# namespace NoteSampleTicks
# {
#     public class Program
#     {
#         public static void Main(string[] args)
#         {
#             var lines = new List<string>();
#
#             for (var i = 0; i < 128; i++)
#             {
#                 var frequency = 440 / 32d * Math.Pow(2, (i - 9) / 12d);
#                 var ticks = 50000000 / frequency / 256;
#                 var line = $"8'h{i:X2}: noteSampleTicks <= 24'd{(int)ticks};  // {i}";
#                 lines.Add(line);
#                 Console.WriteLine(line);
#             }
#
#             File.WriteAllLines("output.txt", lines);
#             Console.WriteLine("Done.");
#
#             Console.ReadLine();
#         }
#     }
# }
