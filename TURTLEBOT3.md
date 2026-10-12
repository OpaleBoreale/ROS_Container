# 🐢 TurtleBot3 — sujets de cours dans le container

Ce guide reprend le *Guide TurtleBot* (RobotHub Académie) et le *Tutorial simulation TurtleBot ROS1 Noetic*, section par section, avec les commandes à taper dans le container `noetic`.

Tout se passe sur ton Mac : pas besoin de machine virtuelle Ubuntu. Le container est déjà en **Ubuntu 20.04 + ROS Noetic**, la version demandée par les deux sujets.

> **Ouvrir plusieurs terminaux.** Les guides disent « ouvre un nouveau terminal avec Ctrl+Alt+T ». Ici, ouvre un nouvel onglet dans ton terminal Mac (⌘T) et tape `make shell`. Chaque onglet est un shell dans le même container, avec ROS déjà sourcé et `TURTLEBOT3_MODEL=burger` déjà défini.

> **Fenêtres graphiques.** Gazebo, RViz et rqt s'affichent dans le bureau du navigateur : `make gui` ou http://localhost:6080/vnc.html, puis *Connect*.

---

## 0. Première installation (une seule fois)

```bash
make build       # ~20-30 min la première fois (ROS desktop-full + Gazebo)
make up
make tb3-setup   # clone la simulation de la compétition + AutoRace 2020, puis catkin_make
```

`make tb3-setup` place deux dépôts dans `catkin_ws/src/` :

| Dossier | Contenu |
|---------|---------|
| `urrc_simulation/` | dépôt de la compétition (*Upper Rhine Robotic Challenge*) : `turtlebot3_gazebo` avec le circuit, `turtlebot3_world`, AutoRace… |
| `turtlebot3_autorace_2020/` | détection de lignes, panneaux, missions (partie 5 et 6) |

> Le *Guide TurtleBot* (4.1) demande de cloner `ROBOTIS-GIT/turtlebot3_simulations`. **Ne le fais pas** : le dépôt de la compétition en est une copie qui contient déjà les mêmes paquets, et deux paquets du même nom dans un workspace font échouer `catkin_make`.

---

## Tutorial simulation (compétition)

**1.1 / 1.2 : environnement et workspace** → déjà fait par `make build` et `make tb3-setup`.

**Lancer le terrain de la compétition :**

```bash
make tb3-circuit          # ou, dans un shell : tb3-circuit
```

> Le PDF écrit `TURTLEBOT3_MODEL=buger` : c'est une coquille, la bonne valeur est `burger` (déjà définie dans le container).

**Voir les capteurs dans RViz** (caméra, lidar), dans un deuxième onglet :

```bash
make shell
rviz        # Add → By topic → /camera/image (Image), /scan (LaserScan)
```

---

## Guide TurtleBot

### 1. Setup

| Section | Dans le container |
|---------|-------------------|
| 1.1 PC Setup | Déjà fait : l'image contient ROS Noetic et les paquets TurtleBot3. Le guide indique Ubuntu 22.04 mais Noetic tourne sur **20.04**, comme le container. |
| 1.2 Raspberry Setup | Se fait sur la carte SD du robot, pas sur le Mac. |
| 1.3 OpenCR Setup | Se fait **depuis le Raspberry Pi** en SSH (`ssh ubuntu@<IP_DU_ROBOT>`), ça marche directement depuis le terminal du Mac. |

### 2. Bringup et 3. Teleoperation (robot réel)

