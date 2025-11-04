#include <stdio.h>

// Estructura punto 2D
struct Point 
{
    int x;
    int y;
};

// Función auxiliar que se puede ejecutar en la CPU y GPU
__host__ __device__ int calculate_sum(int a, int b) 
{
    return a + b;
}

__global__ void struct_and_device_kernel(Point p) 
{
    // Llamada a la función __device__
    int sum = calculate_sum(p.x, p.y);
    printf("Kernel: Suma de las coordenadas (%d, %d) es %d\n", p.x, p.y, sum);
}

int main() 
{
    // Inicializar la estructura en el host
    Point host_point = {10, 20};

    // Lanzar el kernel cargando la estructura en el device
    struct_and_device_kernel<<<1, 1>>>(host_point);
    cudaDeviceSynchronize();

    // Ejecutar mismo comando en la CPU
    int sum = calculate_sum(host_point.x, host_point.y);
    printf("Host: Suma de las coordenadas (%d, %d) es %d\n", host_point.x, host_point.y, sum);

    return 0;
}