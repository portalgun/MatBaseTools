#include "mex.h"
#include <unistd.h>
#include <limits.h>
#if defined _WIN32
  #include <winsock.h>
#endif


void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    char username[LOGIN_NAME_MAX];
    getlogin_r(username, LOGIN_NAME_MAX);
    plhs[0]=mxCreateString(username);
}