Voir [Robot réel](#-robot-réel) plus bas.

### 4. Simulation avec Gazebo

**4.1 Premier lancement**

```bash
make tb3-world      # onglet 1 : Gazebo, TurtleBot3 World
make tb3-teleop     # onglet 2 : pilotage au clavier
```

Les touches sont `w` `a` `s` `d` `x` (le guide parle de ZQSD, mais ce sont bien les lettres w/a/s/d/x qui comptent, même sur un clavier AZERTY). Le terminal du teleop doit avoir le focus.

**Importer le circuit du guide (`.world`, `.launch`, dossier `Circuit`)** : copie les fichiers fournis dans
`catkin_ws/src/urrc_simulation/turtlebot3_gazebo/` (sous-dossiers `worlds/`, `launch/`, `models/`) depuis le Finder, puis :

```bash
make ws-build
make run CMD='roslaunch turtlebot3_gazebo Circuit.launch'
```

> Le dépôt de la compétition contient déjà `worlds/Circuit.world` et `models/Circuit`, via `make tb3-circuit`.

**4.2 SLAM**

```bash
make tb3-world      # onglet 1
make tb3-slam       # onglet 2 : gmapping + RViz
make tb3-teleop     # onglet 3 : explore la zone
make tb3-savemap    # onglet 4 : enregistre maps/map.pgm + maps/map.yaml
```

La carte est sauvegardée dans le dossier `maps/` du dépôt, donc visible sur ton Mac. Pour un autre nom : `make tb3-savemap MAP=circuit`.

> Le guide utilise `map_saver -f ~/map`. Dans le container, utilise `~/maps/map` : c'est le dossier partagé avec le Mac, alors que `~/map` disparaît quand le container est recréé.

**4.3 Navigation**

```bash
make tb3-world      # onglet 1
make tb3-nav        # onglet 2 : AMCL + move_base + RViz (MAP=circuit pour une autre carte)
```

Dans RViz : **2D Pose Estimate** pour placer le robot, `make tb3-teleop` pour affiner la localisation puis **Ctrl+C**, et enfin **2D Nav Goal**.

### 5. Autonomous Driving (AutoRace 2020)

Les paquets du guide (`image-transport`, `cv-bridge`, `vision-opencv`, `image-proc`, OpenCV…) sont déjà installés, et AutoRace est cloné par `make tb3-setup`. Commandes de la [doc ROBOTIS Noetic](https://emanual.robotis.com/docs/en/platform/turtlebot3/autonomous_driving/#autonomous-driving), en simulation :

```bash
make tb3-autorace   # onglet 1 : piste AutoRace dans Gazebo

# onglet 2 : calibration intrinsèque (en simulation, elle charge le fichier fourni)
make run CMD='roslaunch turtlebot3_autorace_camera intrinsic_camera_calibration.launch'

# onglet 3 : calibration extrinsèque, puis réglages dans rqt
make run CMD='roslaunch turtlebot3_autorace_camera extrinsic_camera_calibration.launch mode:=calibration'
make run CMD='rqt'   # Plugins → Configuration → Dynamic Reconfigure / Visualization → Image View
```

**5.2 Détection de ligne puis conduite :**

```bash
make run CMD='roslaunch turtlebot3_autorace_camera extrinsic_camera_calibration.launch'   # mode action
make run CMD='roslaunch turtlebot3_autorace_detect detect_lane.launch mode:=calibration'  # réglage des seuils
make run CMD='roslaunch turtlebot3_autorace_driving turtlebot3_autorace_control_lane.launch'
```

**Panneaux :** `roslaunch turtlebot3_autorace_detect detect_sign.launch mission:=intersection` (ou `construction`, `parking`, `level_crossing`, `tunnel`).

### 6. Missions

Après la piste et les calibrations :

```bash
make run CMD='roslaunch turtlebot3_autorace_detect detect_traffic_light.launch'
make run CMD='roslaunch turtlebot3_autorace_core turtlebot3_autorace_core.launch mission:=traffic_light'
```

`mission:=` accepte `traffic_light`, `intersection`, `construction`, `parking`, `level_crossing`, `tunnel`. Les commandes complètes de chaque mission sont sur la [page ROBOTIS](https://emanual.robotis.com/docs/en/platform/turtlebot3/autonomous_driving/#traffic-lights).

---

## 🤖 Robot réel

ROS 1 a besoin que le robot et le PC puissent **s'ouvrir des connexions dans les deux sens**. Docker Desktop sur macOS isole le container dans une VM, donc le robot ne peut pas joindre les nodes du container par défaut.

**Ce qui marche à coup sûr : tout faire sur le robot, en SSH depuis le Mac.**

```bash
# Onglet 1
ssh ubuntu@<IP_DU_ROBOT>
roscore

# Onglet 2
ssh ubuntu@<IP_DU_ROBOT>
export TURTLEBOT3_MODEL=burger
roslaunch turtlebot3_bringup turtlebot3_robot.launch

# Onglet 3 : téléopération, lancée sur le robot lui-même
ssh ubuntu@<IP_DU_ROBOT>
export TURTLEBOT3_MODEL=burger
roslaunch turtlebot3_teleop turtlebot3_teleop_key.launch
```

Sur le robot, `ROS_MASTER_URI` doit pointer vers lui-même (`http://localhost:11311`) dans `~/.bashrc`.

**SLAM ou RViz avec le vrai robot** : ces outils doivent tourner côté PC, avec un réseau où le robot peut joindre le container. Deux options :

- **Docker Desktop ≥ 4.34** : *Settings → Resources → Network → Enable host networking*, puis ajouter `network_mode: host` au service `noetic` (et retirer `ports:`). C'est une fonctionnalité encore récente, à tester sur le réseau de la salle.
- Utiliser un PC Linux de la salle pour ces étapes.

---

## Raccourcis disponibles dans `make shell`

| Raccourci | Commande |
|-----------|----------|
| `tb3-world` / `tb3-circuit` | Gazebo : TurtleBot3 World / circuit de la compétition |
| `tb3-teleop` | téléopération clavier |
| `tb3-slam` | SLAM gmapping + RViz |
| `tb3-savemap` | sauvegarde la carte dans `~/maps/map` |
| `tb3-nav [nom]` | navigation avec `~/maps/<nom>.yaml` |
| `cb` / `cbp <pkg>` | `catkin_make` (tout / un paquet) puis source |
| `sw` | source `devel/setup.zsh` |
| `rtl` / `rnl` | `rostopic list` / `rosnode list` |

## Performances

Docker sur Mac n'a pas d'accès au GPU : Gazebo et RViz tournent en rendu logiciel. C'est fluide pour TurtleBot3 World, plus lent sur le circuit et AutoRace. Si Gazebo rame :

- donne plus de CPU et de RAM à Docker (*Settings → Resources*), au moins 6 cœurs et 8 Go ;
- réduis la taille du bureau : `VNC_GEOMETRY` dans `docker-compose.yml` (par exemple `1280x720`) ;
- ferme la fenêtre de Gazebo (`gui:=false` quand le launch le permet) et garde seulement RViz.
