#include "mex.h"
#include <unistd.h>
#include <limits.h>
#if defined _WIN32
  #include <winsock.h>
#elif __APPLE__
  #define __USE_POSIX
#endif


void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    char username[_POSIX_LOGIN_NAME_MAX];
    getlogin_r(username, _POSIX_LOGIN_NAME_MAX);
    //char username[LOGIN_NAME_MAX];
    //getlogin_r(username, LOGIN_NAME_MAX);
    plhs[0]=mxCreateString(username);
}
