/* 
  This code was extracted from liblinear-2.2.1 in Feb 2019 and 
  modified for the use with Octave and Matlab
*/ 

#include "mex.h"

#ifdef __cplusplus
extern "C" {
#endif

const char *model_to_matlab_structure(mxArray *plhs[], struct model *model_);
const char *matlab_matrix_to_model(struct model *model_, const mxArray *matlab_struct);

#ifdef __cplusplus
}
#endif

