-- Renders the song and saves it as a .wav file with the same name as the .xrns
local function render_song()
	local rs = renoise.song()

	-- confirm that this XRNS has been saved somewhere, if not show an error
	if rs.file_name == "" then
		renoise.app():show_error(
			"This song can not be rendered by this tool as it has not yet been saved.")

		return
	end

	-- set up path to save song at
	local render_path = get_song_location() .. get_song_file_name()

	renoise.app():show_status("Rendering song to " .. render_path)

	-- find end of song
	local end_pos = renoise.SongPos()
	end_pos.sequence = #rs.sequencer.pattern_sequence
	end_pos.line = rs:pattern(rs.sequencer:pattern(end_pos.sequence)).number_of_lines
	
	-- set up rendering options
	local render_options = {	
		sample_rate = SAMPLE_RATE, bit_depth = BIT_DEPTH,
		start_pos = renoise.SongPos(), end_pos = end_pos, 
	} 

	-- render the song
	enqueue_render_patterns(render_options, render_path, function()
		renoise.app():show_status("Finished rendering song to " .. render_path)
	end)
end
