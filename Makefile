# ROS 2 Jazzy dev container for Apple Silicon — TurtleBot3 + Gazebo, desktop in the browser
# Usage: make help

COMPOSE := docker compose
SERVICE := ros
WS      := /ros2_ws
EXEC    := $(COMPOSE) exec -e NO_WELCOME=1 $(SERVICE) zsh -ic
NOVNC   := http://localhost:6080/vnc.html

# AutoRace (lane / sign / traffic-light detection), cloned by `make tb3-setup`
AUTORACE_REPO := https://github.com/ROBOTIS-GIT/turtlebot3_autorace.git
AUTORACE_DIR  := ros2_ws/src/turtlebot3_autorace

PKG ?=
CMD ?=
MAP ?= map

.DEFAULT_GOAL := help
.NOTPARALLEL:            # targets must run in order, even with `make -j`
.PHONY: help init build up down restart shell gui logs status \
        rosdep ws-build ws-clean ws-test run talker listener turtlesim \
        tb3-setup tb3-world tb3-house tb3-circuit tb3-autorace tb3-teleop \
        tb3-slam tb3-savemap tb3-nav \
        rebuild clean prune

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets:\n"} \
	/^## -/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 4) } \
	/^[a-zA-Z0-9_-]+:.*##/ { printf "  \033[36m%-13s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf "\nVariables: PKG=<package>  CMD='<command>'  MAP=<name>\n\n"

## ---------- Container ----------

init: ## Create the local folders
	@mkdir -p ros2_ws/src maps

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

talker: up ## Demo: C++ talker
	$(EXEC) "ros2 run demo_nodes_cpp talker"

listener: up ## Demo: Python listener
	$(EXEC) "ros2 run demo_nodes_py listener"

turtlesim: up ## Turtlesim window
	$(EXEC) "ros2 run turtlesim turtlesim_node"

## ---------- TurtleBot3 ----------

tb3-setup: up ## Clone AutoRace and build the workspace (tracks included)
	@test -d $(AUTORACE_DIR) || git clone --depth 1 -b jazzy $(AUTORACE_REPO) $(AUTORACE_DIR)
	$(EXEC) "cd $(WS) && colcon build --symlink-install"

tb3-world: up ## Gazebo: TurtleBot3 World
	$(EXEC) "ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py"

tb3-house: up ## Gazebo: TurtleBot3 House
	$(EXEC) "ros2 launch turtlebot3_gazebo turtlebot3_house.launch.py"

tb3-circuit: up ## Gazebo: competition circuit
	$(EXEC) "ros2 launch tb3_worlds circuit.launch.py"

tb3-autorace: up ## Gazebo: AutoRace 2020 track
	$(EXEC) "ros2 launch tb3_worlds autorace_2020.launch.py"

tb3-teleop: up ## Keyboard teleoperation (w a s d x)
	$(EXEC) "TURTLEBOT3_MODEL=burger ros2 run turtlebot3_teleop teleop_keyboard"

tb3-slam: up ## SLAM with Cartographer + RViz
	$(EXEC) "ros2 launch turtlebot3_cartographer cartographer.launch.py use_sim_time:=True"

tb3-savemap: up ## Save the current map to maps/<MAP>.yaml
	$(EXEC) "ros2 run nav2_map_server map_saver_cli -f /root/maps/$(MAP)"

tb3-nav: up ## Nav2 + RViz with maps/<MAP>.yaml
	$(EXEC) "ros2 launch turtlebot3_navigation2 navigation2.launch.py use_sim_time:=True map:=/root/maps/$(MAP).yaml"

## ---------- Cleanup ----------

rebuild: ## Rebuild the image from scratch and restart
	$(COMPOSE) down
	$(COMPOSE) build --no-cache
	$(COMPOSE) up -d

clean: ## Remove container, image and build volumes (keeps your code)
	$(COMPOSE) down --rmi local --volumes

prune: ## Reclaim Docker build cache space
	docker builder prune -f
