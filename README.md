<div align="center">

# 🤖 ROS_Container

**ROS development containers for Apple Silicon Macs**
ROS 1 Noetic with TurtleBot3 & Gazebo · ROS 2 Jazzy headless

![ROS 1](https://img.shields.io/badge/ROS_1-Noetic-22314E?logo=ros&logoColor=white)
![ROS 2](https://img.shields.io/badge/ROS_2-Jazzy-22314E?logo=ros&logoColor=white)
![Arch](https://img.shields.io/badge/arch-arm64-993955)
![Gazebo](https://img.shields.io/badge/Gazebo-11-FFD166)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![Shell](https://img.shields.io/badge/shell-zsh_+_Starship-1B998B)

</div>

---

## ✨ Features

- **Two containers, one Makefile.** `ROS=noetic` (default) or `ROS=jazzy` on any command.
- **Native arm64.** No Rosetta emulation, so builds stay fast.
- **Noetic for TurtleBot3.** Ubuntu 20.04, `desktop-full`, Gazebo 11, RViz, gmapping, navigation and AutoRace 2020, ready for the class labs. See **[TURTLEBOT3.md](TURTLEBOT3.md)**.
- **Desktop in the browser.** Gazebo and RViz run in an XFCE desktop served by noVNC. No XQuartz needed.
- **Jazzy, headless.** A light ROS 2 environment with `colcon` and the demo nodes.
- **Live workspaces.** Edit packages on the Mac in `catkin_ws/src` or `ros2_ws/src`, build inside the container.
- **Comfortable shell.** zsh, a custom Starship prompt, Vim, `eza`, `fzf`, `htop`, `gdb`, `valgrind`.

## 📋 Requirements

| Tool | Notes |
|------|-------|
| macOS on Apple Silicon | M1 / M2 / M3 / M4 |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | or [OrbStack](https://orbstack.dev/). Give it at least 6 CPUs and 8 GB of RAM for Gazebo |
| `make` | ships with Xcode Command Line Tools (`xcode-select --install`) |
| A [Nerd Font](https://www.nerdfonts.com/) *(optional)* | for the prompt's powerline glyphs, e.g. `brew install --cask font-jetbrains-mono-nerd-font` |

## 🚀 Quick start

```bash
git clone git@github.com:mferracc/ROS_Container.git
cd ROS_Container

make build       # ROS 1 Noetic image (~20-30 min the first time)
make up
make tb3-setup   # clone the TurtleBot3 class repos and build them
make gui         # open the desktop in your browser
make tb3-world   # TurtleBot3 World in Gazebo
```

For ROS 2, add `ROS=jazzy`:

```bash
make build ROS=jazzy
make shell ROS=jazzy
```

## 🛠️ Makefile commands

Run `make help` to see this list in your terminal. Every command accepts `ROS=noetic` (default) or `ROS=jazzy`.

### Container

| Command | Description |
|---------|-------------|
| `make build` | Build the image |
| `make up` | Start the container |
| `make down` | Stop and remove the containers |
| `make restart` | Restart the container |
| `make shell` | Open an interactive zsh shell |
| `make gui` | Open the desktop at http://localhost:6080/vnc.html (Noetic) |
| `make logs` / `make status` | Logs / container status |

### Workspace

| Command | Description |
|---------|-------------|
| `make rosdep` | Install the dependencies of every package in `src/` |
| `make ws-build` | `catkin_make` (Noetic) or `colcon build` (Jazzy) |
| `make ws-build PKG=my_pkg` | Build a single package |
| `make ws-clean` | Delete build artifacts |
| `make run CMD='rostopic list'` | Run any command inside the container |
| `make talker` / `make listener` | Demo publisher / subscriber |

### TurtleBot3 (Noetic)

| Command | Description |
|---------|-------------|
| `make tb3-setup` | Clone the competition simulation and AutoRace 2020, then build |
| `make tb3-world` | Gazebo: TurtleBot3 World |
| `make tb3-circuit` | Gazebo: competition circuit |
| `make tb3-autorace` | Gazebo: AutoRace 2020 track |
| `make tb3-teleop` | Keyboard teleoperation |
| `make tb3-slam` | SLAM with gmapping + RViz |
| `make tb3-savemap MAP=name` | Save the map to `maps/name.yaml` |
| `make tb3-nav MAP=name` | Navigation with `maps/name.yaml` |

Each launch command runs in the foreground, so use one terminal tab per command.

### Cleanup

| Command | Description |
|---------|-------------|
| `make rebuild` | Rebuild the image from scratch, without cache |
| `make clean` | Remove containers, images and build volumes (your code is kept) |
| `make prune` | Free up the Docker build cache |

## 🐚 Shell shortcuts

These come from `config/zshrc` and adapt to the ROS version:

| Alias | Noetic | Jazzy |
|-------|--------|-------|
| `ws` | `cd ~/catkin_ws` | `cd /ros2_ws` |
| `cb` | `catkin_make` + source | `colcon build --symlink-install` |
| `cbp <pkg>` | build one package | build one package |
| `sw` | source `devel/setup.zsh` | source `install/setup.zsh` |
| `rtl` / `rnl` | `rostopic` / `rosnode list` | `ros2 topic` / `ros2 node list` |
| `tb3-*` | TurtleBot3 launches (see [TURTLEBOT3.md](TURTLEBOT3.md)) | — |

Git aliases (`gs` `ga` `gc` `gp` `gl`) and `eza` listings (`l` `ll` `lt`) work in both. The shell uses vi keybindings, `Ctrl-R` opens fzf history search, and ↑/↓ searches history by prefix.

## 🎨 Customization

```
config/
├── zshrc           # shell options, aliases, ROS sourcing (Noetic and Jazzy)
├── starship.toml   # prompt
├── vimrc           # editor
└── start-gui       # VNC + noVNC desktop launcher (Noetic)
```

After editing a file, run `make build restart`. The dotfiles are copied in the image's last layers, so this only takes a few seconds.

The prompt uses this [coolors](https://coolors.co/993955-ffd166-080357-1b998b-f8f1ff) palette:

| Wine | Yellow | Navy | Teal | White |
|:----:|:------:|:----:|:----:|:-----:|
| `#993955` | `#FFD166` | `#080357` | `#1B998B` | `#F8F1FF` |

## 📁 Project structure

```
ROS_Container/
├── docker/
│   ├── noetic.Dockerfile   # ROS 1 + TurtleBot3 + Gazebo + noVNC desktop
│   └── jazzy.Dockerfile    # ROS 2, headless
├── docker-compose.yml      # both services, mounts, volumes
├── Makefile                # command shortcuts
├── config/                 # dotfiles + desktop launcher
├── catkin_ws/src/          # ROS 1 packages
├── ros2_ws/src/            # ROS 2 packages
├── maps/                   # maps saved by map_saver
└── TURTLEBOT3.md           # class labs, step by step (in French)
```

## ⚠️ Limitations on macOS

- **No GPU.** Gazebo and RViz use software rendering. TurtleBot3 World is smooth; the circuit and AutoRace tracks are slower.
- **No host networking by default.** A real robot can't reach nodes inside the container, which ROS 1 needs. [TURTLEBOT3.md](TURTLEBOT3.md#-robot-réel) explains the workarounds.
- **No USB passthrough.** Serial devices like `/dev/ttyUSB0` can't be passed to the container. Flash the OpenCR from the robot's Raspberry Pi instead.

## 🧰 Editor integration

- **VS Code:** use the *Dev Containers* extension's **Attach to Running Container…** for IntelliSense and debugging inside the container.
- **CLion:** generate a compilation database inside the container, then open the workspace in CLion:

  ```bash
  catkin_make -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                       # Noetic
  colcon build --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON         # Jazzy
  ```
