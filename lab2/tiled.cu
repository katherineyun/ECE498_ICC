#include <wb.h>

#define wbCheck(stmt)                                                     \
  do {                                                                    \
    cudaError_t err = stmt;                                               \
    if (err != cudaSuccess) {                                             \
      wbLog(ERROR, "Failed to run stmt ", #stmt);                         \
      wbLog(ERROR, "Got CUDA error ...  ", cudaGetErrorString(err));      \
      return -1;                                                          \
    }                                                                     \
  } while (0)


#define TILE_WIDTH 4
// Compute C = A * B
__global__ void matrixMultiply(float *A, float *B, float *C, int numARows,
                               int numAColumns, int numBRows,
                               int numBColumns, int numCRows,
                               int numCColumns) {

   __shared__ float subTileM[TILE_WIDTH][TILE_WIDTH];
  __shared__ float subTileN[TILE_WIDTH][TILE_WIDTH];

  int Row = blockIdx.y * TILE_WIDTH + threadIdx.y;
  int Col = blockIdx.x * TILE_WIDTH + threadIdx.x;

  float pValue = 0;
  for(int m = 0; m < (numAColumns -1)/TILE_WIDTH +1; ++m) {
    
    if(Row<numARows && m*TILE_WIDTH+threadIdx.x < numAColumns)
      subTileM[threadIdx.y][threadIdx.x] = A[Row * numAColumns + m * TILE_WIDTH + threadIdx.x];
    else
      subTileM[threadIdx.y][threadIdx.x] = 0;
    if(m*TILE_WIDTH + threadIdx.y < numBRows && Col < numBColumns)
      subTileN[threadIdx.y][threadIdx.x] = B[(m * TILE_WIDTH + threadIdx.y) * numBColumns + Col];
    else
      subTileN[threadIdx.y][threadIdx.x] = 0;

    __syncthreads();
    if(Row < numCRows && Col < numCColumns){
    for (int k = 0; k < TILE_WIDTH; ++k) 
      pValue += subTileM[threadIdx.y][k] * subTileN[k][threadIdx.x];}
    __syncthreads();
    

  }
    if(Row < numCRows && Col < numCColumns)
      C[Row * numCColumns + Col] = pValue;
}

int main(int argc, char **argv) {
  wbArg_t args;
  float *hostA; // The A matrix
  float *hostB; // The B matrix
  float *hostC; // The output C matrix
  float *deviceA;
  float *deviceB;
  float *deviceC;
  int numARows;    // number of rows in the matrix A
  int numAColumns; // number of columns in the matrix A
  int numBRows;    // number of rows in the matrix B
  int numBColumns; // number of columns in the matrix B
  int numCRows;    // number of rows in the matrix C (you have to set this)
  int numCColumns; // number of columns in the matrix C (you have to set
                   // this)

  args = wbArg_read(argc, argv);

  wbTime_start(Generic, "Importing data and creating memory on host");
  hostA = (float *)wbImport(wbArg_getInputFile(args, 0), &numARows,
                            &numAColumns);
  hostB = (float *)wbImport(wbArg_getInputFile(args, 1), &numBRows,
                            &numBColumns);
  //@@ Set numCRows and numCColumns
  numCRows = numARows;
  numCColumns = numBColumns;
  //@@ Allocate the hostC matrix
  wbTime_stop(Generic, "Importing data and creating memory on host");
  hostC = (float *)malloc(numCRows*numCColumns * sizeof(float));
  wbLog(TRACE, "The dimensions of A are ", numARows, " x ", numAColumns);
  wbLog(TRACE, "The dimensions of B are ", numBRows, " x ", numBColumns);

  wbTime_start(GPU, "Allocating GPU memory.");
  //@@ Allocate GPU memory here
  cudaMalloc((void**) &deviceA,numARows*numAColumns*sizeof(float));
  cudaMalloc((void**) &deviceB,numBRows*numBColumns*sizeof(float));
  cudaMalloc((void**) &deviceC,numCRows*numCColumns*sizeof(float));
  wbTime_stop(GPU, "Allocating GPU memory.");

  wbTime_start(GPU, "Copying input memory to the GPU.");
  //@@ Copy memory to the GPU here
  cudaMemcpy(deviceA,hostA,numARows*numAColumns*sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(deviceB,hostB,numBRows*numBColumns*sizeof(float), cudaMemcpyHostToDevice);
  
  wbTime_stop(GPU, "Copying input memory to the GPU.");

  //@@ Initialize the grid and block dimensions here
  int WIDTH = 4.0;
  dim3 dimGrid(ceil(1.0*numCColumns/WIDTH),ceil(1.0*numCRows/WIDTH),1); //inverse col and row
  dim3 dimBlock(WIDTH,WIDTH,1);
  wbTime_start(Compute, "Performing CUDA computation");
  //@@ Launch the GPU Kernel here
  matrixMultiply<<<dimGrid, dimBlock>>>(deviceA, deviceB, deviceC, numARows, numAColumns,  numBRows, numBColumns,  numCRows,
                                numCColumns);
  cudaDeviceSynchronize();
  wbTime_stop(Compute, "Performing CUDA computation");

  wbTime_start(Copy, "Copying output memory to the CPU");
  //@@ Copy the GPU memory back to the CPU here
  cudaMemcpy(hostC,deviceC,numCRows*numCColumns*sizeof(float), cudaMemcpyDeviceToHost);
  
  wbTime_stop(Copy, "Copying output memory to the CPU");

  wbTime_start(GPU, "Freeing GPU Memory");
  //@@ Free the GPU memory here
  cudaFree(deviceA);
  cudaFree(deviceB);
  cudaFree(deviceC);
  wbTime_stop(GPU, "Freeing GPU Memory");

  wbSolution(args, hostC, numCRows, numCColumns);

  free(hostA);
  free(hostB);
  free(hostC);

  return 0;
}
