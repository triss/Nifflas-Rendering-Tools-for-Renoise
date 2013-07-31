-- Render tracks/groups as a loop using last pattern as loop decay
local function render_each_track_group_as_loop ()
	local rs = renoise.song()
	
	-- confirm that this XRNS has been saved somewhere, if not show an error
	if rs.file_name == "" then
		renoise.app():show_error(
			"This song's ungrouped tracks can not be rendered as loops as it " ..
			"has not yet been saved anywhere."
		)

		return
	end

	-- for every track that's not in a group
	for i = 1, rs.sequencer_track_count do
		if not rs:track(i).group_parent then
			-- set end point for render			
			local end_pos = renoise.SongPos()
			end_pos.sequence = #rs.sequencer.pattern_sequence
			end_pos.line = rs:pattern(#rs.sequencer.pattern_sequence).number_of_lines

			-- set up rendering options
			local render_options = {
				start_pos = renoise.SongPos(), end_pos = end_pos,
				sample_rate = SAMPLE_RATE, bit_depth = BIT_DEPTH 
			}

			-- Temporary render location for unlooped samples
			local tmp_render_path = os.tmpname('.wav')
			
			-- Location for saveing looped track loops
			local save_path = get_song_location() .. rs:track(i).name .. '.wav'

			-- enquue track rendering
			enqueue_render_track(i, render_options, tmp_render_path, function() 
				-- calculate length of tail pattern
				local tail_patt = rs:pattern(#rs.sequencer.pattern_sequence)
				local tail_len = pattern_length_in_frames(tail_patt)

				-- create an instrument containing looped version of the song
				local inst = make_looped_sample_inst(tmp_render_path, tail_len)
				
				-- save the looped sample
				inst.samples[1].sample_buffer:save_as(save_path, 'wav')

				-- clean up the instrument
				rs:delete_instrument_at(#rs.instruments)

				-- delete temporary render file
				os.remove(tmp_render_path)
			end)
		end
	end
end

