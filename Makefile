# ROS 2 Jazzy dev container for Apple Silicon — TurtleBot3 + Gazebo, desktop in the browser
# Usage: make help
#
# Every simulated robot here uses geometry_msgs/Twist on /cmd_vel (like Humble, the real
# robot, turtlebot3_drive and AutoRace). See ros2_ws/src/tb3_worlds/README.md.

COMPOSE := docker compose
SERVICE := ros
WS      := /ros2_ws
EXEC    := $(COMPOSE) exec -e NO_WELCOME=1 $(SERVICE) zsh -ic
NOVNC   := http://localhost:6080/vnc.html

# AutoRace (lane / sign / traffic-light detection), cloned by `make tb3-setup`
AUTORACE_REPO := https://github.com/ROBOTIS-GIT/turtlebot3_autorace.git
AUTORACE_DIR  := ros2_ws/src/turtlebot3_autorace

# ---------- Variables ----------
PKG     ?=
CMD     ?=
MAP     ?= map
TOPIC   ?= /camera/image_raw
# Simulation: MODEL=burger_cam, X=-1.4 Y=0.0 (spawn position), GUI=false (no Gazebo window)
MODEL   ?=
X       ?=
Y       ?=
GUI     ?=
# AutoRace: CALIB=True opens the calibration mode, MISSION for detect_sign
CALIB   ?= False
MISSION ?= intersection
# Camera calibration on the real robot: inner corners of the board, square size in meters
BOARD   ?= 8x6
SQUARE  ?= 0.024
# Rosbags, saved in share/bags on the Mac
BAG        ?=
BAG_TOPICS ?= /camera/image_raw /camera/camera_info /odom /scan /cmd_vel /tf /tf_static

SIM_ARGS := $(if $(MODEL),model:=$(MODEL)) $(if $(X),x_pose:=$(X)) $(if $(Y),y_pose:=$(Y)) $(if $(GUI),gui:=$(GUI))
SIM      := ros2 launch tb3_worlds sim.launch.py

.DEFAULT_GOAL := help
.NOTPARALLEL:            # targets must run in order, even with `make -j`
.PHONY: help init build up down restart shell gui logs status \
        rosdep ws-build ws-clean ws-test run \
        rviz rqt graph camera \
        talker listener turtlesim turtlesim-teleop tf-demo tf-frames tf-tree \
        tb3-setup tb3-world tb3-house tb3-circuit tb3-autorace tb3-teleop tb3-drive \
        tb3-slam tb3-savemap tb3-nav \
        calib ar-intrinsic ar-extrinsic ar-lane ar-sign ar-light ar-drive \
        bag-record bag-play bag-list \
        rebuild clean prune

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets:\n"} \
	/^## -/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 4) } \
	/^[a-zA-Z0-9_-]+:.*##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf "\nVariables: PKG CMD MAP TOPIC MODEL X Y GUI CALIB MISSION BOARD SQUARE BAG BAG_TOPICS (see the top of the Makefile)\n\n"

## ---------- Container ----------

init:
	@mkdir -p ros2_ws/src maps share/bags

build: init ## Build the image
	$(COMPOSE) build

up: init ## Start the container in the background
	$(COMPOSE) up -d
	@echo "Desktop: $(NOVNC)"

down: ## Stop and remove the container
	$(COMPOSE) down

restart: down up ## Restart the container

shell: up ## Open a zsh shell with ROS sourced
	$(COMPOSE) exec $(SERVICE) zsh

gui: up ## Open the desktop (Gazebo, RViz, rqt) in your browser
	@open "$(NOVNC)"

logs: ## Follow container logs
	$(COMPOSE) logs -f $(SERVICE)

status: ## Show container status
	$(COMPOSE) ps

## ---------- Workspace ----------

rosdep: up ## Install the dependencies of packages in src/
	$(EXEC) "apt-get update && rosdep update && rosdep install --from-paths $(WS)/src --ignore-src -r -y"

