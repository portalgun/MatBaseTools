#include "mex.h"
#include <stdlib.h>
#include <string>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <iostream>

using namespace std;


void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  const char* cmd;
  cmd = mxArrayToString(prhs[0]);

  struct stat sb;
  string delimiter = ":";
  string path = string(getenv("PATH"));
  size_t start_pos = 0, end_pos = 0;

  while ((end_pos = path.find(':', start_pos)) != string::npos)
    {
      string current_path = path.substr(start_pos, end_pos - start_pos) + "/" + cmd;
        //path.substr(start_pos, end_pos - start_pos) + "/mathsat";

      if ((stat(current_path.c_str(), &sb) == 0) && (sb.st_mode & S_IXOTH))
        {
          plhs[0]=mxCreateString(current_path);
          return;
         }

      start_pos = end_pos + 1;
     }

  plhs[0]=mxCreateLogicalScalar((mxLogical) false);

  return;
}
