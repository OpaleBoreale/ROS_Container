<div align="center">

# 🤖 ROS_Container

**A headless ROS 2 Jazzy development container for Apple Silicon Macs**

![ROS 2](https://img.shields.io/badge/ROS_2-Jazzy-22314E?logo=ros&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?logo=ubuntu&logoColor=white)
![Arch](https://img.shields.io/badge/arch-arm64-993955)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![Shell](https://img.shields.io/badge/shell-zsh_+_Starship-1B998B)

</div>

---

## ✨ Features

- **Native arm64.** Runs on M-series chips without Rosetta emulation, so builds stay fast.
- **ROS 2 Jazzy (LTS)** on Ubuntu 24.04, with `colcon`, `rosdep`, `vcstool` and the demo nodes.
- **Live workspace.** Edit your packages on the Mac in `ros2_ws/src`, then build and run them inside the container.
- **Comfortable shell.** zsh, a custom Starship prompt, Vim, `eza`, `fzf`, `htop`, `gdb` and `valgrind`.
- **One-word commands.** A Makefile wraps every Docker and colcon command.
- **Persistent history.** Shell history survives container rebuilds.

## 📋 Requirements

| Tool | Notes |
|------|-------|
| macOS on Apple Silicon | M1 / M2 / M3 / M4 |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | or [OrbStack](https://orbstack.dev/) |
| `make` | ships with Xcode Command Line Tools (`xcode-select --install`) |
| A [Nerd Font](https://www.nerdfonts.com/) *(optional)* | needed for the prompt's powerline glyphs, e.g. `brew install --cask font-jetbrains-mono-nerd-font` |

## 🚀 Quick start

```bash
git clone git@github.com:mferracc/ROS_Container.git
cd ROS_Container

make build    # build the image (~5 min the first time)
make up       # start the container in the background
make shell    # open zsh inside, with ROS already sourced
```

To check that everything works, open two terminals:

```bash
make talker     # terminal 1: C++ publisher
make listener   # terminal 2: Python subscriber
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
| `make logs` | Follow container logs |
| `make status` | Show container status |

### Workspace

| Command | Description |
|---------|-------------|
| `make rosdep` | Install the dependencies of every package in `src/` |
| `make ws-build` | `colcon build --symlink-install` |
| `make ws-build PKG=my_pkg` | Build a single package |
| `make ws-test` | Run tests and show results (`PKG=` works too) |
| `make ws-clean` | Delete `build/`, `install/` and `log/` |
| `make run CMD='ros2 topic list'` | Run any command inside the container |

### Cleanup

| Command | Description |
|---------|-------------|
| `make rebuild` | Rebuild the image from scratch, without cache |
| `make clean` | Remove the container and the image (your code is kept) |
| `make prune` | Free up the Docker build cache |

## 📦 Working on a package

```bash
make shell
cd /ros2_ws/src
ros2 pkg create my_pkg --build-type ament_cmake --dependencies rclcpp std_msgs
cb            # build the workspace
sw            # source the overlay
ros2 run my_pkg <node>
```

`ros2_ws/src` is mounted from your Mac. Your code lives in this repo, so you can use any editor on the host. Build artifacts stay in the container's workspace and are ignored by Git.

## 🐚 Shell shortcuts

These come from `config/zshrc`:

| Alias | Command |
|-------|---------|
| `ws` | `cd /ros2_ws` |
| `cb` | `colcon build --symlink-install` |
| `cbp <pkg>` | build a single package |
| `ct` | `colcon test` + results |
| `sw` | source `install/setup.zsh` |
| `rtl` / `rnl` | `ros2 topic list` / `ros2 node list` |
| `gs` `ga` `gc` `gp` `gl` | Git status / add / commit / push / log graph |
| `l` `ll` `lt` | `eza` listings / tree view |

Tab completion works for `ros2` and `colcon`. The shell uses vi keybindings, `Ctrl-R` opens fzf history search, and ↑/↓ searches history by prefix.

## 🎨 Customization

Everything lives in `config/` and is copied into the image:

```
config/
├── zshrc           # shell options, aliases, ROS sourcing
├── starship.toml   # prompt
└── vimrc           # editor
```

After editing a file, run `make build restart`. The dotfiles are copied in the image's last layers, so this only takes a few seconds.

The prompt uses this [coolors](https://coolors.co/993955-ffd166-080357-1b998b-f8f1ff) palette:

| Wine | Yellow | Navy | Teal | White |
|:----:|:------:|:----:|:----:|:-----:|
| `#993955` | `#FFD166` | `#080357` | `#1B998B` | `#F8F1FF` |

## 📁 Project structure

```
ROS_Container/
├── Dockerfile          # ROS 2 Jazzy arm64 image
├── docker-compose.yml  # container config, mounts, volumes
├── Makefile            # command shortcuts
├── config/             # dotfiles
└── ros2_ws/
    └── src/            # your ROS 2 packages
```

## ⚠️ Limitations on macOS

- **No GUI.** The image is headless, so RViz and rqt aren't included.
- **No host networking.** Docker Desktop doesn't support `network_mode: host`, so DDS discovery with robots or other machines on your LAN won't work out of the box. Nodes inside the container communicate normally.
- **No USB passthrough.** Serial devices like `/dev/ttyUSB0` can't be passed through to the container on macOS.

## 🧰 Editor integration

- **VS Code:** use the *Dev Containers* extension's **Attach to Running Container…** to get IntelliSense and debugging inside the container.
- **CLion:** generate a compilation database inside the container, then open the workspace in CLion:

  ```bash
  colcon build --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  ```
