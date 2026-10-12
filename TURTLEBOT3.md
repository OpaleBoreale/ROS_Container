# 🐢 TurtleBot3 sur ROS 2 Jazzy

Ce guide reprend le *Guide TurtleBot* (RobotHub Académie) et le *Tutorial simulation TurtleBot*, section par section, en version **ROS 2 Jazzy**.

Les deux sujets sont écrits pour ROS 1 Noetic, qui est en fin de vie depuis mai 2025. Les étapes restent les mêmes, seuls les outils changent :

| ROS 1 Noetic (sujets) | ROS 2 Jazzy (ici) |
|-----------------------|-------------------|
| `roscore` | plus nécessaire |
| `rosrun pkg node` / `roslaunch pkg x.launch` | `ros2 run pkg node` / `ros2 launch pkg x.launch.py` |
| `rostopic` / `rosnode` / `rosservice` | `ros2 topic` / `ros2 node` / `ros2 service` |
| `catkin_make` dans `~/catkin_ws` | `colcon build` dans `/ros2_ws` |
| Gazebo 11 (Classic) | Gazebo Harmonic (`gz sim`) |
| SLAM gmapping | Cartographer |
| Navigation `move_base` + AMCL | Nav2 |
| `map_server map_saver` | `nav2_map_server map_saver_cli` |

> **Ouvrir plusieurs terminaux.** Les guides disent « ouvre un nouveau terminal ». Ici, ouvre un nouvel onglet dans ton terminal Mac (⌘T) et tape `make shell`, ou utilise `make <cible>` directement. Chaque onglet est un shell dans le même container.

> **Fenêtres graphiques.** Gazebo, RViz et rqt s'affichent dans le bureau du navigateur : `make gui` ou http://localhost:6080/vnc.html, puis *Connect*.

---

## 0. Première installation (une seule fois)

```bash
make build       # ~15-20 min la première fois
make up
make tb3-setup   # clone AutoRace (Jazzy) et compile le workspace
```

Le workspace contient deux paquets :

| Paquet | Contenu |
|--------|---------|
| `tb3_worlds` (dans le dépôt) | le **circuit de la compétition** et la **piste AutoRace 2020**, convertis pour le nouveau Gazebo |
| `turtlebot3_autorace` (cloné) | détection de lignes, panneaux, feux, missions (ROBOTIS, branche `jazzy`) |

---

## Tutorial simulation (compétition)

**1.1 / 1.2 : environnement et workspace** → déjà fait par `make build` et `make tb3-setup`.

**Lancer le terrain de la compétition :**

```bash
make tb3-circuit
```

Le robot est un Burger équipé d'une caméra (`burger_cam`), placé sur la ligne de départ.

> Le circuit a été converti depuis la version ROS 1 du dépôt de la compétition (textures, panneaux, murs, obstacles). Si un élément manque ou a un rendu différent de la figure 1 du sujet, dis-le-moi.

**Voir les capteurs dans RViz**, dans un deuxième onglet :

```bash
make shell
rviz2       # Add → By topic → /camera/image_raw (Image), /scan (LaserScan)
```

Ou, pour la caméra seule : `ros2 run rqt_image_view rqt_image_view`.

---

## Guide TurtleBot

### 1. Setup

Le **1.1 PC Setup** est déjà fait par l'image. Les parties qui concernent le robot physique (1.2 Raspberry, 1.3 OpenCR, 2 Bringup, 3 Teleoperation sur le robot) sont laissées de côté : tout se fait en simulation ci-dessous.

### 4. Simulation avec Gazebo

**4.1 Premier lancement**

```bash
make tb3-world      # onglet 1 : Gazebo, TurtleBot3 World
make tb3-teleop     # onglet 2 : pilotage au clavier
```

Les touches sont `w` `a` `s` `d` `x`. Le terminal du teleop doit avoir le focus.

**4.2 SLAM** (Cartographer remplace gmapping)

```bash
make tb3-world      # onglet 1
make tb3-slam       # onglet 2 : Cartographer + RViz
make tb3-teleop     # onglet 3 : explore la zone
make tb3-savemap    # onglet 4 : enregistre maps/map.pgm + maps/map.yaml
```

La carte est sauvegardée dans le dossier `maps/` du dépôt, donc visible sur ton Mac. Pour un autre nom : `make tb3-savemap MAP=circuit`.