ws-build: up ## colcon build (PKG=name for one package)
	$(EXEC) "cd $(WS) && colcon build --symlink-install $(if $(PKG),--packages-select $(PKG),)"

ws-test: up ## colcon test (PKG=name for one package)
	$(EXEC) "cd $(WS) && colcon test $(if $(PKG),--packages-select $(PKG),) && colcon test-result --verbose"

ws-clean: up ## Delete build artifacts
	$(EXEC) "rm -rf $(WS)/build/* $(WS)/install/* $(WS)/log/*"

run: up ## Run a command: make run CMD='ros2 topic list'
	@test -n "$(CMD)" || (echo "Usage: make run CMD='ros2 topic list'"; exit 1)
	$(EXEC) "$(CMD)"

## ---------- GUI tools ----------

rviz: up ## RViz2
	$(EXEC) "rviz2"

rqt: up ## rqt (add tools from the Plugins menu)
	$(EXEC) "rqt"

graph: up ## Node graph (rqt_graph)
	$(EXEC) "rqt_graph"

camera: up ## Image viewer on TOPIC (default /camera/image_raw)
	$(EXEC) "ros2 run rqt_image_view rqt_image_view $(TOPIC)"

## ---------- Tutorials ----------

talker: up ## Demo: C++ talker
	$(EXEC) "ros2 run demo_nodes_cpp talker"

listener: up ## Demo: Python listener
	$(EXEC) "ros2 run demo_nodes_py listener"

turtlesim: up ## Turtlesim window
	$(EXEC) "ros2 run turtlesim turtlesim_node"

turtlesim-teleop: up ## Drive the turtlesim turtle with the arrow keys
	$(EXEC) "ros2 run turtlesim turtle_teleop_key"

tf-demo: up ## TF2 tutorial: turtle2 follows turtle1
	$(EXEC) "ros2 launch turtle_tf2_py turtle_tf2_demo.launch.py"

tf-frames: up ## Export the TF tree to share/frames_*.pdf
	$(EXEC) "cd /root/share && ros2 run tf2_tools view_frames"

tf-tree: up ## Live TF tree (rqt_tf_tree)
	$(EXEC) "ros2 run rqt_tf_tree rqt_tf_tree"

## ---------- TurtleBot3 simulation ----------

tb3-setup: up ## Clone AutoRace and build the workspace (tb3_worlds included)
	@test -d ros2_ws/src/tb3_worlds || (echo "ros2_ws/src/tb3_worlds is missing"; exit 1)
	@test -d $(AUTORACE_DIR) || git clone --depth 1 -b jazzy $(AUTORACE_REPO) $(AUTORACE_DIR)
	$(EXEC) "cd $(WS) && colcon build --symlink-install"

tb3-world: up ## Gazebo: TurtleBot3 World
	$(EXEC) "$(SIM) world:=turtlebot3_world $(SIM_ARGS)"

tb3-house: up ## Gazebo: TurtleBot3 House
	$(EXEC) "$(SIM) world:=turtlebot3_house $(SIM_ARGS)"

tb3-circuit: up ## Gazebo: lane-following circuit (burger_cam)
	$(EXEC) "$(SIM) world:=circuit $(SIM_ARGS)"

tb3-autorace: up ## Gazebo: AutoRace 2020 track, with STOP sign and checkerboard (burger_cam)
	$(EXEC) "$(SIM) world:=autorace_2020 $(SIM_ARGS)"

# ROS_DISTRO=humble makes the TurtleBot3 teleop publish Twist instead of TwistStamped
tb3-teleop: up ## Keyboard teleoperation (w a s d x)
	$(EXEC) "ROS_DISTRO=humble TURTLEBOT3_MODEL=burger ros2 run turtlebot3_teleop teleop_keyboard"

tb3-drive: up ## Lidar obstacle avoidance demo (turtlebot3_drive)
	$(EXEC) "ros2 run turtlebot3_gazebo turtlebot3_drive"

