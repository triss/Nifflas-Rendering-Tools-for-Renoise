--------------------------------------------------------------------------------
-- Methods for handling queued renders
--------------------------------------------------------------------------------

-- used to indicate how a  requested render should be carried out
local render_type = { PATTERN = 1, TRACK = 2 }

-- keeps track of enqueud renders
queued_renders = {}

-- Performs a queued render
-- called by renoise's idle handler, required as we can only perform one render 
-- at a time and have to poll to check if its finished
function perform_queued_renders()
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
function enqueue_render_patterns(options, path, call_back)
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
function enqueue_render_track(track_i, options, path, call_back)
	table.insert(queued_renders, { 
		options = options, 
		path = path, 
		call_back = call_back,
		render_type = render_type.TRACK,
		track = track_i
	})
end