**4.3 Navigation** (Nav2 remplace `move_base`)

```bash
make tb3-world      # onglet 1
make tb3-nav        # onglet 2 : Nav2 + RViz (MAP=circuit pour une autre carte)
```

Dans RViz, le principe est le même que dans le guide : **2D Pose Estimate** pour placer le robot, puis **Nav2 Goal** (l'ancien *2D Nav Goal*).

> Pour la navigation sur le circuit, le robot est un `burger_cam` : lance `TURTLEBOT3_MODEL=burger_cam make tb3-nav MAP=circuit` pour que Nav2 utilise les bons paramètres.

### 5. Autonomous Driving (AutoRace)

Commandes de la [doc ROBOTIS](https://emanual.robotis.com/docs/en/platform/turtlebot3/autonomous_driving/), onglet **Jazzy**, en simulation. Chaque commande dans un onglet séparé :

```bash
make tb3-autorace   # piste AutoRace 2020 (ou make tb3-circuit)

# 5.1 Calibration de la caméra
make run CMD='ros2 launch turtlebot3_autorace_camera intrinsic_camera_calibration.launch.py'
make run CMD='ros2 launch turtlebot3_autorace_camera extrinsic_camera_calibration.launch.py calibration_mode:=True'
make run CMD='rqt'    # Plugins → Configuration → Dynamic Reconfigure, Visualization → Image View
```

**5.2 Détection de ligne puis conduite :**

```bash
make run CMD='ros2 launch turtlebot3_autorace_camera extrinsic_camera_calibration.launch.py'
make run CMD='ros2 launch turtlebot3_autorace_detect detect_lane.launch.py calibration_mode:=True'   # réglage des seuils
make run CMD='ros2 launch turtlebot3_autorace_mission control_lane.launch.py'
```

**Panneaux :** `ros2 launch turtlebot3_autorace_detect detect_sign.launch.py mission:=intersection` (ou `construction`, `parking`, `level_crossing`, `tunnel`).

### 6. Missions

```bash
make run CMD='ros2 launch turtlebot3_autorace_detect detect_traffic_light.launch.py'
make run CMD='ros2 launch turtlebot3_autorace_mission mission_construction.launch.py'
make run CMD='ros2 launch turtlebot3_autorace_mission mission_tunnel.launch.py'
```

> Dans le nouveau Gazebo, le **feu tricolore** et la **barrière du passage à niveau** de la piste AutoRace sont fixes : ils étaient animés par des plugins de l'ancien Gazebo, qui ne fonctionnent plus. Le feu reste rouge et la barrière reste en place.

---

## Turtlesim

```bash
make turtlesim                                   # onglet 1
make run CMD='ros2 run turtlesim turtle_teleop_key'   # onglet 2 : flèches du clavier
make run CMD="ros2 service call /spawn turtlesim/srv/Spawn \"{x: 2.0, y: 2.0, theta: 0.0, name: 'turtle2'}\""
```

---

## Raccourcis disponibles dans `make shell`

| Raccourci | Commande |
|-----------|----------|
| `tb3-world` / `tb3-house` | Gazebo : TurtleBot3 World / House |
| `tb3-circuit` / `tb3-autorace` | Gazebo : circuit de la compétition / piste AutoRace |
| `tb3-teleop` | téléopération clavier |
| `tb3-slam` | SLAM Cartographer + RViz |
| `tb3-savemap [nom]` | sauvegarde la carte dans `~/maps/<nom>` |
| `tb3-nav [nom]` | Nav2 avec `~/maps/<nom>.yaml` |
| `cb` / `cbp <pkg>` | `colcon build` (tout / un paquet) puis source |
| `sw` | source `install/setup.zsh` |
| `rtl` / `rnl` | `ros2 topic list` / `ros2 node list` |

## Performances

Docker sur Mac n'a pas d'accès au GPU : Gazebo et RViz tournent en rendu logiciel. Si Gazebo rame :

- donne plus de CPU et de RAM à Docker (*Settings → Resources*), au moins 6 cœurs et 8 Go ;
- lance la simulation sans fenêtre Gazebo et garde RViz : `make run CMD='ros2 launch tb3_worlds circuit.launch.py gui:=false'` ;
- réduis la taille du bureau : `VNC_GEOMETRY` dans `docker-compose.yml` (par exemple `1280x720`).
