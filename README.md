# ROSCON 2025 España - CUDA Workshop

Este repositorio contiene el material del taller de CUDA para ROSCon 2025 España, enfocado en la aceleración GPU de procesamiento de imágenes en tiempo real con ROS 2.

## Estructura del Proyecto

### `cuda_ros_demos`
Paquete de ROS 2 que demuestra la integración de CUDA con ROS 2 para procesamiento de imágenes en tiempo real.
- Implementación de filtro Sobel para detección de bordes
- Comparación de rendimiento CPU vs GPU
- Nodos ROS 2 configurables para diferentes backends

**Archivos principales:**
- `src/cpu_sobel_node.cpp` - Nodo con implementación CPU
- `src/cuda_sobel_node.cpp` - Nodo con implementación CUDA
- `src/cpu_sobel_interface.cpp` - Interfaz de procesamiento CPU
- `src/cuda_sobel_interface.cu` - Interfaz de procesamiento CUDA
- `launch/` - Archivos de lanzamiento para ambos nodos

### `exercises`
Serie de ejercicios progresivos para aprender programación CUDA desde cero. Los mismos son ejecutados en el workshop con **Google Colab**.

1. **`01_simple_kernel.cu`** - Primer kernel: "Hola Mundo" desde la GPU
2. **`02_two_kernels.cu`** - Ejecución de múltiples kernels
3. **`03_device_struct.cu`** - Manejo de estructuras en device memory
4. **`04_device_properties.cu`** - Consulta de propiedades del dispositivo GPU
5. **`05_vector_sum.cu`** - Suma de vectores con paralelización
6. **`06_vector_inversion_shared.cu`** - Uso de memoria compartida
7. **`07_async_stream.cu`** - Streams asíncronos para operaciones concurrentes
8. **`08_activity.cu`** - Ejercicio de práctica

## Requisitos (para compilación en tu PC)

- **ROS 2 Humble**
- **CUDA Toolkit 11.8+**
- **OpenCV 4.x**
- **GPU compatible con CUDA**
- **CMake 3.16+**

## Compilación

### Paquete ROS 2
```bash
cd ~/ros2_ws/src
git clone https://github.com/mourams/roscon2025es_cuda_workshop.git
cd ~/ros2_ws
colcon build --packages-select cuda_ros_demos
source install/setup.bash
```

### Ejercicios CUDA
```bash
cd roscon2025es_cuda_workshop/exercises
nvcc -o 01_simple_kernel 01_simple_kernel.cu
./01_simple_kernel
```
Repite para cada ejercicio cambiando el nombre del archivo.

## Uso

### Ejecutar demo de procesamiento de imágenes

Necesitarás una cámara conectada o un archivo de video para probar los nodos.

**Nodo CPU:**
```bash
ros2 launch cuda_ros_demos cpu_sobel_node.launch.py
```

**Nodo CUDA:**
```bash
ros2 launch cuda_ros_demos cuda_sobel_node.launch.py
```

### Trabajar con los ejercicios
Cada archivo `.cu` en la carpeta `exercises/` puede compilarse y ejecutarse individualmente para explorar diferentes conceptos de CUDA.

## Objetivos del Taller

1. **Fundamentos de CUDA** - Comprender la arquitectura GPU y el modelo de programación CUDA
2. **Integración ROS 2** - Aprender a incorporar CUDA en nodos de ROS 2
3. **Optimización** - Técnicas de optimización para procesamiento en tiempo real
4. **Casos de uso prácticos** - Aplicaciones reales de CUDA en robótica

## Autor

**Mateus Sanches** - mateus.sanches@eurecat.org

## Licencia

Apache License 2.0


