# tb3_worlds

TurtleBot3 simulation for Gazebo (gz sim) on ROS 2 Jazzy.

```bash
ros2 launch tb3_worlds sim.launch.py world:=circuit          # or: make tb3-circuit
ros2 launch tb3_worlds sim.launch.py world:=autorace_2020    # or: make tb3-autorace
ros2 launch tb3_worlds sim.launch.py world:=turtlebot3_world # or: make tb3-world
```

| Argument | Default | |
|---|---|---|
| `world` | `turtlebot3_world` | `turtlebot3_world`, `turtlebot3_house`, `circuit`, `autorace_2020` |
| `model` | `$TURTLEBOT3_MODEL` | `burger`, `burger_cam`, `waffle`, `waffle_pi`. The tracks always use a camera model |
| `x_pose`, `y_pose` | per world | spawn position |
| `gui` | `true` | `false` runs Gazebo without its window (faster) |

## `cmd_vel` is a `Twist`

The TurtleBot3 packages for Jazzy bridge `/cmd_vel` as `geometry_msgs/TwistStamped`. Humble, the real robot, `turtlebot3_drive` and the AutoRace nodes use `geometry_msgs/Twist`. This package's bridge configs (`params/`) use `Twist`, so the same nodes drive the simulated robot and the real one. The Makefile's `tb3-teleop` and `tb3-nav` targets are set up for it.

## Tracks

Both tracks were made for Gazebo Classic and converted with [`tools/port_worlds.py`](../../../tools/port_worlds.py):

- **circuit:** from [wafaesebbata's TurtleBot3 simulation repository](https://github.com/wafaesebbata/Turtlebot-simulation-for-Upper-Rhine-Robotic-Challenge) (Apache-2.0). Signs placed: tunnel, right turn, construction, parking. The STOP sign and the checkerboard are commented out in the original world.
- **autorace_2020:** from [ROBOTIS-GIT/turtlebot3_simulations](https://github.com/ROBOTIS-GIT/turtlebot3_simulations) (Apache-2.0). It has the STOP sign and the checkerboard. The traffic light and level-crossing bar were animated by Gazebo Classic plugins, so they are static here.

To convert another Gazebo Classic world (for example a modified `turtlebot3_gazebo` package):

```bash
python3 tools/port_worlds.py --models <pkg>/models --model-name <ModelFolder> \
    --world <pkg>/worlds/<file>.world \
    --out-world ros2_ws/src/tb3_worlds/worlds/<name>.sdf --out-models ros2_ws/src/tb3_worlds/models
```

Then add `<name>` to the `WORLDS` table in `launch/sim.launch.py`.
