#include <stdio.h>
#include <cuda_runtime.h>

#define N 1024

// Kernel simple de suma (reutilizado)
__global__ void simple_add_kernel(float *A, float *B, float *C, int size) 
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < size) {
        C[idx] = A[idx] + B[idx];
    }
}

int main() 
{
    float *h_A, *h_B, *h_C;
    float *d_A, *d_B, *d_C;

    // Asignación de memoria pinneada (necesario para la concurrencia Host-Device)
    cudaHostAlloc((void**)&h_A, N * sizeof(float), cudaHostAllocPortable);
    cudaHostAlloc((void**)&h_B, N * sizeof(float), cudaHostAllocPortable);
    cudaHostAlloc((void**)&h_C, N * sizeof(float), cudaHostAllocPortable);

    for (int i = 0; i < N; i++) {
        h_A[i] = 1.0f;
        h_B[i] = 2.0f;
    }

    cudaMalloc((void**)&d_A, N * sizeof(float));
    cudaMalloc((void**)&d_B, N * sizeof(float));
    cudaMalloc((void**)&d_C, N * sizeof(float));

    // Crear un stream
    cudaStream_t stream;
    cudaStreamCreate(&stream);

    // Operaciones asíncronas en el stream:

    // Transferencia de A al Device (asíncrona)
    cudaMemcpyAsync(d_A, h_A, N * sizeof(float), cudaMemcpyHostToDevice, stream);

    // Transferencia de B al Device (asíncrona)
    cudaMemcpyAsync(d_B, h_B, N * sizeof(float), cudaMemcpyHostToDevice, stream);

    // Lanzamiento del Kernel (asíncrono)
    int threadsPerBlock = 256;
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;
    simple_add_kernel<<<blocksPerGrid, threadsPerBlock, 0, stream>>>(d_A, d_B, d_C, N);

    // Transferencia de C al Host (asíncrona)
    cudaMemcpyAsync(h_C, d_C, N * sizeof(float), cudaMemcpyDeviceToHost, stream);

    // Esperar a que el stream finalice
    cudaStreamSynchronize(stream);

    // Verificación
    if (h_C[0] == 3.0f) 
    {
        printf("Ejecución Asíncrona Exitosa. Resultado: %.1f\n", h_C[0]);
    }

    // Limpieza
    cudaStreamDestroy(stream);
    cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);
    cudaFreeHost(h_A); cudaFreeHost(h_B); cudaFreeHost(h_C);

    return 0;
}