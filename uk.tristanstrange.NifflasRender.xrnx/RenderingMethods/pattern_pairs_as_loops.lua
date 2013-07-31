-- Render each consecutive pair of patterns as loop and save as a sample with
-- the name of the first pattern
local function render_pattern_pairs_as_loop()
	local rs = renoise.song()
	
	-- show an error and return if this XRNS has not been saved anywhere yet
	if rs.file_name == "" then
		renoise.app():show_error(
			"This song's pattern pairs can not be rendered as loops as it " ..
			"has not yet been saved."
		)

		return
	end

	-- warn if we don't have an even number of patterns to render
	if #rs.sequencer.pattern_sequence % 2 ~= 0 then
		renoise.app():show_warning(
			"This song's last pattern will not be rendered as it does not " .. 
			"contain a pattern to follow it and act as loop tail."
		)
	end

	for i = 1, #rs.sequencer.pattern_sequence - 1, 2 do
		local pattern = rs:pattern(rs.sequencer.pattern_sequence[i])
		local tail_patt = rs:pattern(rs.sequencer.pattern_sequence[i+1])

		-- only render if pattern has a name
		if pattern.name ~= "" then
			-- set start and ends for render
			local start_pos = renoise.SongPos()
			local end_pos = renoise.SongPos()
			start_pos.sequence = i 
			end_pos.sequence = i + 1 -- note patern after i!
			end_pos.line = tail_patt.number_of_lines

			-- get temporary location to store render in
			local tmp_render_path = os.tmpname("wav")

			-- construct path name for looped render
			local save_path = get_song_location() .. pattern.name .. ".wav"
			
			local render_options = {
				start_pos = start_pos, end_pos = end_pos, 
				sample_rate = SAMPLE_RATE, bit_depth = BIT_DEPTH 
			}

			-- render the pattern
			enqueue_render_patterns(render_options, tmp_render_path, function() 
				-- get length of loop tail/decay pattern
				local tail_len = pattern_length_in_frames(tail_patt)

				-- create an instrument containing looped version of the song
				local inst = make_looped_sample_inst(tmp_render_path, tail_len)
				
				-- save the looped sample
				inst.samples[1].sample_buffer:save_as(save_path, "wav")

				-- clean up the instrument
				rs:delete_instrument_at(#rs.instruments)

				-- delete temporary render file
				os.remove(tmp_render_path)

				renoise.app():show_status(
					"Finished rendering pattern pairs " .. pattern.name ..  " to " .. save_path
				)
			end)
		end
	end
end
