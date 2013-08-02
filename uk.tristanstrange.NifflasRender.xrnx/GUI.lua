local rendering_method_dialog = nil

function show_choose_rendering_method_dialog()
  local vb = renoise.ViewBuilder()
	
	if rendering_method_dialog and rendering_method_dialog.visible then
		rendering_method_dialog:show()
	end

  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

  local content = vb:column {
		margin = DEFAULT_MARGIN,
		vb:text { text = "Select a rendering mode for this song:", width = 200 },
		vb:popup { 
			id = "rendering_mode", width = 200,
			items = {
				"Render song", "Render song as loop", "Render labelled patterns",
				"Render labelled pattern pairs as loops", "Render ungrouped tracks",
				"Ungrouped tracks as loops"
			}
		},
		vb:space { height = DEFAULT_MARGIN },
		vb:button {
			text = "Ok", width = 200,
			notifier = function()
				perform_rendering_method(vb.views.rendering_mode.value)	
				rendering_method_dialog:close()
			end
		}
	}

  rendering_method_dialog = renoise.app():show_custom_dialog(
		"Choose rendering method...", content)
end
