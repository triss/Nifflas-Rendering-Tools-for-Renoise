--------------------------------------------------------------------------------
-- Miscellaneous helper functions
--------------------------------------------------------------------------------

-- Returns a patterns estimated length in frames
function pattern_length_in_frames(pattern)
	-- TODO should I be searching back through track for last BPM/LPB commands?

	local transport = renoise.song().transport
	
	local bps = transport.bpm / 60
	local len_beats = pattern.number_of_lines / transport.lpb
	local len_frames = len_beats / bps * SAMPLE_RATE

	return len_frames
end

-- Returns the path that the currently loaded song is located within including 
-- trailing slash, it assumes the song filename ends with .XRNS
function get_song_location()
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
function get_song_file_name()
	local rs = renoise.song()

	local search_pattern

	if os.platform() == "WINDOWS" then
		search_pattern = "\\[^\\]*%.xrns" -- not tested!!!
	else
		search_pattern = "/[^/]*%.xrns"
	end

	local file_name_i = string.find(string.lower(rs.file_name), search_pattern) + 1
	local extension_i = string.find(string.lower(rs.file_name), ".xrns") - 1

	return string.sub(rs.file_name, file_name_i, extension_i)
end

-- Returns the maximum absolute value in a table
function abs_max_of_table(t)
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
function get_sequencer_track_solo_states()
	local rs = renoise.song()
	
	local solo_states = {}

	for i = 1, rs.sequencer_track_count do
		solo_states[i] = rs:track(i).solo_state
	end

	return solo_states
end

-- Set sequencer track solo states
function set_sequencer_track_solo_states(solo_states)
	local rs = renoise.song()

	for i = 1, rs.sequencer_track_count do
		rs:track(i).solo_state = solo_states[i]
	end
end

-- Make's sure only one top level track is solo'd
function set_one_track_solo(track_i)
	local rs = renoise.song()

	for i = 1, rs.sequencer_track_count do
		if not rs:track(i).group_parent and i ~= track_i then
			rs:track(i).solo_state = false
		elseif i == track_i then
			rs:track(i).solo_state = true
		end
	end
end
