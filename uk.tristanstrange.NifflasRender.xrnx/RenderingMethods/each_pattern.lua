-- Render every named pattern as a sample with the same name as the pattern
local function render_each_pattern()
	local rs = renoise.song()
	
	-- confirm that this XRNS has been saved somewhere, if not show an error
	if rs.file_name == ""  then
		renoise.app():show_error(
			"This song can not have each of it's patterns rendered as it has not " ..
			"yet been saved.")

		return
	end

	for i = 1, #rs.sequencer.pattern_sequence do
		local pattern = rs:pattern(rs.sequencer.pattern_sequence[i])

		-- only render pattern if its been named in the sequencer
		if pattern.name ~= "" then
			-- set start and end positions for render
			local start_pos = renoise.SongPos()
			local end_pos = renoise.SongPos()
			start_pos.sequence = i
			end_pos.sequence = i
			end_pos.line = pattern.number_of_lines

			-- construct path name for render
			local render_path = get_song_location() .. pattern.name
			
			local render_options = {
				start_pos = start_pos, end_pos = end_pos, 
				sample_rate = SAMPLE_RATE, bit_depth = BIT_DEPTH 
			}

			-- render the pattern
			enqueue_render_patterns(render_options, render_path, function() 
				renoise.app():show_status(
					"Finished rendering " .. pattern.name ..  " to " .. render_path
				)
			end)
		end
	end
end
