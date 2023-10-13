
## Get a copy of the pipeline code.
- The original source of the code lives on Github under https://github.com/buschlab-muenster/buschlab-eeg-pipeline. You can download a clone of this repo 
- Create a branch of the main EEGpipeline repo and clone it to a folder on the labserver with: ``

## Download required toolboxes and plugins
- You can download these toolboxes from their respective websites and copy the files to your project folder. Doing that can be inconvenient sometimes on the labserver, for instance when the SAMBA service is not working properly. An convenient alternative is downloading the toolboxes by cloning their repositories from the command line. Go to the Linux command line in Mobaxterm and navigate to the eeglab folder, e.g. `cd /data3/Niko/buschlab-pipeline-dev/tools/eeglab2023.0/plugins/`
- When you clone the repo with git, the resulting folder will simply be named after the toolbox and will not include the version number (e.g. "eeglab" instead of "eeglab2023.0"). You can check the version number with: `git tag -l`
- You can tell the clone command which specific version you want to download with the `-b` option. You can find out about available versions on the toolbox' Github page:
![[Pasted image 20230707082005.png]]


## EEGLAB
- Download a copy of the EEGLAB toolbox from https://sccn.ucsd.edu/eeglab/downloadtoolbox.php 
- Or: `git clone --recurse-submodules --depth 1 -b 2023.0
- ... or a different version number.

## EEGLAB plugins
- The EEGLAB plugin should be copied to the eeglab/plugins folder.

### fileio plugin
- fileio plugin for importing Biosemi raw data: 
- `git clone --depth 1 -b 9.20  https://github.com/ucdavis/erplab.git`

### Eye EEG plugin
- For integrating eytracking and EEG data: https://www.eyetracking-eeg.org/index.php
- `git clone --depth 1 -b v0.99 https://github.com/olafdimigen/eye-eeg.git`

### Viewprops
- For the manual ICA inspection/rejection. https://github.com/sccn/viewprops


### ERPLAB
- `git clone --depth 1 -b 9.20  https://github.com/ucdavis/erplab.git`


## Adjust get_cfg and get_prefs
- The pipeline relies a lot on the `cfg` structure which is defined in the function `get_cfg.m` . This function is basically a long list of parameters for the various signal processing functions, e.g. defining the directories where stuff is located, or the frequency bands used for filtering.
- You need to adapt the `cfg.dir` structure according to the folder names of your project so that the pipeline can locate the files you are working with.
- /This is kinda deprecated. I would like to retire the get_prefs function and take care of its functionality oin the get_cfg structure./ The pipeline also uses the `prefs` structure defined in the function `get_prefs.m` . The purpose of this function is to allow you to use this code on different machines, e.g. via MobaXterm on the labserver and from your Windows PC with a Samba connection. A minimal adjustment you have to make in tis function is to provide the path to the EEGLAB toolbox on the machine(s) you are working with.
