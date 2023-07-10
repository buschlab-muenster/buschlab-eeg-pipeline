

As much as possible, the pipeline has only three levels of code:

### 1. Scripts
- Each processing step has its own script. What constitutes a step, and why not include the entire pre-processing pipeline within a single script? My general rule of thumb is: the ideal script fits on a single screen page, although in reality, scripts are often longer, but I try to keep them as short as possible. Moreover, scripts include only those processing steps that belong to the same processing stage, such that you can re-run a downstream stage with different parameters without starting from scratch. For instance, you might want to re-run the ICA without having to import the raw data again. 
- Some scripts include verbatim processing commands such as `pop_saveset`, but most of the actual processing happens inside a sub-function. My general rule of thumb is that if a processing step requires more than three lines of code, I move it into a sub-function.
- The heart of each script is simply a loop over datasets/subjects. Ideally, the inside of the loop is written so concise and descriptive that you can read it as a description of what is happening (e.g. "load the data, do the filtering, save results") without necessarily checking the exact implementation of the algorithms that do the actual processing.

### Sub-functions
- Most of the action happens inside the sub-functions. As much as possible, I try to code these functions such that a single function does only a single thing. I also try to keep the input as minimal as possible; most sub-functions require only the input data and a specific subfield of the `cfg`struct. The convention is that sub- function are named `func_PROCESSINGSTAGE_WHATITDOES.m` , e.g. `func_import_downsample.m`. In the end, the sub-functions are only wrappers to call toolbox functions, which then do the heavy lifting.

### Toolbox functions
- These functions implement the processing algorithms, e.g. for filtering, ICA, or artifact rejection. I consider these functions "untouchable", meaning I want to rely on their functionality and assume that I will never have to edit any of these functions. 

### Elektropipe legacy.
- Unlike Elektro-pipe, my pipeline does not require a subject "database", e.g. an Excel spreadsheet with a list of all subjects, in which you and the pipeline keep track of which subjects are included, which datasets are alrady processed etc. Instead, my pipeline simply uses a `dir` command on the appropriate data folder to check which input data files are available for processing, and for checking which output data files already exist. Depending on a switch in the `cfg`file, the pipeline then decides which data files are processed, and if any exisiting files need reprocessing and overwriting. Thus, there is no flag indicating a dataset "to be excluded" -- if you don't want a dataset to be processed, just remove it from the standard data folder. 