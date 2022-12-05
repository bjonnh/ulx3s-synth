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

midisynth.json: midisynth.ys top.v clock.v MidiByteReader.v MidiNoteNumberToSampleTicks.v MidiProcessor.v i2s.v hdl/sv/ecp5pll.sv sine.mem
	yosys midisynth.ys

sine.mem: gen_sine.py
	python gen_sine.py

prog: ulx3s.bit
	fujprog ulx3s.bit

