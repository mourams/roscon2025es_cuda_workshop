#include <iostream>

__global__ void kernelUno() 
{
  printf("¡Hola desde kernel uno!\n");
}

__global__ void kernelDos() 
{
  printf("¡Hola desde kernel dos!\n");
}

int main() 
{
    int threadsPerBlock = 1;
    int blocksPerGrid = 1;

    printf("Host: ejecutando kernel 1\n");
    kernelUno<<<blocksPerGrid, threadsPerBlock>>>();

    // No es necesario sincronizar si kernel2 no necesita del resultado.
    // Prueba quitar la sincronización y ver qué pasa.
    cudaDeviceSynchronize();

    printf("Host: ejecutando kernel 2\n");
    kernelDos<<<blocksPerGrid, threadsPerBlock>>>();

    cudaDeviceSynchronize();
    printf("Host: ambos kernels han finalizado\n");

    return 0;
}