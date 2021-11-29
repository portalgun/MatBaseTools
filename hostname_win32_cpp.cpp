#include "mex.h"
#include <unistd.h>
#include <Winsock2.h>
#include <limits.h>


void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  char hostname[128];
  ::gethostname(hostname, sizeof(hostname));
  plhs[0]=mxCreateString(hostname);
}
