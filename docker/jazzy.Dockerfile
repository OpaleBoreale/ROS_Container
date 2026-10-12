# syntax=docker/dockerfile:1.7
# ROS 2 Jazzy (LTS, Ubuntu 24.04) — native arm64 for Apple Silicon Macs
# TurtleBot3 + Gazebo Harmonic + Nav2 + Cartographer + AutoRace, RViz/rqt
# Desktop served in the browser through noVNC: http://localhost:6080/vnc.html
# Build context is the repo root (see docker-compose.yml)
FROM --platform=linux/arm64 ros:jazzy-ros-base

ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=jazzy

# Keep downloaded .deb files in a BuildKit cache and retry failed downloads,
# so an interrupted `make build` resumes instead of starting over
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
    && printf 'Acquire::Retries "10";\nAcquire::http::Timeout "60";\n' > /etc/apt/apt.conf.d/80-retries

# 1/4 — ROS desktop (RViz2, rqt, turtlesim, demos) + Gazebo Harmonic and its ROS bridge
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        ros-jazzy-desktop \
        ros-jazzy-ros-gz

# 2/4 — TurtleBot3, SLAM (Cartographer, slam_toolbox), navigation (Nav2)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        ros-jazzy-turtlebot3 \
        ros-jazzy-turtlebot3-msgs \
        ros-jazzy-turtlebot3-gazebo \
        ros-jazzy-dynamixel-sdk \
        ros-jazzy-teleop-twist-keyboard \
        ros-jazzy-cartographer \
        ros-jazzy-cartographer-ros \
        ros-jazzy-slam-toolbox \
        ros-jazzy-navigation2 \
        ros-jazzy-nav2-bringup

# 3/4 — AutoRace (camera, image processing, calibration) + build tools
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        ros-jazzy-image-transport \
        ros-jazzy-image-transport-plugins \
        ros-jazzy-cv-bridge \
        ros-jazzy-vision-opencv \
        ros-jazzy-image-pipeline \
        ros-jazzy-camera-calibration \
        ros-jazzy-rqt-image-view \
        ros-jazzy-rqt-reconfigure \
        python3-opencv python3-numpy \
        python3-colcon-common-extensions python3-rosdep python3-pip \
        python3-vcstool python3-argcomplete \
        build-essential cmake git gdb valgrind

# 4/4 — Desktop over VNC -> noVNC, and the shell tools used by the zshrc
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        xfce4 xfce4-terminal dbus-x11 \
        tigervnc-standalone-server novnc websockify \
        mesa-utils libgl1-mesa-dri \
        zsh vim less tree htop eza fzf procps openssh-client \
        iputils-ping net-tools curl ca-certificates locales \
    && (apt-get purge -y xfce4-screensaver light-locker || true) \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Starship prompt
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# zsh as default shell
RUN chsh -s /usr/bin/zsh root
ENV SHELL=/usr/bin/zsh

# Software rendering: Docker on macOS has no GPU passthrough
ENV DISPLAY=:1 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    QT_X11_NO_MITSHM=1

# Workspace
WORKDIR /ros2_ws
RUN mkdir -p /ros2_ws/src /root/maps

# Keep bash usable too, with ROS sourced
RUN cat >> /root/.bashrc <<'EOF'
source /opt/ros/jazzy/setup.bash
[ -f /ros2_ws/install/setup.bash ] && source /ros2_ws/install/setup.bash
EOF

COPY config/start-gui     /usr/local/bin/start-gui
RUN chmod +x /usr/local/bin/start-gui

# Dotfiles — kept last so editing them only rebuilds these layers
COPY config/zshrc         /root/.zshrc
COPY config/vimrc         /root/.vimrc
COPY config/starship.toml /root/.config/starship.toml

EXPOSE 6080

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["start-gui"]
