# syntax=docker/dockerfile:1.7
# ROS 1 Noetic (Ubuntu 20.04) — native arm64 for Apple Silicon Macs
# TurtleBot3 + Gazebo 11 + RViz + SLAM + Navigation + AutoRace 2020
# GUI served in the browser through noVNC: http://localhost:6080/vnc.html
FROM --platform=linux/arm64 ros:noetic-ros-base

ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=noetic

RUN apt-get update && apt-get install -y --no-install-recommends \
        # ROS desktop: Gazebo 11, gazebo_ros, RViz, rqt
        ros-noetic-desktop-full \
        # TurtleBot3 (bringup, teleop, slam, navigation, description, gazebo, fake)
        ros-noetic-turtlebot3 \
        ros-noetic-turtlebot3-msgs \
        ros-noetic-turtlebot3-simulations \
        ros-noetic-dynamixel-sdk \
        ros-noetic-teleop-twist-keyboard \
        # SLAM & navigation
        ros-noetic-gmapping \
        ros-noetic-slam-gmapping \
        ros-noetic-navigation \
        ros-noetic-map-server \
        ros-noetic-amcl \
        ros-noetic-move-base \
        ros-noetic-dwa-local-planner \
        # AutoRace 2020 (camera, image processing, calibration)
        ros-noetic-image-transport \
        ros-noetic-image-transport-plugins \
        ros-noetic-cv-bridge \
        ros-noetic-vision-opencv \
        ros-noetic-image-proc \
        ros-noetic-camera-calibration \
        ros-noetic-topic-tools \
        python3-opencv libopencv-dev python3-numpy \
        # AutoRace nodes start with `#!/usr/bin/env python`
        python-is-python3 \
        # Build & debug tooling
        python3-pip python3-rosdep python3-vcstool python3-catkin-tools \
        build-essential cmake git gdb valgrind \
        # Lightweight desktop over VNC -> noVNC in the browser
        xfce4 xfce4-terminal dbus-x11 \
        tigervnc-standalone-server novnc websockify \
        mesa-utils libgl1-mesa-dri \
        # Shell & CLI tools used by the zshrc
        zsh vim less tree htop fzf procps openssh-client \
        iputils-ping net-tools curl ca-certificates locales \
    && (apt-get purge -y xfce4-screensaver light-locker || true) \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# AutoRace sign detection calls cv2.SIFT_create(), which needs OpenCV >= 4.4
# (Ubuntu 20.04 ships 4.2). The pip build takes precedence over the apt one for Python only.
RUN pip3 install --no-cache-dir "opencv-contrib-python-headless==4.5.5.64" "numpy>=1.19.3,<1.25"

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# eza is not packaged for Ubuntu 20.04: use the upstream static-ish binary
RUN curl -fsSL https://github.com/eza-community/eza/releases/latest/download/eza_aarch64-unknown-linux-gnu.tar.gz \
        | tar xz -C /usr/local/bin \
    || echo "eza download failed, aliases will fall back to ls"

# Starship prompt
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- -y

# zsh as default shell
RUN chsh -s /usr/bin/zsh root
ENV SHELL=/usr/bin/zsh

# Software rendering: Docker on macOS has no GPU passthrough
ENV DISPLAY=:1 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    QT_X11_NO_MITSHM=1

# catkin workspace (same path as in the class guides: ~/catkin_ws)
WORKDIR /root/catkin_ws
RUN mkdir -p /root/catkin_ws/src /root/maps

# Keep bash usable too, with ROS sourced
RUN cat >> /root/.bashrc <<'EOF'
source /opt/ros/noetic/setup.bash
[ -f /root/catkin_ws/devel/setup.bash ] && source /root/catkin_ws/devel/setup.bash
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
