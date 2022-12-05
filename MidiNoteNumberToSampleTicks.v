
module MidiNoteNumberToSampleTicks(
	input [7:0] midiNoteNumber,
	output reg [23:0] noteSampleTicks
);

always @(midiNoteNumber)
begin
	case (midiNoteNumber)

		8'h00: noteSampleTicks <= 24'd2986;  // 0
		8'h01: noteSampleTicks <= 24'd2818;  // 1
		8'h02: noteSampleTicks <= 24'd2660;  // 2
		8'h03: noteSampleTicks <= 24'd2511;  // 3
		8'h04: noteSampleTicks <= 24'd2370;  // 4
		8'h05: noteSampleTicks <= 24'd2237;  // 5
		8'h06: noteSampleTicks <= 24'd2111;  // 6
		8'h07: noteSampleTicks <= 24'd1993;  // 7
		8'h08: noteSampleTicks <= 24'd1881;  // 8
		8'h09: noteSampleTicks <= 24'd1775;  // 9
		8'h0a: noteSampleTicks <= 24'd1675;  // 10
		8'h0b: noteSampleTicks <= 24'd1581;  // 11
		8'h0c: noteSampleTicks <= 24'd1493;  // 12
		8'h0d: noteSampleTicks <= 24'd1409;  // 13
		8'h0e: noteSampleTicks <= 24'd1330;  // 14
		8'h0f: noteSampleTicks <= 24'd1255;  // 15
		8'h10: noteSampleTicks <= 24'd1185;  // 16
		8'h11: noteSampleTicks <= 24'd1118;  // 17
		8'h12: noteSampleTicks <= 24'd1055;  // 18
		8'h13: noteSampleTicks <= 24'd996;  // 19
		8'h14: noteSampleTicks <= 24'd940;  // 20
		8'h15: noteSampleTicks <= 24'd887;  // 21
		8'h16: noteSampleTicks <= 24'd837;  // 22
		8'h17: noteSampleTicks <= 24'd790;  // 23
		8'h18: noteSampleTicks <= 24'd746;  // 24
		8'h19: noteSampleTicks <= 24'd704;  // 25
		8'h1a: noteSampleTicks <= 24'd665;  // 26
		8'h1b: noteSampleTicks <= 24'd627;  // 27
		8'h1c: noteSampleTicks <= 24'd592;  // 28
		8'h1d: noteSampleTicks <= 24'd559;  // 29
		8'h1e: noteSampleTicks <= 24'd527;  // 30
		8'h1f: noteSampleTicks <= 24'd498;  // 31
		8'h20: noteSampleTicks <= 24'd470;  // 32
		8'h21: noteSampleTicks <= 24'd443;  // 33
		8'h22: noteSampleTicks <= 24'd418;  // 34
		8'h23: noteSampleTicks <= 24'd395;  // 35
		8'h24: noteSampleTicks <= 24'd373;  // 36
		8'h25: noteSampleTicks <= 24'd352;  // 37
		8'h26: noteSampleTicks <= 24'd332;  // 38
		8'h27: noteSampleTicks <= 24'd313;  // 39
		8'h28: noteSampleTicks <= 24'd296;  // 40
		8'h29: noteSampleTicks <= 24'd279;  // 41
		8'h2a: noteSampleTicks <= 24'd263;  // 42
		8'h2b: noteSampleTicks <= 24'd249;  // 43
		8'h2c: noteSampleTicks <= 24'd235;  // 44
		8'h2d: noteSampleTicks <= 24'd221;  // 45
		8'h2e: noteSampleTicks <= 24'd209;  // 46
		8'h2f: noteSampleTicks <= 24'd197;  // 47
		8'h30: noteSampleTicks <= 24'd186;  // 48
		8'h31: noteSampleTicks <= 24'd176;  // 49
		8'h32: noteSampleTicks <= 24'd166;  // 50
		8'h33: noteSampleTicks <= 24'd156;  // 51
		8'h34: noteSampleTicks <= 24'd148;  // 52
		8'h35: noteSampleTicks <= 24'd139;  // 53
		8'h36: noteSampleTicks <= 24'd131;  // 54
		8'h37: noteSampleTicks <= 24'd124;  // 55
		8'h38: noteSampleTicks <= 24'd117;  // 56
		8'h39: noteSampleTicks <= 24'd110;  // 57
		8'h3a: noteSampleTicks <= 24'd104;  // 58
		8'h3b: noteSampleTicks <= 24'd98;  // 59
		8'h3c: noteSampleTicks <= 24'd93;  // 60
		8'h3d: noteSampleTicks <= 24'd88;  // 61
		8'h3e: noteSampleTicks <= 24'd83;  // 62
		8'h3f: noteSampleTicks <= 24'd78;  // 63
		8'h40: noteSampleTicks <= 24'd74;  // 64
		8'h41: noteSampleTicks <= 24'd69;  // 65
		8'h42: noteSampleTicks <= 24'd65;  // 66
		8'h43: noteSampleTicks <= 24'd62;  // 67
		8'h44: noteSampleTicks <= 24'd58;  // 68
		8'h45: noteSampleTicks <= 24'd55;  // 69
		8'h46: noteSampleTicks <= 24'd52;  // 70
		8'h47: noteSampleTicks <= 24'd49;  // 71
		8'h48: noteSampleTicks <= 24'd46;  // 72
		8'h49: noteSampleTicks <= 24'd44;  // 73
		8'h4a: noteSampleTicks <= 24'd41;  // 74
		8'h4b: noteSampleTicks <= 24'd39;  // 75
		8'h4c: noteSampleTicks <= 24'd37;  // 76
		8'h4d: noteSampleTicks <= 24'd34;  // 77
		8'h4e: noteSampleTicks <= 24'd32;  // 78
		8'h4f: noteSampleTicks <= 24'd31;  // 79
		8'h50: noteSampleTicks <= 24'd29;  // 80
		8'h51: noteSampleTicks <= 24'd27;  // 81
		8'h52: noteSampleTicks <= 24'd26;  // 82
		8'h53: noteSampleTicks <= 24'd24;  // 83
		8'h54: noteSampleTicks <= 24'd23;  // 84
		8'h55: noteSampleTicks <= 24'd22;  // 85
		8'h56: noteSampleTicks <= 24'd20;  // 86
		8'h57: noteSampleTicks <= 24'd19;  // 87
		8'h58: noteSampleTicks <= 24'd18;  // 88
		8'h59: noteSampleTicks <= 24'd17;  // 89
		8'h5a: noteSampleTicks <= 24'd16;  // 90
		8'h5b: noteSampleTicks <= 24'd15;  // 91
		8'h5c: noteSampleTicks <= 24'd14;  // 92
		8'h5d: noteSampleTicks <= 24'd13;  // 93
		8'h5e: noteSampleTicks <= 24'd13;  // 94
		8'h5f: noteSampleTicks <= 24'd12;  // 95
		8'h60: noteSampleTicks <= 24'd11;  // 96
		8'h61: noteSampleTicks <= 24'd11;  // 97
		8'h62: noteSampleTicks <= 24'd10;  // 98
		8'h63: noteSampleTicks <= 24'd9;  // 99
		8'h64: noteSampleTicks <= 24'd9;  // 100
		8'h65: noteSampleTicks <= 24'd8;  // 101
		8'h66: noteSampleTicks <= 24'd8;  // 102
		8'h67: noteSampleTicks <= 24'd7;  // 103
		8'h68: noteSampleTicks <= 24'd7;  // 104
		8'h69: noteSampleTicks <= 24'd6;  // 105
		8'h6a: noteSampleTicks <= 24'd6;  // 106
		8'h6b: noteSampleTicks <= 24'd6;  // 107
		8'h6c: noteSampleTicks <= 24'd5;  // 108
		8'h6d: noteSampleTicks <= 24'd5;  // 109
		8'h6e: noteSampleTicks <= 24'd5;  // 110
		8'h6f: noteSampleTicks <= 24'd4;  // 111
		8'h70: noteSampleTicks <= 24'd4;  // 112
		8'h71: noteSampleTicks <= 24'd4;  // 113
		8'h72: noteSampleTicks <= 24'd4;  // 114
		8'h73: noteSampleTicks <= 24'd3;  // 115
		8'h74: noteSampleTicks <= 24'd3;  // 116
		8'h75: noteSampleTicks <= 24'd3;  // 117
		8'h76: noteSampleTicks <= 24'd3;  // 118
		8'h77: noteSampleTicks <= 24'd3;  // 119
		8'h78: noteSampleTicks <= 24'd2;  // 120
		8'h79: noteSampleTicks <= 24'd2;  // 121
		8'h7a: noteSampleTicks <= 24'd2;  // 122
		8'h7b: noteSampleTicks <= 24'd2;  // 123
		8'h7c: noteSampleTicks <= 24'd2;  // 124
		8'h7d: noteSampleTicks <= 24'd2;  // 125
		8'h7e: noteSampleTicks <= 24'd2;  // 126
		8'h7f: noteSampleTicks <= 24'd1;  // 127

		default: noteSampleTicks <= 0;
	endcase
end

endmodule

