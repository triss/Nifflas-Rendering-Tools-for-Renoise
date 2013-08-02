Nifflas-Rendering-Tools-for-Renoise
===================================

Renders the song, labelled patterns or ungrouped tracks as samples.

All produced samples are 16bit 44100Hz. 

A 10 sample always applied to either end of the sample when creating loops.

All renders produced by this tool are saved in the same location as the source .XRNS song.

All features silently overwrite the output from previous runs.

Error's or warning message's are only produced when a requested action can not be carried out or if clipping occurs when constructing a loop. Otherwise all status updates are sent to Renoise's status bar.

The tools features can be accessed via the following menu options:

## Tools -> Nifflas Render

Render's the song using it's chosen rendering mode or prompts for you to select one.

## Tools -> Choose Nifflas Render mode... 

Allows you to select a different rendering type for the song.

# Rendering modes:

## Render song

Renders the song without modifying it. 
The outputted sample is saved as a .WAV with the same name as the .XRNS file.

## Song as loop...

Renders the song as a loop. The last pattern of the song is removed and mixed with the first. 
The outputted sample is saved as a .WAV with the same name as the .XRNS file.

## Labelled patterns...

Renders each pattern that has a name in the song sequencer to a .WAV file with that name.

##  Labelled pattern pairs as loops...

Renders each pair of patterns that has a name in the song sequencer to a sample and then creates a loop by taking the content of the 2nd pattern and merging it with the start of the first.
Samples are saved as .WAV files with that same name as the pattern pair.

## Ungrouped tracks...

Renders each ungrouped track as a .WAV file as the same name as that track.

## Ungrouped tracks as loops...

Renders each ungrouped track as a .WAV file as the same name as that track and cuts off the last pattern of the tracks to create a loop by mixing it with the first.
