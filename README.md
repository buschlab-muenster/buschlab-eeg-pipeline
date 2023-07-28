# buschlab-eeg-pipeline

**A template for a (pre)processing pipeline for EEG data, coded in Matlab**

<img src="./documentation\izzy-jiang-PMZb2JDSKGY-unsplash.jpg" alt="alt text" width="300">

Photo by <a href="https://unsplash.com/@izzyjiang?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Izzy Jiang</a> on <a href="https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>

Refer to the documentation in the "Documentation" subfolder. Currently best viewed as an Obsidian vault.

[Here](https://trello.com/b/91PwZtSc/buschlabpipeline) is the link to the development Trello board.








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
