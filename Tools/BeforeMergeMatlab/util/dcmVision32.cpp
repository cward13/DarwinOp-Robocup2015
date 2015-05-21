/*
  ret = dcmSensor(args);

  mex -O dcmSensor.cpp -I/usr/local/boost -lrt

  Matlab MEX file to access shared memory using Boost interprocess
  Author: Stephen McGill w/ Daniel Lee
*/

#include "mex.h"

#define WIDTH 320
#define HEIGHT 240

#include <boost/interprocess/managed_shared_memory.hpp>
using namespace boost::interprocess;

static const char visionShmName[] = "vision";
static managed_shared_memory visionShm;

mxArray *bufArray = NULL;

void mexExit(void)
{
  if (bufArray) {
    // Don't free mmap memory:
    printf("Null'ing the Buffer Array (%x)...\n",bufArray);
    mxSetData(bufArray, NULL);
    printf("Destroying the Buffer Array...\n");
    mxDestroyArray(bufArray);
    printf("Done with the Buffer Array!\n");
  }
  fprintf(stdout, "Exiting dcmSensor.\n");
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  static bool init = false;
  if (!init) {
    fprintf(stdout, "Attaching shm: %s", visionShmName);
    visionShm = managed_shared_memory(open_only, visionShmName);

    mwSize dims[2];
    dims[0] = WIDTH/2;
    dims[1] = HEIGHT;
    bufArray = mxCreateNumericArray(2, dims, mxUINT32_CLASS, mxREAL);
    mexMakeArrayPersistent(bufArray);
    mxFree(mxGetData(bufArray));

    mexAtExit(mexExit);
    init = true;
  }

  if ((nrhs < 1) || (!mxIsChar(prhs[0])))
    mexErrMsgTxt("Need to input string argument");
  const char* key = mxArrayToString(prhs[0]);

  // Try to find key
  std::pair<double *, std::size_t> ret;
  ret = visionShm.find<double>(key);
  void *p = (void*)ret.first;
  int n = ret.second;
  if (p == NULL) {
    plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
    return;
  }
  
  mxSetData(bufArray, p);
  plhs[0] = bufArray;
}
