# ROS dev containers for Apple Silicon
#   ROS=noetic (default) : ROS 1 + TurtleBot3 + Gazebo, desktop in the browser
#   ROS=jazzy            : ROS 2, headless
# Usage: make help   |   make shell ROS=jazzy

ROS     ?= noetic
COMPOSE := docker compose
SERVICE := $(ROS)
EXEC    := $(COMPOSE) exec -e NO_WELCOME=1 $(SERVICE) zsh -ic
NOVNC   := http://localhost:6080/vnc.html

ifeq ($(ROS),noetic)
  WS_HOST := catkin_ws
  WS      := /root/catkin_ws
else ifeq ($(ROS),jazzy)
  WS_HOST := ros2_ws
  WS      := /ros2_ws
else
  $(error ROS must be 'noetic' or 'jazzy')
endif

# Class repositories (cloned into catkin_ws/src by `make tb3-setup`)
COMP_REPO     := https://github.com/wafaesebbata/Turtlebot-simulation-for-Upper-Rhine-Robotic-Challenge.git
COMP_DIR      := catkin_ws/src/urrc_simulation
AUTORACE_REPO := https://github.com/ROBOTIS-GIT/turtlebot3_autorace_2020.git
AUTORACE_DIR  := catkin_ws/src/turtlebot3_autorace_2020

PKG ?=
CMD ?=
MAP ?= map

.DEFAULT_GOAL := help
.NOTPARALLEL:            # targets must run in order, even with `make -j`
.PHONY: help init build up down restart shell gui logs status \
        rosdep ws-build ws-clean run talker listener \
        tb3-setup tb3-world tb3-circuit tb3-teleop tb3-slam tb3-savemap tb3-nav tb3-autorace \
        rebuild clean prune noetic-only

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets (ROS=$(ROS)):\n"} \
	/^## -/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 4) } \
	/^[a-zA-Z0-9_-]+:.*##/ { printf "  \033[36m%-13s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf "\nVariables: ROS=noetic|jazzy  PKG=<package>  CMD='<command>'  MAP=<name>\n\n"

## ---------- Container ----------

init: ## Create the local workspace folders
	@mkdir -p $(WS_HOST)/src maps

build: init ## Build the image
	$(COMPOSE) build $(SERVICE)

up: init ## Start the container in the background
	$(COMPOSE) up -d $(SERVICE)
	@[ "$(ROS)" = noetic ] && echo "Desktop: $(NOVNC)" || true

down: ## Stop and remove the containers
	$(COMPOSE) down

restart: down up ## Restart the container

shell: up ## Open a zsh shell with ROS sourced
	$(COMPOSE) exec $(SERVICE) zsh

gui: noetic-only up ## Open the desktop (Gazebo, RViz) in your browser
	@open "$(NOVNC)"

logs: ## Follow container logs
	$(COMPOSE) logs -f $(SERVICE)

status: ## Show container status
	$(COMPOSE) ps

## ---------- Workspace ----------

rosdep: up ## Install the dependencies of packages in src/
	$(EXEC) "apt-get update && rosdep update && rosdep install --from-paths $(WS)/src --ignore-src -r -y"

ws-build: up ## Build the workspace (PKG=name for one package)
ifeq ($(ROS),noetic)
	$(EXEC) "cd $(WS) && catkin_make $(if $(PKG),--pkg $(PKG),)"
else
	$(EXEC) "cd $(WS) && colcon build --symlink-install $(if $(PKG),--packages-select $(PKG),)"
endif

ws-clean: up ## Delete build artifacts
ifeq ($(ROS),noetic)
	$(EXEC) "rm -rf $(WS)/build/* $(WS)/devel/*"
else
	$(EXEC) "rm -rf $(WS)/build $(WS)/install $(WS)/log"
endif

run: up ## Run a command: make run CMD='rostopic list'
	@test -n "$(CMD)" || (echo "Usage: make run CMD='rostopic list'"; exit 1)
	$(EXEC) "$(CMD)"

talker: up ## Demo publisher
ifeq ($(ROS),noetic)
	$(EXEC) "rosrun rospy_tutorials talker"
else
	$(EXEC) "ros2 run demo_nodes_cpp talker"
endif

listener: up ## Demo subscriber
ifeq ($(ROS),noetic)
	$(EXEC) "rosrun rospy_tutorials listener"
else
	$(EXEC) "ros2 run demo_nodes_py listener"
endif

## ---------- TurtleBot3 (ROS=noetic) ----------

tb3-setup: noetic-only up ## Clone the competition simulation + AutoRace and build
	@test -d $(COMP_DIR) || git clone --depth 1 $(COMP_REPO) $(COMP_DIR)
	@test -d $(AUTORACE_DIR) || git clone --depth 1 -b noetic-devel $(AUTORACE_REPO) $(AUTORACE_DIR)
	$(EXEC) "cd $(WS) && catkin_make"

tb3-world: noetic-only up ## Gazebo: TurtleBot3 World
	$(EXEC) "roslaunch turtlebot3_gazebo turtlebot3_world.launch"

tb3-circuit: noetic-only up ## Gazebo: competition circuit
	$(EXEC) "roslaunch turtlebot3_gazebo turtlebot3_circuit_competition.launch"

tb3-teleop: noetic-only up ## Keyboard teleoperation (w a s d x)
	$(EXEC) "roslaunch turtlebot3_teleop turtlebot3_teleop_key.launch"

tb3-slam: noetic-only up ## SLAM with gmapping + RViz
	$(EXEC) "roslaunch turtlebot3_slam turtlebot3_slam.launch slam_methods:=gmapping"

tb3-savemap: noetic-only up ## Save the current map to maps/<MAP>.yaml
	$(EXEC) "rosrun map_server map_saver -f /root/maps/$(MAP)"

tb3-nav: noetic-only up ## Navigation + RViz with maps/<MAP>.yaml
	$(EXEC) "roslaunch turtlebot3_navigation turtlebot3_navigation.launch map_file:=/root/maps/$(MAP).yaml"

tb3-autorace: noetic-only up ## Gazebo: AutoRace 2020 track
	$(EXEC) "roslaunch turtlebot3_gazebo turtlebot3_autorace_2020.launch"

noetic-only:
	@[ "$(ROS)" = noetic ] || (echo "This target needs ROS=noetic"; exit 1)

## ---------- Cleanup ----------

rebuild: ## Rebuild the image from scratch and restart
	$(COMPOSE) down
	$(COMPOSE) build --no-cache $(SERVICE)
	$(COMPOSE) up -d $(SERVICE)

clean: ## Remove containers, images and build volumes (keeps your code)
	$(COMPOSE) down --rmi local --volumes

prune: ## Reclaim Docker build cache space
	docker builder prune -f
