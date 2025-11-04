cmake_minimum_required(VERSION 3.16)
project(cuda_ros_demos LANGUAGES CXX CUDA)

# Paquetes necesarios
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(cv_bridge REQUIRED)
find_package(OpenCV REQUIRED)

# Includes
include_directories(
  include
  ${OpenCV_INCLUDE_DIRS}
)

# CUDA 
find_package(CUDA REQUIRED)
set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -O3 ") # Optimización
set(CMAKE_CUDA_ARCHITECTURES 87) # Ajustar CC para Jetson Orin Nano

# Biblioteca CUDA
add_library(cuda_sobel_lib src/cuda_sobel_interface.cu)
set_target_properties(cuda_sobel_lib PROPERTIES CUDA_SEPARABLE_COMPILATION ON)

# Nodo ROS2
add_executable(cpu_sobel_node src/cpu_sobel_node.cpp src/cpu_sobel_interface.cpp)
target_link_libraries(cpu_sobel_node ${OpenCV_LIBS})
ament_target_dependencies(cpu_sobel_node rclcpp sensor_msgs cv_bridge)

add_executable(cuda_sobel_node src/cuda_sobel_node.cpp)
target_link_libraries(cuda_sobel_node cuda_sobel_lib ${OpenCV_LIBS})
ament_target_dependencies(cuda_sobel_node rclcpp sensor_msgs cv_bridge)


# Instalación
install(TARGETS cuda_sobel_node cpu_sobel_node
  DESTINATION lib/${PROJECT_NAME}
)
install(DIRECTORY include/
  DESTINATION include/
)

install(DIRECTORY launch
  DESTINATION share/${PROJECT_NAME}/
)

ament_package()
