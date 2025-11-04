#include <stdio.h>
#include <stdlib.h>

#define N 512 // Tamaño del vector. Debe ser par.
#define TILE_SIZE 256 // El tamaño del bloque

// Kernel para invertir un vector usando memoria compartida
__global__ void invert_kernel_corrected(int *d_A, int size) 
{
    // Memoria Compartida: Almacena la porción del vector a invertir
    __shared__ int s_tile[TILE_SIZE];

    // Cálculo del índice local (dentro del bloque)
    int local_idx = threadIdx.x;
    
    // Cálculo de los índices de memoria global para la porción del bloque
    // Los índices del bloque 'blockIdx.x' van desde 'offset'
    int offset = blockIdx.x * blockDim.x;

    // Cargar el dato de Memoria Global (d_A) a Memoria Compartida (s_tile)
    // El hilo 'local_idx' se encarga de cargar el elemento 'offset + local_idx'
    int global_read_idx = offset + local_idx;

    if (global_read_idx < size) 
    {
        s_tile[local_idx] = d_A[global_read_idx];
    }
    
    // Sincronización: Esperar a que todos los hilos del bloque carguen su dato
    __syncthreads();

    // Escribir el dato desde Memoria Compartida a la posición invertida en Memoria Global
    
    // El hilo 'local_idx' lee de s_tile[local_idx]
    // y lo escribe en la posición que es el COMPLEMENTO del índice de lectura.
    
    // Si el índice de lectura es 'global_read_idx', el índice de escritura debe ser:
    int global_write_idx = (size - 1) - global_read_idx; 

    if (global_write_idx >= 0 && global_write_idx < size) 
    {
        // El hilo 'local_idx' escribe el valor que está en s_tile[local_idx]
        // en la posición global invertida 'global_write_idx'.
        d_A[global_write_idx] = s_tile[local_idx];
    }
}

int main() 
{
    int *h_A, *d_A;
    int arraySize = N;

    // Asignación e Inicialización
    h_A = (int*)malloc(arraySize * sizeof(int));
    for (int i = 0; i < arraySize; i++) 
    {
        h_A[i] = i; // Inicialización: [0, 1, 2, ..., 511]
    }

    printf("Vector Inicial: [%d, %d, ..., %d, %d]\n", h_A[0], h_A[1], h_A[N-2], h_A[N-1]);

    // Asignación y Transferencia H->D
    cudaMalloc((void**)&d_A, arraySize * sizeof(int));
    cudaMemcpy(d_A, h_A, arraySize * sizeof(int), cudaMemcpyHostToDevice);

    // Dimensiones de lanzamiento
    int threadsPerBlock = TILE_SIZE;
    int blocksPerGrid = (arraySize + threadsPerBlock - 1) / threadsPerBlock;

    // Lanzamiento del Kernel Corregido
    invert_kernel_corrected<<<blocksPerGrid, threadsPerBlock>>>(d_A, arraySize);
    cudaDeviceSynchronize();

    // Transferencia D->H y Verificación
    cudaMemcpy(h_A, d_A, arraySize * sizeof(int), cudaMemcpyDeviceToHost);

    printf("Vector Invertido: [%d, %d, ..., %d, %d]\n", h_A[0], h_A[1], h_A[N-2], h_A[N-1]);
    // El resultado esperado es una inversión completa: [511, 510, ..., 1, 0]

    // Liberación de Memoria
    free(h_A);
    cudaFree(d_A);

    return 0;
}