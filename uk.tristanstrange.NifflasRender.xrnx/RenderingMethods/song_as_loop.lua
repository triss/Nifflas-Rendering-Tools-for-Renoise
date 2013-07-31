-- Renders the song as a loop and outputs file with the same name as and in the
-- same folder as the song's XRNS file
local function render_song_as_loop()
	local rs = renoise.song()

	-- confirm that this XRNS has been saved somewhere, if not show an error
	if rs.file_name == "" then 
		renoise.app():show_error(
			"This song can not be rendered as a loop as it has not yet been saved.")

		return
	end

	-- get temporary location to store render in
	local tmp_render_path = os.tmpname("wav")

	-- find end position
	local end_pos = renoise.SongPos()
	end_pos.sequence = #rs.sequencer.pattern_sequence
	end_pos.line = rs:pattern(rs.sequencer:pattern(end_pos.sequence)).number_of_lines
	
	-- Find length of the tail pattern
	local tail_patt = rs:pattern(rs.sequencer:pattern(end_pos.sequence))
	local tail_len = pattern_length_in_frames(tail_patt)

	-- set up rendering options
	local render_options = {	
		sample_rate = SAMPLE_RATE, bit_depth = BIT_DEPTH,
		start_pos = renoise.SongPos(), end_pos = end_pos, } 

	-- render the song
	enqueue_render_patterns(render_options, tmp_render_path, function()
		-- create an instrument containing looped version of the song
		local inst = make_looped_sample_inst(tmp_render_path, tail_len)
		
		-- save the looped sample
		inst.samples[1].sample_buffer:save_as(
			get_song_location() .. get_song_file_name() .. ".wav", "wav"
		) 

		-- clean up the instrument
		rs:delete_instrument_at(#rs.instruments)

		-- delete temporary render file
		os.remove(tmp_render_path)

		renoise.app():show_status("Finished rendering song as loop.")
	end)
end
