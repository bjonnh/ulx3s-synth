SOURCE := top.v


# vhd2vl  in.vhd out.v


ulx3s.bit: ulx3s_out.config
	ecppack ulx3s_out.config ulx3s.bit

ulx3s_out.config: midisynth.json
	nextpnr-ecp5 --85k --json midisynth.json \
		--lpf ulx3s_v20.lpf \
		--textcfg ulx3s_out.config

MidiNoteNumberToSampleTicks.v: NoteSampleTicks.py
	python NoteSampleTicks.py > MidiNoteNumberToSampleTicks.v

midisynth.json: midisynth.ys top.v MidiByteReader.v MidiNoteNumberToSampleTicks.v MidiProcessor.v i2s.v
	yosys midisynth.ys

prog: ulx3s.bit
	fujprog ulx3s.bit

