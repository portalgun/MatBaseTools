#include "mex.h"
#include <unistd.h>

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
        char *homedir = getenv("HOME");
        plhs[0]=mxCreateString(homedir);
}
