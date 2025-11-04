#include <stdio.h>
#include <cuda_runtime.h>

int main() 
{
    // Obtener el número de dispositivos CUDA
    int deviceCount;
    cudaGetDeviceCount(&deviceCount);

    if (deviceCount == 0) 
    {
        printf("¡Error! No se encontraron dispositivos CUDA.\n");
        return 1;
    }

    printf("Dispositivos CUDA encontrados: %d\n", deviceCount);

    // Iterar sobre cada dispositivo y mostrar sus propiedades
    for (int i = 0; i < deviceCount; i++) 
    {
        cudaDeviceProp devProp;
        // Establecer el dispositivo actual
        cudaSetDevice(i);
        // Obtener las propiedades del dispositivo
        cudaGetDeviceProperties(&devProp, i);

        printf("\n--- Propiedades del Dispositivo %d ---\n", i);
        printf("Nombre del Dispositivo: %s\n", devProp.name);
        printf("Memoria Global Total: %.2f GB\n", devProp.totalGlobalMem / (1024.0 * 1024.0 * 1024.0));
        printf("Capacidad de Cómputo (SM): %d.%d\n", devProp.major, devProp.minor);
        printf("Número Máximo de Hilos por Bloque: %d\n", devProp.maxThreadsPerBlock);
        printf("Número de Multiprocesadores (SMs): %d\n", devProp.multiProcessorCount);
    }

    return 0;
}