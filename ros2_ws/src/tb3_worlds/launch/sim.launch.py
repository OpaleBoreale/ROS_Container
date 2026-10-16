#!/usr/bin/env python3
"""TurtleBot3 simulation in Gazebo (gz sim, ROS 2 Jazzy), with cmd_vel as geometry_msgs/Twist.

    ros2 launch tb3_worlds sim.launch.py world:=circuit
    ros2 launch tb3_worlds sim.launch.py world:=autorace_2020 gui:=false
    ros2 launch tb3_worlds sim.launch.py world:=turtlebot3_world model:=burger_cam
    ros2 launch tb3_worlds sim.launch.py world:=circuit x_pose:=-1.4 y_pose:=0.0

Worlds:
    turtlebot3_world, turtlebot3_house   from turtlebot3_gazebo
    circuit, autorace_2020               from this package (lane-following tracks)

Why this file instead of the turtlebot3_gazebo launch files: in Jazzy, ROBOTIS bridges
cmd_vel as TwistStamped, while Humble, the real robot, turtlebot3_drive and the AutoRace
nodes all use Twist. This launch uses the bridge configs of this package (params/),
which bridge cmd_vel as Twist, so the same nodes work in simulation and on the robot.
"""
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import (AppendEnvironmentVariable, DeclareLaunchArgument,
                            IncludeLaunchDescription, OpaqueFunction)
from launch.conditions import IfCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node

CAMERA_MODELS = ('burger_cam', 'waffle', 'waffle_pi')

# world name -> (package, world file, default x, default y, needs a camera)
WORLDS = {
    'turtlebot3_world': ('turtlebot3_gazebo', 'turtlebot3_world.world', '-2.0', '-0.5', False),
    'turtlebot3_house': ('turtlebot3_gazebo', 'turtlebot3_house.world', '-2.0', '-0.5', False),
    'circuit':          ('tb3_worlds', 'circuit.sdf', '0.8', '-1.747', True),
    'autorace_2020':    ('tb3_worlds', 'autorace_2020.sdf', '0.8', '-1.747', True),
}


def launch_setup(context):
    world_name = LaunchConfiguration('world').perform(context)
    if world_name not in WORLDS:
        raise RuntimeError(f"Unknown world '{world_name}'. Choose one of: {', '.join(WORLDS)}")
    pkg, world_file, default_x, default_y, needs_camera = WORLDS[world_name]

    # Robot model: model:=..., else TURTLEBOT3_MODEL, else burger.
    # The lane-following tracks need a camera, so burger becomes burger_cam there.
    model = LaunchConfiguration('model').perform(context) or os.environ.get('TURTLEBOT3_MODEL', 'burger')
    if needs_camera and model not in CAMERA_MODELS:
        model = 'burger_cam'
    # robot_state_publisher.launch.py of turtlebot3_gazebo reads this variable
    os.environ['TURTLEBOT3_MODEL'] = model

    x_pose = LaunchConfiguration('x_pose').perform(context) or default_x
    y_pose = LaunchConfiguration('y_pose').perform(context) or default_y
    gui = LaunchConfiguration('gui')
    use_sim_time = LaunchConfiguration('use_sim_time')

    tb3_gazebo = get_package_share_directory('turtlebot3_gazebo')
    here = get_package_share_directory('tb3_worlds')
    world = os.path.join(get_package_share_directory(pkg), 'worlds', world_file)
    gz_sim_launch = os.path.join(get_package_share_directory('ros_gz_sim'), 'launch', 'gz_sim.launch.py')

    actions = [
        # Models of this package (tracks, signs) and of turtlebot3_gazebo (robots, worlds)
        AppendEnvironmentVariable('GZ_SIM_RESOURCE_PATH', os.path.join(here, 'models')),
        AppendEnvironmentVariable('GZ_SIM_RESOURCE_PATH', os.path.join(tb3_gazebo, 'models')),

        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(gz_sim_launch),
            launch_arguments={'gz_args': ['-r -s -v2 ', world], 'on_exit_shutdown': 'true'}.items(),
        ),
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(gz_sim_launch),
            launch_arguments={'gz_args': '-g -v2 ', 'on_exit_shutdown': 'true'}.items(),
            condition=IfCondition(gui),
        ),
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(os.path.join(tb3_gazebo, 'launch', 'robot_state_publisher.launch.py')),
            launch_arguments={'use_sim_time': use_sim_time}.items(),
        ),

        # Spawn the robot
        Node(
            package='ros_gz_sim',
            executable='create',
            arguments=[
                '-name', model,
                '-file', os.path.join(tb3_gazebo, 'models', f'turtlebot3_{model}', 'model.sdf'),
                '-x', x_pose, '-y', y_pose, '-z', '0.01',
            ],
            output='screen',
        ),
        # ROS <-> Gazebo bridge (cmd_vel as Twist)
        Node(
            package='ros_gz_bridge',
            executable='parameter_bridge',
            arguments=['--ros-args', '-p',
                       f"config_file:={os.path.join(here, 'params', f'turtlebot3_{model}_bridge.yaml')}"],
            output='screen',
        ),
    ]
    if model in CAMERA_MODELS:
        actions.append(Node(
            package='ros_gz_image',
            executable='image_bridge',
            arguments=['/camera/image_raw'],
            output='screen',
        ))
    return actions


def generate_launch_description():
    return LaunchDescription([
        DeclareLaunchArgument('world', default_value='turtlebot3_world',
                              description=f"One of: {', '.join(WORLDS)}"),
        DeclareLaunchArgument('model', default_value='',
                              description='burger, burger_cam, waffle, waffle_pi (default: TURTLEBOT3_MODEL)'),
        DeclareLaunchArgument('x_pose', default_value='', description='Spawn x (default: per world)'),
        DeclareLaunchArgument('y_pose', default_value='', description='Spawn y (default: per world)'),
        DeclareLaunchArgument('gui', default_value='true', description='Open the Gazebo window'),
        DeclareLaunchArgument('use_sim_time', default_value='true'),
        OpaqueFunction(function=launch_setup),
    ])
