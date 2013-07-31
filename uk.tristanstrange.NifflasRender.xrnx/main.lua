--[[============================================================================
Render Song as Loop

Written by Tristan Strange <tristan.strange@gmail.com> 
============================================================================]]--

-- render settings
local SAMPLE_RATE = 44100
local BIT_DEPTH = 16

-- render types
local render_type = { PATTERN = 1, TRACK = 2 }

-- keeps track of enqueud renders
local queued_renders = {}

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Returns a patterns estimated length in frames
local function pattern_length_in_frames(pattern)
	-- TODO should I be searching back through track for last BPM/LPB commands?

	local transport = renoise.song().transport
	
	local bps = transport.bpm / 60
	local len_beats = pattern.number_of_lines / transport.lpb
	local len_frames = len_beats / bps * SAMPLE_RATE

	return len_frames
end

-- Returns the path that the currently loaded song is located within including 
-- trailing slash, it assumes the song filename ends with .XRNS
local function get_song_location()
	local rs = renoise.song()

	local search_pattern

	if os.platform() == "WINDOWS" then
		search_pattern = "\\[^\\]*%.xrns" -- not tested!!!
	else
		search_pattern = "/[^/]*%.xrns"
	end

	local song_path_end_i = string.find(string.lower(rs.file_name), search_pattern)

	return string.sub(rs.file_name, 1, song_path_end_i)
end

-- Returns the the file name of the current song excluding it's path and  
-- extension
local function get_song_file_name()
	local rs = renoise.song()

	local search_pattern

	if os.platform == "WINDOWS" then
		search_pattern = "\\[^\\]*%.xrns" -- not tested!!!
	else
		search_pattern = "/[^/]*%.xrns"
	end

	local file_name_i = string.find(string.lower(rs.file_name), search_pattern) + 1
	local extension_i = string.find(string.lower(rs.file_name), ".xrns") - 1

	return string.sub(rs.file_name, file_name_i, extension_i)
end

-- Returns the maximum absolute value in a table
local function abs_max_of_table(t)
	local abs_max = 0

	for i = 1, #t do
		local x = math.abs(t[i])
		
		if x > abs_max then 
			abs_max = x
		end
	end

	return abs_max
end

-- Returns sequencer track mute states
local function get_sequencer_track_solo_states()
	local rs = renoise.song()
	
	local solo_states = {}

	for i = 1, rs.sequencer_track_count do
		solo_states[i] = rs:track(i).solo_state
	end

	return solo_states
end

-- Set sequencer track solo states
local function set_sequencer_track_solo_states(solo_states)
	local rs = renoise.song()

	for i = 1, rs.sequencer_track_count do
		rs:track(i).solo_state = solo_states[i]
	end
end

-- Make's sure only one top level track is solo'd
local function set_one_track_solo(track_i)
	local rs = renoise.song()

	for i = 1, rs.sequencer_track_count do
		if not rs:track(i).group_parent and i ~= track_i then
			rs:track(i).solo_state = false
		elseif i == track_i then
			rs:track(i).solo_state = true
		end
	end
end

--------------------------------------------------------------------------------
-- Methods for handling queued renders
--------------------------------------------------------------------------------

-- Performs a queued render
-- called by renoise's idle handler, required as we can only perform one render 
-- at a time and have to poll to check if its finished
local function perform_queued_renders()
	local rs = renoise.song()
	
	-- if we aren't rendering and we have stuff left to render
	if not rs.rendering and #queued_renders > 0 then
		-- get details of next render to perform
		local render = queued_renders[1]
	
		if render.render_type == render_type.PATTERN then
			-- perform render
			rs:render(render.options, render.path, render.call_back)
		elseif render.render_type == render_type.TRACK then
			-- solo the track to render
			local solo_states = get_sequencer_track_solo_states()
			set_one_track_solo(render.track)

			rs:render(render.options, render.path, function()
				render.call_back()

				-- undo solo'ing
				set_sequencer_track_solo_states(solo_states)
			end)
		end

		-- remove enqueud render request
		table.remove(queued_renders, 1)
	end
end

-- register perform_queued_renders to be executed when renoise is idle
if not renoise.tool().app_idle_observable:has_notifier(perform_queued_renders) then
	renoise.tool().app_idle_observable:add_notifier(perform_queued_renders)
end

-- Enqueues a request to render a particular pattern
-- - options - rendering options as passed to renoise.song():render
-- - path - path of file to render to
-- - call_back - function to perform after render
local function enqueue_render_patterns(options, path, call_back)
	table.insert(queued_renders, { 
		options = options, 
		path = path, 
		call_back = call_back,
		render_type = render_type.PATTERN
	})
end

