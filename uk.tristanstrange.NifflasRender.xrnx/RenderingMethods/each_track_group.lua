-- Render  every track not in a group as a separate sample
function render_each_track_group()
	local rs = renoise.song()

	-- confirm that this XRNS has been saved somewhere, if not show an error
	if rs.file_name == "" then
		renoise.app():show_error(
			"This song's track groups can not be rendered as it " ..
			"has not yet been saved.")

		return
	end

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

			local render_path = get_song_location() .. rs:track(i).name

			enqueue_render_track(i, render_options, render_path, function() 
				renoise.app():show_status(
					"Finished rendering track " .. rs:track(i).name ..  
					" to " .. render_path
				)
			end)
		end
	end
end
