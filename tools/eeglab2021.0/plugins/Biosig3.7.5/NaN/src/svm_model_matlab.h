/* 
  This code was extracted from libsvm 3.2.3 in Feb 2019 and 
  modified for the use with Octave and Matlab
*/ 

#include "mex.h"

#ifdef __cplusplus
extern "C" {
#endif

const char *model_to_matlab_structure(mxArray *plhs[], int num_of_feature, struct svm_model *model);
struct svm_model *matlab_matrix_to_model(const mxArray *matlab_struct, const char **error_message);


#ifdef __cplusplus
}
#endif

