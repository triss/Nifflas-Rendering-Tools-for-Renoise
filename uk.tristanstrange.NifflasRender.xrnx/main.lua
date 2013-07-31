--[[============================================================================
Nifflas Rendering Tools

Written by Tristan Strange <tristan.strange@gmail.com> 
============================================================================]]--

-- render settings
SAMPLE_RATE = 44100
BIT_DEPTH = 16

-- song render mode
song_render_mode = nil

require "Helper"
require "RenderQueue"
require "make_looped_sample_inst"
require "SongRenderSettings"

require "RenderingMethods/each_pattern"
require "RenderingMethods/each_track_group_as_loop"
require "RenderingMethods/each_track_group"
require "RenderingMethods/pattern_pairs_as_loops"
require "RenderingMethods/song_as_loop"
require "RenderingMethods/song"

require "GUI"

-- execute a particular rendering method - indedxed by number for easy use with
-- popups.
function perform_rendering_method(render_mode)
	local render_methods = { 
		render_song, render_song_as_loop, render_each_pattern,
		render_pattern_pairs_as_loop, render_each_track_group,
		render_pattern_pairs_as_loop
	}

	song_render_mode = render_mode

	store_render_settings()

	render_methods[song_render_mode]()
end

function perform_default_render()
	if song_render_mode then
		perform_rendering_method(song_render_mode)
	else
		show_choose_rendering_method_dialog()
	end
end

--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
	name = "Main Menu:Tools:Nifflas Render...",
	invoke = perform_default_render
}

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
