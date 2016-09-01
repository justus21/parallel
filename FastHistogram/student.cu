/* Udacity HW5
   Histogramming for Speed

   The goal of this assignment is compute a histogram
   as fast as possible.  We have simplified the problem as much as
   possible to allow you to focus solely on the histogramming algorithm.

   The input values that you need to histogram are already the exact
   bins that need to be updated.  This is unlike in HW3 where you needed
   to compute the range of the data and then do:
   bin = (val - valMin) / valRange to determine the bin.

   Here the bin is just:
   bin = val

   so the serial histogram calculation looks like:
   for (i = 0; i < numElems; ++i)
   histo[val[i]]++;

   That's it!  Your job is to make it run as fast as possible!

   The values are normally distributed - you may take
   advantage of this fact in your implementation.

*/


#include "utils.h"

// Naive solution for reference
__global__
void naive(const unsigned int* const vals, //INPUT
           unsigned int* const histo,      //OUPUT
           unsigned int numVals)
{
    int id = threadIdx.x + blockIdx.x * blockDim.x;
    if (id >= numVals) {
        return;
    }
    int bin = vals[id];
    atomicAdd(&histo[bin], 1);
}

__global__
void privatized(const unsigned int* const vals,
                unsigned int* const histo,
                unsigned int numVals)
{
    int id = threadIdx.x + blockIdx.x * blockDim.x;
    if (id >= numVals) {
        return;
    }
    __shared__ unsigned int sub[1024];
    sub[threadIdx.x] = 0;
    __syncthreads();
    unsigned int bin = vals[id];
    atomicAdd(&sub[bin], 1);
    __syncthreads();
    atomicAdd(&histo[threadIdx.x], sub[threadIdx.x]);
}

void computeHistogram(const unsigned int* const d_vals, //INPUT
                      unsigned int* const d_histo,      //OUTPUT
                      const unsigned int numBins,
                      const unsigned int numElems)
{
    // numBins == 1024
    // numElems == 10240000
    const dim3 blockSize = 1024;
    const dim3 gridSize = (numElems / blockSize.x) + 1;
    
//    naive<<<gridSize, blockSize>>>(d_vals, d_histo, numElems);
    privatized<<<gridSize, blockSize>>>(d_vals, d_histo, numElems);
    cudaDeviceSynchronize();
    checkCudaErrors(cudaGetLastError());
}
