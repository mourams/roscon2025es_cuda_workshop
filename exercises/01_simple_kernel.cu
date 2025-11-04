#include <iostream>

// Nuestro primer kernel: una función que se ejecuta en la GPU
__global__ void simpleKernel()
{
  printf("¡Hola desde la GPU!\n");
}

int main()
{
  // Lanzar el kernel. Aquí configuramos 1 bloque y 1 hilo por bloque
  // ¡Prueba cambiar el numero de hilos!    
  simpleKernel<<<1, 1>>>();

  // Esperar a que el kernel termine de ejecutar
  cudaDeviceSynchronize(); 

  return 0;
}