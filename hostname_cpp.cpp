#include "mex.h"
#include <unistd.h>
#if defined _WIN32
  #include <winsock.h>
#endif
#include <limits.h>

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  char hostname[_POSIX_HOST_NAME_MAX];
  gethostname(hostname, _POSIX_HOST_NAME_MAX);
  plhs[0]=mxCreateString(hostname);
}
