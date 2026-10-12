#!/usr/bin/env python3
"""ROBOTIS AutoRace 2020 track in Gazebo (gz sim) with a TurtleBot3 Burger + camera.

    ros2 launch tb3_worlds autorace_2020.launch.py            # with the Gazebo window
    ros2 launch tb3_worlds autorace_2020.launch.py gui:=false # simulation only (faster)
"""
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import AppendEnvironmentVariable, DeclareLaunchArgument, IncludeLaunchDescription
from launch.conditions import IfCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration

WORLD = 'autorace_2020.sdf'
SPAWN_X, SPAWN_Y = '0.8', '-1.747'
CAMERA_MODELS = ('burger_cam', 'waffle', 'waffle_pi')


def generate_launch_description():
    # The tracks are made for camera-based lane following: use the Burger with a camera
    if os.environ.get('TURTLEBOT3_MODEL') not in CAMERA_MODELS:
        os.environ['TURTLEBOT3_MODEL'] = 'burger_cam'

    pkg = get_package_share_directory('tb3_worlds')
    tb3_gazebo = get_package_share_directory('turtlebot3_gazebo')
    tb3_launch = os.path.join(tb3_gazebo, 'launch')
    gz_sim_launch = os.path.join(get_package_share_directory('ros_gz_sim'), 'launch', 'gz_sim.launch.py')

    gui = LaunchConfiguration('gui')
    use_sim_time = LaunchConfiguration('use_sim_time')
    x_pose = LaunchConfiguration('x_pose')
    y_pose = LaunchConfiguration('y_pose')

    return LaunchDescription([
        DeclareLaunchArgument('gui', default_value='true', description='Open the Gazebo window'),
        DeclareLaunchArgument('use_sim_time', default_value='true'),
        DeclareLaunchArgument('x_pose', default_value=SPAWN_X),
        DeclareLaunchArgument('y_pose', default_value=SPAWN_Y),

        # Our models first, then the TurtleBot3 robot models
        AppendEnvironmentVariable('GZ_SIM_RESOURCE_PATH', os.path.join(pkg, 'models')),
        AppendEnvironmentVariable('GZ_SIM_RESOURCE_PATH', os.path.join(tb3_gazebo, 'models')),

        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(gz_sim_launch),
            launch_arguments={
                'gz_args': ['-r -s -v2 ', os.path.join(pkg, 'worlds', WORLD)],
                'on_exit_shutdown': 'true',
            }.items(),
        ),
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(gz_sim_launch),
            launch_arguments={'gz_args': '-g -v2 ', 'on_exit_shutdown': 'true'}.items(),
            condition=IfCondition(gui),
        ),
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(os.path.join(tb3_launch, 'robot_state_publisher.launch.py')),
            launch_arguments={'use_sim_time': use_sim_time}.items(),
        ),
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(os.path.join(tb3_launch, 'spawn_turtlebot3.launch.py')),
            launch_arguments={'x_pose': x_pose, 'y_pose': y_pose}.items(),
        ),
    ])
