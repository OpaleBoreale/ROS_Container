#!/usr/bin/env python3
"""Shortcut for: ros2 launch tb3_worlds sim.launch.py world:=circuit [model:=... x_pose:=... y_pose:=... gui:=...]"""
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration

ARGS = ('model', 'x_pose', 'y_pose', 'gui', 'use_sim_time')
DEFAULTS = {'gui': 'true', 'use_sim_time': 'true'}


def generate_launch_description():
    sim = os.path.join(get_package_share_directory('tb3_worlds'), 'launch', 'sim.launch.py')
    forwarded = {name: LaunchConfiguration(name) for name in ARGS}
    forwarded['world'] = 'circuit'
    return LaunchDescription(
        [DeclareLaunchArgument(name, default_value=DEFAULTS.get(name, '')) for name in ARGS]
        + [IncludeLaunchDescription(PythonLaunchDescriptionSource(sim),
                                    launch_arguments=forwarded.items())]
    )
