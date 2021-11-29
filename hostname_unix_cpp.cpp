#include "mex.h"
#include <unistd.h>
#include <limits.h>


void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  char hostname[_POSIX_HOST_NAME_MAX];
  ::gethostname(hostname, sizeof(hostname));
  plhs[0]=mxCreateString(hostname);
}
