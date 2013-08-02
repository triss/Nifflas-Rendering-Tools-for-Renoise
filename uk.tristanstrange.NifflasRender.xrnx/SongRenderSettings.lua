local RENDER_SETTINGS_INST_NAME = "NO ACCESS: Nifflas Render Data"

--returns a sample slot to store settings in 
function get_render_settings_sample()
	for i, instrument in ripairs (renoise.song ().instruments) do
		if instrument.name == RENDER_SETTINGS_INST_NAME then
			return instrument.samples[1]
		end
	end

	return nil
end

function create_render_settings()
	local index = #renoise.song().instruments + 1
	renoise.song():insert_instrument_at (index)
	local instrument = renoise.song():instrument(index)
	instrument.name = RENDER_SETTINGS_INST_NAME

	return instrument:sample(1)
end

-- recover rendering settings from sample slot
function recover_render_settings()	
	local recoverd_settings = get_render_settings_sample().name

	if recoverd_settings then
		song_render_mode = recoverd_settings
	end
end

-- store rendering settings in sample slot
function store_render_settings()
	get_render_settings_sample().name = tostring(song_render_mode)
end

renoise.tool().app_new_document_observable:add_notifier(recover_render_settings)
