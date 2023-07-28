Here is a list of things should take care of and check *before* recording EEG data.
## Biosemi cfg file
- I recommend to record additional channels around the eyes for computing HEOG and VEOG: IO1, AFp9, AFp10. It will facilitate the analysis in Matlab if these names are named appropriately in the Biosemi cfg file.

## Make sure that EEG and Eyelink are synced
- We want to be able to include the eyetracking data in the EEG data structure. This requires that the two data streams can be synchronized, which in turn requires sending markers during your experiment to both devices.
- The procedure is explained in this tutorial: https://www.eyetracking-eeg.org/tutorial.html#tutorial2

