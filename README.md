<div align="center">

# 🤖 ROS_Container

**A ROS 2 Jazzy development container for Apple Silicon Macs**
TurtleBot3 · Gazebo Harmonic · Nav2 · Cartographer · desktop in the browser

![ROS 2](https://img.shields.io/badge/ROS_2-Jazzy-22314E?logo=ros&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white)
![Arch](https://img.shields.io/badge/arch-arm64-993955)
![Gazebo](https://img.shields.io/badge/Gazebo-Harmonic-FFD166)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![Shell](https://img.shields.io/badge/shell-zsh_+_Starship-1B998B)

</div>

---

## ✨ Features

- **Native arm64.** Runs on M-series chips without Rosetta emulation.
- **ROS 2 Jazzy (LTS)** on Ubuntu 24.04, supported until 2029.
- **TurtleBot3 ready.** Gazebo Harmonic, Cartographer, Nav2, AutoRace, RViz and rqt. The class labs are in **[TURTLEBOT3.md](TURTLEBOT3.md)**.
- **Competition tracks.** The Upper Rhine Robotic Challenge circuit and the AutoRace 2020 track, ported to the new Gazebo (`tb3_worlds` package).
- **Desktop in the browser.** Gazebo, RViz and rqt run in an XFCE desktop served by noVNC. No XQuartz needed.
- **Live workspace.** Edit packages on the Mac in `ros2_ws/src`, build inside the container.
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

make build       # ~15-20 min the first time
make up
make tb3-setup   # clone AutoRace and build the workspace
make gui         # open the desktop in your browser
make tb3-world   # TurtleBot3 World in Gazebo
```

## 🛠️ Makefile commands

Run `make help` to see this list in your terminal.

### Container

| Command | Description |
|---------|-------------|
| `make build` | Build the image |
| `make up` | Start the container |
| `make down` | Stop and remove the container |
| `make restart` | Restart the container |
| `make shell` | Open an interactive zsh shell |
| `make gui` | Open the desktop at http://localhost:6080/vnc.html |
| `make logs` / `make status` | Logs / container status |

### Workspace

| Command | Description |
|---------|-------------|
| `make rosdep` | Install the dependencies of every package in `src/` |
| `make ws-build` | `colcon build --symlink-install` |
| `make ws-build PKG=my_pkg` | Build a single package |
| `make ws-test` | Run tests and show results (`PKG=` works too) |
| `make ws-clean` | Delete build artifacts |
| `make run CMD='ros2 topic list'` | Run any command inside the container |
| `make talker` / `make listener` / `make turtlesim` | Demos |

### TurtleBot3

| Command | Description |
|---------|-------------|
| `make tb3-setup` | Clone AutoRace and build the workspace |
| `make tb3-world` / `make tb3-house` | Gazebo: TurtleBot3 World / House |
| `make tb3-circuit` | Gazebo: competition circuit |
| `make tb3-autorace` | Gazebo: AutoRace 2020 track |
| `make tb3-teleop` | Keyboard teleoperation |
| `make tb3-slam` | SLAM with Cartographer + RViz |
| `make tb3-savemap MAP=name` | Save the map to `maps/name.yaml` |
| `make tb3-nav MAP=name` | Nav2 with `maps/name.yaml` |

Each launch command runs in the foreground, so use one terminal tab per command.

### Cleanup

| Command | Description |
|---------|-------------|
| `make rebuild` | Rebuild the image from scratch, without cache |
| `make clean` | Remove the container, image and build volumes (your code is kept) |
| `make prune` | Free up the Docker build cache |

## 🐚 Shell shortcuts

These come from `config/zshrc`:

| Alias | Command |
|-------|---------|
| `ws` | `cd /ros2_ws` |
| `cb` / `cbp <pkg>` | `colcon build` (all / one package), then source |
| `sw` | source `install/setup.zsh` |
| `ct` | `colcon test` + results |
| `rtl` / `rnl` | `ros2 topic list` / `ros2 node list` |
| `tb3-*` | TurtleBot3 launches (see [TURTLEBOT3.md](TURTLEBOT3.md)) |
| `gs` `ga` `gc` `gp` `gl` | Git status / add / commit / push / log graph |
| `l` `ll` `lt` | `eza` listings / tree view |

Tab completion works for `ros2` and `colcon`. The shell uses vi keybindings, `Ctrl-R` opens fzf history search, and ↑/↓ searches history by prefix.

## 🎨 Customization

```
config/
├── zshrc           # shell options, aliases, ROS sourcing
├── starship.toml   # prompt
├── vimrc           # editor
└── start-gui       # VNC + noVNC desktop launcher
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
│   └── jazzy.Dockerfile    # ROS 2 Jazzy + TurtleBot3 + Gazebo + noVNC desktop
├── docker-compose.yml      # container config, mounts, volumes
├── Makefile                # command shortcuts
├── config/                 # dotfiles + desktop launcher
├── tools/
│   └── port_worlds.py      # Gazebo Classic -> gz sim world converter
├── ros2_ws/src/
│   └── tb3_worlds/         # competition circuit + AutoRace track
├── maps/                   # maps saved by map_saver
└── TURTLEBOT3.md           # class labs, step by step (in French)
```

## ⚠️ Limitations on macOS

- **No GPU.** Gazebo and RViz use software rendering. Run Gazebo with `gui:=false` and keep only RViz if it's slow.
- **Simulation only.** Docker Desktop has no host networking by default, so a real robot can't reach nodes inside the container.
- **No USB passthrough.** Serial devices like `/dev/ttyUSB0` can't be passed to the container.

## 🧰 Editor integration

- **VS Code:** use the *Dev Containers* extension's **Attach to Running Container…** for IntelliSense and debugging inside the container.
- **CLion:** generate a compilation database inside the container, then open the workspace in CLion:

  ```bash
  colcon build --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  ```
