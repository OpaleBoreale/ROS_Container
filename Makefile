# ROS 2 Jazzy dev container (headless) — Apple Silicon
# Usage: make help

COMPOSE := docker compose
SERVICE := ros
WS      := /ros2_ws
EXEC    := $(COMPOSE) exec -e NO_WELCOME=1 $(SERVICE) zsh -ic

PKG ?=
CMD ?=

.DEFAULT_GOAL := help
.PHONY: help init build up down restart shell logs status \
        ws-build ws-clean ws-test rosdep run talker listener \
        rebuild clean prune

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nTargets:\n"} \
	/^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf "\nVariables: PKG=<package> (ws-build, ws-test), CMD='<command>' (run)\n\n"

## ---------- Container ----------

init: ## Create the local workspace folder
	@mkdir -p ros2_ws/src

build: init ## Build the image
	$(COMPOSE) build

up: init ## Start the container in the background
	$(COMPOSE) up -d

down: ## Stop and remove the container
	$(COMPOSE) down

restart: down up ## Restart the container

shell: up ## Open a shell with ROS sourced
	$(COMPOSE) exec $(SERVICE) zsh

logs: ## Follow container logs
	$(COMPOSE) logs -f $(SERVICE)

status: ## Show container status
	$(COMPOSE) ps

## ---------- Workspace ----------

rosdep: up ## Install dependencies of packages in src/
	$(EXEC) "apt-get update && rosdep update && rosdep install --from-paths src --ignore-src -y"

ws-build: up ## colcon build (PKG=name to build one package)
	$(EXEC) "cd $(WS) && colcon build --symlink-install $(if $(PKG),--packages-select $(PKG),)"

ws-test: up ## colcon test (PKG=name to test one package)
	$(EXEC) "cd $(WS) && colcon test $(if $(PKG),--packages-select $(PKG),) && colcon test-result --verbose"

ws-clean: up ## Remove build/ install/ log/
	$(EXEC) "rm -rf $(WS)/build $(WS)/install $(WS)/log"

run: up ## Run a command in the container: make run CMD='ros2 topic list'
	@test -n "$(CMD)" || (echo "Usage: make run CMD='ros2 topic list'"; exit 1)
	$(EXEC) "$(CMD)"

talker: up ## Demo: C++ talker
	$(EXEC) "ros2 run demo_nodes_cpp talker"

listener: up ## Demo: Python listener
	$(EXEC) "ros2 run demo_nodes_py listener"

## ---------- Cleanup ----------

rebuild: ## Rebuild the image from scratch and restart
	$(COMPOSE) down
	$(COMPOSE) build --no-cache
	$(COMPOSE) up -d

clean: ## Remove container and image (keeps ros2_ws/src)
	$(COMPOSE) down --rmi local

prune: ## Reclaim Docker build cache space
	docker builder prune -f