-- Enqueues a request to render a particular track
-- - track_i - index of track to render
-- - options - rendering options as passed to renoise.song():render
-- - path - path of file to render to
-- - call_back - function to perform after render
local function enqueue_render_track(track_i, options, path, call_back)
	table.insert(queued_renders, { 
		options = options, 
		path = path, 
		call_back = call_back,
		render_type = render_type.TRACK,
		track = track_i
	})
end

--------------------------------------------------------------------------------
-- Main methods
--------------------------------------------------------------------------------

-- Load a sample and produces an instrument containing a looped version of it
--
-- If the loop clips due to merging the volume of the sample is normlised
-- A 10 sample fade is appled to either end of the sample to prevent clicking
-- Returns an instrument containing a looped version of the sample
-- - sample_path - file name of sample to load
-- - tail_len - length of samples tail in frames
local function make_looped_sample_inst(sample_path, tail_len)
	local rs = renoise.song()

	-- Create an instrument to perform work in
	local inst = rs:insert_instrument_at(#rs.instruments + 1)
	inst.name = "Looped Song"

	-- Load sample
	inst.samples[1].sample_buffer:load_from(sample_path)
	local src_sample = inst.samples[1].sample_buffer

	-- Calculate length of sample after tail is merged
	local looped_sample_len = src_sample.number_of_frames - tail_len
	
	-- merge start and end of sample
	renoise.app():show_status("Creating looped sample from " .. sample_path)

	local merge = {}
	for c = 1, src_sample.number_of_channels do
		merge[c] = {}
		for f = 1, tail_len do
			merge[c][f] = src_sample:sample_data(c, f) 
				+ src_sample:sample_data(c, f + src_sample.number_of_frames - tail_len)
		end
	end
	
	-- find max amplitude in merged section
	local max_amp = math.max(abs_max_of_table(merge[1]), abs_max_of_table(merge[2]))

	-- if mixed section clips scale the whole samples amplitude down
	local amp_scaling = 1 
	if max_amp > 1 then
		amp_scaling = 1 / max_amp
	end
	
	-- create new sample buffer to write merged sample in to
	renoise.app():show_status("Writing looped sample to buffer")

	inst:insert_sample_at(2)
	inst.samples[2].sample_buffer:create_sample_data(
		SAMPLE_RATE, BIT_DEPTH, src_sample.number_of_channels, looped_sample_len
	)

	local looped_sample = inst.samples[2].sample_buffer

	-- write merged sample
	looped_sample:prepare_sample_data_changes()
	for c = 1, src_sample.number_of_channels do
		for f = 1, looped_sample_len do
			-- if we still have a merged bit to copy
			if f < tail_len then -- copy the merged bit
				-- if were right at the start of the loop apply a little fade in
				if f < 10 then
					looped_sample:set_sample_data(c, f, merge[c][f] * amp_scaling * 0.1 * f)
				else
					looped_sample:set_sample_data(c, f, merge[c][f] * amp_scaling)
				end
			else -- otherwise just take the samples as is
				-- if we're right atthe end of the loop apply a little fade out 
				if looped_sample_len - f < 10 then	
					looped_sample:set_sample_data(c, f, 
						src_sample:sample_data(c, f) * amp_scaling * (looped_sample_len - f) * 0.1)
				else
					looped_sample:set_sample_data(c, f, src_sample:sample_data(c, f) * amp_scaling)
				end
			end
		end
	end
	looped_sample:finalize_sample_data_changes()

	-- clean up origanal sample
	inst:delete_sample_at(1)

	-- map our looped one
	inst:insert_sample_mapping(1, 1)

	-- warn user if we scaled amplitude of sample
	if amp_scaling < 1 then
		renoise.app():show_warning(
			"Clipping occured whilst rendering this sample as a loop. Its " .. 
			"amplitude was scaled by" .. amp_scaling .. " in order to compensate.")
	end

	renoise.app():show_status("Finished creating looped verion of sample")

	return inst
end

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

-- Render  every track nt in a group as a separate sample
local function render_each_track_group()
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
					"Finished rendering track " .. rs:track(i).name ..  " to " .. save_path
				)
			end)
		end
	end
end

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
--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Nifflas Render:Song...",
  invoke = render_song 
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Nifflas Render:Song as loop...",
  invoke = render_song_as_loop 
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Nifflas Render:Labelled patterns...",
  invoke = render_each_pattern 
}

renoise.tool():add_menu_entry {
	name = "Main Menu:Tools:Nifflas Render:Labelled pattern pairs as loops...",
	invoke = render_pattern_pairs_as_loop 
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Nifflas Render:Ungrouped tracks...",
	invoke = render_each_track_group 
}

renoise.tool():add_menu_entry {
	name = "Main Menu:Tools:Nifflas Render:Ungrouped tracks as loops...",
	invoke = render_each_track_group_as_loop 
}
