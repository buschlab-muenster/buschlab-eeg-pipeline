# buschlab-eeg-pipeline

**A template for a (pre)processing pipeline for EEG data, coded in Matlab**

<img src="./documentation\izzy-jiang-PMZb2JDSKGY-unsplash.jpg" alt="alt text" width="300">

Photo by <a href="https://unsplash.com/@izzyjiang?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Izzy Jiang</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>



# Table of contents

- [Before](./documentation/before_recording.md)





## Design principles

- As much as possible, the pipeline has only three levels of code:
  
  1. **Scripts**: each processing step has its own script. What constitutes a step, and why not include the entire pre-processing pipeline within a single script? My general rule of thumb is: the ideal script fits on a single screen page, although in reality, scripts are often longer, but I try to keep them as short as possible. Moreover, scripts include only those processing steps that belong to the same processing stage, such that you can re-run a downstream stage with different parameters without starting from scratch. For instance, you might want to re-run the ICA without having to import the raw data again. 
     Some scripts include verbatim processing commands such as `pop_saveset`, but most of the actual processing happens inside a sub-function. My general rule of thumb is that if a processing step requires more than three lines of code, I move it into a sub-function.
     
     The heart of each script is simply a loop over datasets/subjects. Ideally, the inside of the loop is written so concise and descriptive that you can read it as a description of what is happening (e.g. "load the data, do the filtering, save results") without necessarily checking the exact implementation of the algorithms that do the actual processing.
  
  2. **Sub-functions**: most of the action happens inside the sub-functions. As much as possible, I try to code these functions such that a single function does only a single thing. I also try to keep the input as minimal as possible; most sub-functions require only the input data and a specific subfield of the `cfg`struct. The convention is that sub- function are named `func_PROCESSINGSTAGE_WHATITDOES.m` , e.g. `func_import_downsample.m`. In the end, the sub-functions are only wrappers to call toolbox functions, which then do the heavy lifting.
  
  3. **Toolbox functions**: these functions implement the processing algorithms, e.g. for filtering, ICA, or artifact rejection. I consider these functions "untouchable", meaning I want to rely on their functionality and assume that I will never have to edit any of these functions. 

- Unlike Elektro-pipe, my pipeline does not require a subject "database", e.g. an Excel spreadsheet with a list of all subjects, in which you and the pipeline keep track of which subjects are included, which datasets are alrady processed etc. Instead, my pipeline simply uses a `dir` command on the appropriate data folder to check which input data files are available for processing, and for checking which output data files already exist. Depending on a switch in the `cfg`file, the pipeline then decides which data files are processed, and if any exisiting files need reprocessing and overwriting. Thus, there is no flag indicating a dataset "to be excluded" -- if you don't want a dataset to be processed, just remove it from the standard data folder. 

## The `cfg` struct and `getcfg`function

- Every parameter that involves a decision is set in the `cfg`struct, which is define din the `getcfg`function. No parameter values are **ever** harcoded inside scripts or functions.
- The `cfg`struct has a number of fields/sub-structs, such as `cfg.dir.` or `cfg.epoch.`. All parameters reside inside one of there subfields. This gives the `cfg` struct a hierarchical order, which offers several advantages:
  1. The parameters are more descriptive. For instance, `cfg.epoch.tlims = [-1 2]` informs you that `tlims`is relevant at the epoching stages.
  2. As much as possible, the subfields correspond to one of the analysis subfunctions. Thus, instead of passing the entire `cfg` struct to each of the numerous analysis subfunctions, we can pass only those parameters that are relevant for a given function. This makes it easier to understand the relevant parameters expected by each function.
  3. For programming analysis functions, I find it easier, safer, and more elegant to be selective about the parameter input into the function. Instead of passing every parameter, I can pass only parameters that are needed inside the function, which in turn forces me to think about what the function really needs.

## The `getprefs`function

- This function includes preferences that are specific for the environment/machine on which the code is currently running. The main purpose is to load necessary toolboxes, assuming that paths to these olders might be different on different machines and/or operating systems.
- I also use `getprefs` to adjust the number of cores ot be used for parallel `parfor`loops.

## Tools you need

- EEGLAB toolbox
- Olaf Dimigen's Eye-EEG plugin
- ERPLAB plugin (for filters)
- Wanja Mössing's Elektro-pipe toolbox
- EDF2ASC executable for converting eyetracking data. This should already be installed on labserver1.
- Wanja's replacement for the fileio plugin, which can read triggers sent via our custom-made 16-bit trigger cable. 

## Todos

- [ ] Make the entire pipeline independent of Wanja's Elektropipe, either by reimplementing these functions from scratch or by at least moving them to the `./functions` subfolder so that the skinny pipeline has no dependencies with Elektropipe.
- [ ] Test if the getprefs settings for number of cores actually work as intended.- [ ] 
- [ ] Simplify structure of `getcfg`and `getprefs` to make it easier to adapt these functions to your own work environment.
- [ ] EEGLAB management is still a mess. Some of our scripts require only a few functions, others require several folders/plugins, ther eis always the problem with name duplicates from the fieldtrip-lite functions, and EEGLAB complains when the EEGLAB folder is added with all paths. `script04_cleanica.m` even requires that EEGLAB is initialized with all global variables like `ALLEEG`, `CURRENTSET`etc.  Can we clean this up?

## Pipeline Meeting

- this is a test (ALB)