tb3-slam: up ## SLAM with Cartographer + RViz
	$(EXEC) "ros2 launch turtlebot3_cartographer cartographer.launch.py use_sim_time:=True"

tb3-savemap: up ## Save the current map to maps/<MAP>.yaml
	$(EXEC) "ros2 run nav2_map_server map_saver_cli -f /root/maps/$(MAP)"

# Nav2 parameters of the robot model, with cmd_vel switched to Twist
tb3-nav: up ## Nav2 + RViz with maps/<MAP>.yaml (MODEL=burger_cam on the tracks)
	$(EXEC) "m=$(or $(MODEL),\$${TURTLEBOT3_MODEL:-burger}); \
	         sed 's/enable_stamped_cmd_vel: true/enable_stamped_cmd_vel: false/' \
	             \$$(ros2 pkg prefix --share turtlebot3_navigation2)/param/\$$m.yaml > /tmp/nav2_twist.yaml && \
	         TURTLEBOT3_MODEL=\$$m ros2 launch turtlebot3_navigation2 navigation2.launch.py \
	             use_sim_time:=True map:=/root/maps/$(MAP).yaml params_file:=/tmp/nav2_twist.yaml"

## ---------- Vision / AutoRace (run a track first) ----------

calib: up ## Real camera: intrinsic calibration (BOARD=8x6 SQUARE=0.024 TOPIC=...)
	$(EXEC) "ros2 run camera_calibration cameracalibrator --size $(BOARD) --square $(SQUARE) \
	         --ros-args -r image:=$(TOPIC) -p camera:=/camera"

ar-intrinsic: up ## AutoRace: intrinsic calibration / image rectification
	$(EXEC) "ros2 launch turtlebot3_autorace_camera intrinsic_camera_calibration.launch.py"

ar-extrinsic: up ## AutoRace: bird's-eye projection (CALIB=True to tune it in rqt)
	$(EXEC) "ros2 launch turtlebot3_autorace_camera extrinsic_camera_calibration.launch.py calibration_mode:=$(CALIB)"

ar-lane: up ## AutoRace: lane detection (CALIB=True to tune the thresholds)
	$(EXEC) "ros2 launch turtlebot3_autorace_detect detect_lane.launch.py calibration_mode:=$(CALIB)"

ar-sign: up ## AutoRace: sign detection (MISSION=intersection|construction|parking|level_crossing|tunnel)
	$(EXEC) "ros2 launch turtlebot3_autorace_detect detect_sign.launch.py mission:=$(MISSION)"

ar-light: up ## AutoRace: traffic light detection
	$(EXEC) "ros2 launch turtlebot3_autorace_detect detect_traffic_light.launch.py"

ar-drive: up ## AutoRace: lane following (needs ar-intrinsic, ar-extrinsic, ar-lane)
	$(EXEC) "ros2 launch turtlebot3_autorace_mission control_lane.launch.py"

## ---------- Rosbag (share/bags on the Mac) ----------

bag-record: up ## Record BAG_TOPICS to share/bags/<BAG> (default: date and time)
	$(EXEC) "cd /root/share/bags && ros2 bag record -o $(or $(BAG),bag_\$$(date +%Y%m%d_%H%M%S)) $(BAG_TOPICS)"

bag-play: up ## Replay share/bags/<BAG> in a loop
	@test -n "$(BAG)" || (echo "Usage: make bag-play BAG=<name>  (see make bag-list)"; exit 1)
	$(EXEC) "ros2 bag play /root/share/bags/$(BAG) --loop"

bag-list: up ## List the recorded bags
	$(EXEC) "ls -1 /root/share/bags"

## ---------- Cleanup ----------

rebuild: ## Rebuild the image from scratch and restart
	$(COMPOSE) down
	$(COMPOSE) build --no-cache
	$(COMPOSE) up -d

clean: ## Remove container, image and build volumes (keeps your code)
	$(COMPOSE) down --rmi local --volumes

prune: ## Reclaim Docker build cache space
	docker builder prune -f
