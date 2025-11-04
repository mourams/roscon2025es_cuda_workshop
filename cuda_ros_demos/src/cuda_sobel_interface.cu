#include "cuda_ros_demos/cuda_sobel_interface.cuh"

#include <cuda_runtime.h>
#include <iostream>

#define BLOCK_SIZE 16
#define RADIUS 1
#define MAX_SOBEL_MAG 1020.0f

// Operadores - constantes en memoria
__constant__ int Gx[3][3] = {
    {-1, 0, 1},
    {-2, 0, 2},
    {-1, 0, 1}};

__constant__ int Gy[3][3] = {
    {-1, -2, -1},
    {0, 0, 0},
    {1, 2, 1}};

// Sobel Kernel utilizando memoria compartida
__global__ void sobelSharedKernel(const unsigned char *input, unsigned char *output, int width, int height, float threshold)
{
    __shared__ unsigned char tile[BLOCK_SIZE + 2 * RADIUS][BLOCK_SIZE + 2 * RADIUS];

    int x = blockIdx.x * BLOCK_SIZE + threadIdx.x;
    int y = blockIdx.y * BLOCK_SIZE + threadIdx.y;

    int shared_x = threadIdx.x + RADIUS;
    int shared_y = threadIdx.y + RADIUS;

    // Cargar píxel central
    if (x < width && y < height)
        tile[shared_y][shared_x] = input[y * width + x];
    else
        tile[shared_y][shared_x] = 0;

    // // Cargar bordes
    // if (threadIdx.x < RADIUS)
    // {
    //     int left = max(x - RADIUS, 0);
    //     int right = min(x + BLOCK_SIZE, width - 1);
    //     if (y < height)
    //     {
    //         tile[shared_y][threadIdx.x] = input[y * width + left];
    //         tile[shared_y][shared_x + BLOCK_SIZE - threadIdx.x] = input[y * width + right];
    //     }
    // }

    // // Cargar bordes superior e inferior
    // if (threadIdx.y < RADIUS)
    // {
    //     int top = max(y - RADIUS, 0);
    //     int bottom = min(y + BLOCK_SIZE, height - 1);
    //     if (x < width)
    //     {
    //         tile[threadIdx.y][shared_x] = input[top * width + x];
    //         tile[shared_y + BLOCK_SIZE - threadIdx.y][shared_x] = input[bottom * width + x];
    //     }
    // }

    // Load halo pixels around left/right edges
    for(int dy = -RADIUS; dy <= RADIUS; dy++)
    {
        int ty = threadIdx.y + dy + RADIUS;
        int iy = min(max(y + dy, 0), height-1);

        if(threadIdx.x < RADIUS)
        {
            // left halo
            int ix = min(max(x - RADIUS, 0), width-1);
            tile[ty][threadIdx.x] = input[iy*width + ix];

            // right halo
            ix = min(max(x + BLOCK_SIZE, 0), width-1);
            tile[ty][shared_x + BLOCK_SIZE] = input[iy*width + ix];
        }
    }

    // Load halo pixels around top/bottom edges
    for(int dx = -RADIUS; dx <= RADIUS; dx++)
    {
        int tx = threadIdx.x + dx + RADIUS;
        int ix = min(max(x + dx, 0), width-1);

        if(threadIdx.y < RADIUS)
        {
            // top halo
            int iy = min(max(y - RADIUS, 0), height-1);
            tile[threadIdx.y][tx] = input[iy*width + ix];

            // bottom halo
            iy = min(max(y + BLOCK_SIZE, 0), height-1);
            tile[shared_y + BLOCK_SIZE][tx] = input[iy*width + ix];
        }
    }

    __syncthreads();

    // Aplicar filtro Sobel
    if (x < width && y < height)
    {
        float sumX = 0.0f, sumY = 0.0f;
        for (int ky = -RADIUS; ky <= RADIUS; ky++)
        {
            for (int kx = -RADIUS; kx <= RADIUS; kx++)
            {
                float pixel = static_cast<float>(tile[shared_y + ky][shared_x + kx]);
                sumX += pixel * Gx[ky + 1][kx + 1];
                sumY += pixel * Gy[ky + 1][kx + 1];
            }
        }

        // Sólo conservar bordes que superen el umbral
        float mag = sqrtf(sumX * sumX + sumY * sumY);
        float scaled = (mag / MAX_SOBEL_MAG) * 255.0f;
        output[y*width + x] = (scaled >= threshold) ? 255 : 0;
    }
}

// Función de interfaz
void runCudaSobel(const cv::Mat &input, cv::Mat &output, float threshold)
{
    if (input.empty() || input.type() != CV_8UC1)
    {
        std::cerr << "[CUDA Sobel] Input must be non-empty grayscale image (CV_8UC1)!" << std::endl;
        return;
    }

    int width = input.cols;
    int height = input.rows;
    size_t imgSize = width * height * sizeof(unsigned char);

    // Alocar memoria en la GPU (Jetson - unificada)
    uchar *d_input = nullptr;
    uchar *d_output = nullptr;
    CUDA_CHECK(cudaMallocManaged(&d_input, imgSize));
    CUDA_CHECK(cudaMallocManaged(&d_output, imgSize));

    // Copiar datos
    memcpy(d_input, input.data, imgSize);

    // Lanzar kernel
    dim3 block(BLOCK_SIZE, BLOCK_SIZE);
    dim3 grid((width + BLOCK_SIZE - 1) / BLOCK_SIZE,
              (height + BLOCK_SIZE - 1) / BLOCK_SIZE);
    sobelSharedKernel<<<grid, block>>>(d_input, d_output, width, height, threshold);
    cudaDeviceSynchronize();

    // Copiar resultado de vuelta
    output.create(height, width, CV_8UC1);
    cudaMemcpy(output.data, d_output, imgSize, cudaMemcpyDeviceToHost);

    // Liberar memoria de la GPU
    CUDA_CHECK(cudaFree(d_input));
    CUDA_CHECK(cudaFree(d_output));
}
