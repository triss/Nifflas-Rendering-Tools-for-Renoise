--[[============================================================================
Nifflas Rendering Tools

Written by Tristan Strange <tristan.strange@gmail.com> 
============================================================================]]--

-- render settings
SAMPLE_RATE = 44100
BIT_DEPTH = 16

-- render types

require("Helper")
require("RenderQueue")
require("RenderingMethods")

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
