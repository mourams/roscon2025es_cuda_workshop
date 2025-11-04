#include <stdio.h>
#include <stdlib.h>
#include <chrono>

// Función para sumar vectores en la CPU (Host)
// Prueba algo más complejo... (combinación de operaciones)
void vectorAddCPU(const float *A, const float *B, float *C, int size) 
{
    for (int i = 0; i < size; i++) 
    {
        C[i] = A[i] + B[i];
    }
}

// Kernel para sumar vectores en la GPU (Device)
// Prueba algo más complejo... (combinación de operaciones)
__global__ void vectorAddGPU(const float *A, const float *B, float *C, int size) 
{
    // Cálculo del índice global del hilo
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if (idx < size) {
        C[idx] = A[idx] + B[idx];
    }
}

int main() 
{
    float *h_A, *h_B, *h_C_cpu, *h_C_gpu; // Punteros de host
    float *d_A, *d_B, *d_C;               // Punteros de device
    double elapsed_time;
    
    int N = 1048576; // 2^20 elementos. Prueba añadir uno o dos ceros...

    // Asignación de Memoria en el Host
    h_A = (float*)malloc(N * sizeof(float));
    h_B = (float*)malloc(N * sizeof(float));
    h_C_cpu = (float*)malloc(N * sizeof(float));
    h_C_gpu = (float*)malloc(N * sizeof(float));

    // Inicialización de los datos
    for (int i = 0; i < N; i++) {
        h_A[i] = 1.0f;
        h_B[i] = 2.0f;
    }

    // --- Ejecución en la CPU ---

    auto start = std::chrono::high_resolution_clock::now();
    vectorAddCPU(h_A, h_B, h_C_cpu, N);
    auto end = std::chrono::high_resolution_clock::now();

    elapsed_time = std::chrono::duration<double, std::milli>(end - start).count() / 1000.0;
    printf("Tiempo de CPU para la suma de vectores: %.6f segundos\n", elapsed_time);

    // --- Ejecución en de la GPU ---

    // Asignación de Memoria en el Device
    cudaMalloc((void**)&d_A, N * sizeof(float));
    cudaMalloc((void**)&d_B, N * sizeof(float));
    cudaMalloc((void**)&d_C, N * sizeof(float));

    // Transferencia de Datos del Host al Device (A y B)
    cudaMemcpy(d_A, h_A, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, N * sizeof(float), cudaMemcpyHostToDevice);

    // Definición de las dimensiones
    int threadsPerBlock = 256;
    int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;

    // Medición del tiempo de la GPU (simplificada solo para el kernel)
    start = std::chrono::high_resolution_clock::now();

    // 4. Lanzamiento del Kernel
    vectorAddGPU<<<blocksPerGrid, threadsPerBlock>>>(d_A, d_B, d_C, N);

    // 5. Transferencia de Resultados del Device al Host (C)
    cudaMemcpy(h_C_gpu, d_C, N * sizeof(float), cudaMemcpyDeviceToHost);

    cudaDeviceSynchronize(); // Asegurar que todo ha terminado antes de medir
    end = std::chrono::high_resolution_clock::now();

    elapsed_time = std::chrono::duration<double, std::milli>(end - start).count() / 1000.0;
    printf("Tiempo de GPU (incluye transferencias) para la suma de vectores: %.6f segundos\n", elapsed_time);

    // 6. Verificación (primer elemento)
    if (h_C_gpu[0] == 3.0f) 
    {
        printf("Verificación exitosa: h_C_gpu[0] = %.1f\n", h_C_gpu[0]);
    } 
    else 
    {
        printf("¡Error de verificación!\n");
    }

    // Liberar memoria
    cudaFree(d_A); 
    cudaFree(d_B); 
    cudaFree(d_C);
    free(h_A); 
    free(h_B); 
    free(h_C_cpu); 
    free(h_C_gpu);

    return 0;
}