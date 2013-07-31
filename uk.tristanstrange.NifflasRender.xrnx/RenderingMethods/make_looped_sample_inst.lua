-- Load a sample and produces an instrument containing a looped version of it
--
-- If the loop clips due to merging the volume of the sample is normlised
-- A 10 sample fade is appled to either end of the sample to prevent clicking
-- Returns an instrument containing a looped version of the sample
-- - sample_path - file name of sample to load
-- - tail_len - length of samples tail in frames
function make_looped_sample_inst(sample_path, tail_len)
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
