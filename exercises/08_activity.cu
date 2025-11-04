#include <iostream>
#include <cuda_runtime.h>

/* Actividad: Implementar la multiplicación de una matriz por un vector */

// Usaremos una matriz de 1024x1024
#define N 1024 
#define M 1024 

// El Kernel de CUDA: Multiplicación Matriz-Vector (Y = A * X)
__global__ void matVecMulKernel(float *A, float *X, float *Y) 
{
    // TODO: implementar lógica de multiplicación matriz-vector
    // Pista: calcular el índice global del hilo primero 
    // Para cada hilo, calcula un solo elemento de Y, recorriendo toda una fila de A (N columnas)
    // Recuerda que A está en formato 1D, así que A[i][j] se accede como A[i * N + j]
    // ...
}

int main() 
{
    size_t sizeA = (size_t)M * N * sizeof(float);
    size_t sizeVec = (size_t)N * sizeof(float);
    size_t sizeRes = (size_t)M * sizeof(float);
    
    // Punteros del Host (CPU)
    float *h_A, *h_X, *h_Y;

    // Punteros del Device (GPU)
    float *d_A, *d_X, *d_Y;

    // Asignar e inicializar Host memory
    h_A = (float*)malloc(sizeA);
    h_X = (float*)malloc(sizeVec);
    h_Y = (float*)malloc(sizeRes);

    // Inicializar: A con 1.0f y X con 2.0f
    for (int i = 0; i < M * N; i++) h_A[i] = 1.0f;
    for (int i = 0; i < N; i++) h_X[i] = 2.0f;

    // TODO: Asignar memoria en el Device (GPU) para d_A, d_X, d_Y
    // TODO: Copiar datos del Host al Device (CPU -> GPU)

    // Configuración de la ejecución del Kernel
    // Solo necesitamos lanzar M hilos (uno por cada fila/elemento de Y)
    int threadsPerBlock = 256;
    int numBlocks = (M + threadsPerBlock - 1) / threadsPerBlock; 

    // TODO: Lanzar el Kernel matVecMulKernel y sincronizar
    // TODO: Copiar resultados del Device al Host (GPU -> CPU)

    // Verificación
    int errors = 0;
    // Cálculo esperado: Y[i] = Suma(A[i][j] * X[j]) para j=0 a N-1
    // Como A[i][j]=1.0f y X[j]=2.0f, el resultado es N * (1.0f * 2.0f)
    float expected = (float)N * 2.0f; 
    
    for (int i = 0; i < M; i++) 
    {
        // Usamos una pequeña tolerancia para la comparación de punto flotante
        if (fabs(h_Y[i] - expected) > 1e-5) 
        {
            errors++;
        }
    }

    if (errors == 0) {
        std::cout << "✅ ¡Verificación exitosa! El resultado (" << expected << ") es correcto para todos los elementos." << std::endl;
    } else {
        std::cout << "❌ ¡Verificación fallida! Se encontraron " << errors << " errores." << std::endl;
    }
    
    // Liberar memoria del Host
    free(h_A);
    free(h_X);
    free(h_Y);

    // TODO: Liberar memoria del Device (d_A, d_X, d_Y)

    return 0;
}