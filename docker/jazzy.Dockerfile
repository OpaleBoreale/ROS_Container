# syntax=docker/dockerfile:1.7
# ROS 2 Jazzy (LTS, Ubuntu 24.04) — headless, native arm64 for Apple Silicon Macs
# Build context is the repo root (see docker-compose.yml)
FROM --platform=linux/arm64 ros:jazzy-ros-base

ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=jazzy

RUN apt-get update && apt-get install -y --no-install-recommends \
        # Demo nodes for quick testing (talker / listener)
        ros-jazzy-demo-nodes-cpp \
        ros-jazzy-demo-nodes-py \
        # Build & debug tooling
        python3-colcon-common-extensions \
        python3-rosdep \
        python3-pip \
        python3-vcstool \
        python3-argcomplete \
        build-essential cmake git gdb valgrind \
        # Shell & CLI tools used by the zshrc
        zsh vim less tree htop eza fzf procps openssh-client \
        iputils-ping net-tools curl ca-certificates locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Starship prompt (official installer, puts the binary in /usr/local/bin)
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# zsh as default shell
RUN chsh -s /usr/bin/zsh root
ENV SHELL=/usr/bin/zsh

# Workspace
WORKDIR /ros2_ws
RUN mkdir -p /ros2_ws/src

# Keep bash usable too, with ROS sourced
RUN cat >> /root/.bashrc <<'EOF'
source /opt/ros/${ROS_DISTRO}/setup.bash
[ -f /ros2_ws/install/setup.bash ] && source /ros2_ws/install/setup.bash
EOF

# Dotfiles — kept last so editing them only rebuilds these layers
COPY config/zshrc         /root/.zshrc
COPY config/vimrc         /root/.vimrc
COPY config/starship.toml /root/.config/starship.toml

ENTRYPOINT ["/ros_entrypoint.sh"]
# Keep the container alive so you can `docker compose exec` into it
CMD ["sleep", "infinity"]
