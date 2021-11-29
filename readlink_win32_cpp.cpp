#include "mex.h"
#include <sys/stat.h>
#include <string>
#include <unistd.h>
#include <limits.h>
#include <windows.h>

// XXX DOESN"T WORK, JUST A COPY OF UNIX VERSION

string do_readlink(char *path)
{
  enum { BUFFERSIZE = 1024 };
  char buf[BUFFERSIZE];
  char* str;
  ssize_t len = readlink(path, buf, sizeof(buf)-1); // XXX
  if (len != -1) {
      buf[len] = '\0';
      return string(buf);
  }
  return "";
    /* handle error condition */

}

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    struct stat S;
    char* FileName;
    int bLink;

    // Check number and type of arguments:
    if (nrhs != 1) {
      mexErrMsgTxt("*** FileIsLink[mex]: 1 input required.");
    }
    if (nlhs > 1) {
      mexErrMsgTxt("*** FileIsLink[mex]: 1 output allowed.");
    }
    // Type of input arguments:
    if (!mxIsChar(prhs[0])) {
      mexErrMsgTxt("*** FileIsLink[mex]: 1st input must be the file name.");
    }
    // Obtain FileName:
    if ((FileName = mxArrayToString(prhs[0])) == NULL) {
      mexErrMsgTxt("*** FileIsLink[mex]: "
                   "Cannot convert FileName to C-string.");
    }

    if (stat(FileName, &S) == 0) { // XXX
      bLink = S_ISLNK(S.st_mode);  // XXX
    } else {  // File not found:
        bLink = 0;
    }

    // return same name if not symlink
    if (bLink == 0) {
        plhs[0]=mxCreateString(FileName);
        return;
    }

    string str = do_readlink(FileName);

    // return dest if symlink, empty if broken
    const char* cstr=str.c_str();
    plhs[0] = mxCreateString(cstr);
    // mxFree(FileName);  
    return;
}
