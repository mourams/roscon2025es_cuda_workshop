from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        Node(
            package='cuda_ros_demos',
            executable='cuda_sobel_node',
            name='cuda_sobel_node',
            output='screen',
            parameters=[
                {'edge_threshold': 75.0}  # Ajusta el umbral según sea necesario
            ],
            remappings=[
                ('/camera/image_raw', '/robot/front_camera/color/image_raw'),
                ('/camera/image_edges', '/robot/front_camera/image_edges/gpu')
            ]
        )
    ])