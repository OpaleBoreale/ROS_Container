# tb3_worlds

TurtleBot3 tracks for the new Gazebo (gz sim) on ROS 2 Jazzy:

| Launch | World |
|--------|-------|
| `ros2 launch tb3_worlds circuit.launch.py` | Upper Rhine Robotic Challenge competition circuit |
| `ros2 launch tb3_worlds autorace_2020.launch.py` | ROBOTIS AutoRace 2020 track |

Add `gui:=false` to run without the Gazebo window. The robot is a TurtleBot3 Burger with a camera (`burger_cam`), spawned at the start line.

## Origin

Both worlds were made for Gazebo Classic (ROS 1) and converted with [`tools/port_worlds.py`](../../../tools/port_worlds.py):

- **Circuit:** [wafaesebbata/Turtlebot-simulation-for-Upper-Rhine-Robotic-Challenge](https://github.com/wafaesebbata/Turtlebot-simulation-for-Upper-Rhine-Robotic-Challenge) (Apache-2.0)
- **AutoRace 2020:** [ROBOTIS-GIT/turtlebot3_simulations](https://github.com/ROBOTIS-GIT/turtlebot3_simulations) (Apache-2.0)

The conversion replaces the OGRE material scripts with PBR textures and adds the gz sim system plugins. The traffic light and level-crossing bar of AutoRace were animated by Gazebo Classic plugins, which gz sim can't load, so they are static here.
