#!/usr/bin/env python3
"""
Port Gazebo Classic (ROS 1) worlds and models to the new Gazebo (gz sim, ROS 2 Jazzy).

What it changes:
  * OGRE material scripts (<material><script>...</script>) become PBR materials
    with an albedo texture, or a plain color for the built-in Gazebo/* materials;
  * Gazebo Classic plugins (lib*.so) are removed: they cannot run in gz sim;
  * the world gets the gz sim system plugins (physics, sensors, scene...),
    and its <state>, <gui> and old <physics> blocks are dropped;
  * broken XML comments (`--!>`) and absolute mesh paths are cleaned up.

Usage:
  port_worlds.py --models SRC_MODELS_DIR --model-name NAME \
                 --world SRC_WORLD --out-world OUT_WORLD --out-models OUT_MODELS_DIR
"""
import argparse
import os
import re
import shutil
import sys
import xml.etree.ElementTree as ET

# Built-in Gazebo Classic materials -> RGBA
GAZEBO_COLORS = {
    "Gazebo/Grey": "0.7 0.7 0.7 1",
    "Gazebo/DarkGrey": "0.35 0.35 0.35 1",
    "Gazebo/FlatBlack": "0.1 0.1 0.1 1",
    "Gazebo/Black": "0.05 0.05 0.05 1",
    "Gazebo/White": "1 1 1 1",
    "Gazebo/Red": "1 0 0 1",
    "Gazebo/Green": "0 1 0 1",
    "Gazebo/Blue": "0 0 1 1",
    "Gazebo/Yellow": "1 1 0 1",
    "Gazebo/Orange": "1 0.5 0 1",
    "Gazebo/Wood": "0.6 0.4 0.2 1",
}

GZ_SYSTEMS = [
    ("gz-sim-physics-system", "gz::sim::systems::Physics", ""),
    ("gz-sim-user-commands-system", "gz::sim::systems::UserCommands", ""),
    ("gz-sim-scene-broadcaster-system", "gz::sim::systems::SceneBroadcaster", ""),
    ("gz-sim-sensors-system", "gz::sim::systems::Sensors", "<render_engine>ogre2</render_engine>"),
    ("gz-sim-imu-system", "gz::sim::systems::Imu", ""),
]

PHYSICS = """<physics name="1ms" type="ignored">
  <max_step_size>0.001</max_step_size>
  <real_time_factor>1.0</real_time_factor>
</physics>"""


def read_xml(path):
    text = open(path, encoding="utf-8").read()
    # Gazebo Classic tolerated HTML-style comments ending in `--!>`; XML does not.
    text = re.sub(r"<!--.*?--!?>", "", text, flags=re.S)
    return ET.ElementTree(ET.fromstring(text))


def write_xml(tree, path):
    ET.indent(tree, space="  ")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tree.write(path, encoding="utf-8", xml_declaration=True)


def index_material_scripts(models_root):
    """material name -> absolute texture path, from every *.material file."""
    index = {}
    for root, _, files in os.walk(models_root):
        for f in files:
            if not f.endswith(".material"):
                continue
            text = open(os.path.join(root, f), encoding="utf-8", errors="ignore").read()
            for name, body in re.findall(r"material\s+([\w/.-]+)\s*\{(.*?)\n\}", text, flags=re.S):
                m = re.search(r"\btexture\s+([^\s]+)", body)
                if not m:
                    continue
                tex = m.group(1)
                # texture lives in ../textures next to the script, or next to it
                candidates = [
                    os.path.normpath(os.path.join(root, "..", "textures", tex)),
                    os.path.normpath(os.path.join(root, tex)),
                    os.path.normpath(os.path.join(root, "..", tex)),
                ]
                for c in candidates:
                    if os.path.isfile(c):
                        index[name] = c
                        break
    return index


def to_model_uri(abs_path, out_models_root):
    rel = os.path.relpath(abs_path, out_models_root).replace(os.sep, "/")
    return "model://" + rel


def set_children(parent, tag_values):
    for tag, value in tag_values:
        el = ET.SubElement(parent, tag)
        el.text = value


def convert_materials(tree, tex_index, out_models_root, report):
    for material in tree.iter("material"):
        script = material.find("script")
        if script is None:
            continue
        name_el = script.find("name")
        name = name_el.text.strip() if name_el is not None and name_el.text else ""
        material.remove(script)
        if name in GAZEBO_COLORS:
            rgba = GAZEBO_COLORS[name]
            set_children(material, [("ambient", rgba), ("diffuse", rgba), ("specular", "0.1 0.1 0.1 1")])
            report["colors"] += 1
        elif name in tex_index:
            set_children(material, [("ambient", "1 1 1 1"), ("diffuse", "1 1 1 1"), ("specular", "0.1 0.1 0.1 1")])
            pbr = ET.SubElement(material, "pbr")
            metal = ET.SubElement(pbr, "metal")
            set_children(metal, [
                ("albedo_map", to_model_uri(tex_index[name], out_models_root)),
                ("metalness", "0.0"),
                ("roughness", "1.0"),
            ])
            report["textures"] += 1
        else:
            set_children(material, [("ambient", "0.8 0.8 0.8 1"), ("diffuse", "0.8 0.8 0.8 1")])
            report["unknown"].add(name)


def strip_classic(tree, report):
    parents = {c: p for p in tree.iter() for c in p}
    for plugin in list(tree.iter("plugin")):
        filename = plugin.get("filename", "")
        if not filename.startswith("gz-sim") and not filename.startswith("libgz-sim"):
            parents[plugin].remove(plugin)
            report["plugins_removed"].add(filename)
    for el in tree.iter():
        if el.tag == "pose" and el.get("frame") == "":
            del el.attrib["frame"]


def port_model_tree(src_models, model_name, out_models, report):
    src = os.path.join(src_models, model_name)
    dst = os.path.join(out_models, model_name)
    if os.path.exists(dst):
        shutil.rmtree(dst)
    # meshes/ in the competition repo holds unused models with absolute paths: skip it
    shutil.copytree(src, dst, ignore=shutil.ignore_patterns("meshes", "*.material"))
    tex_index = index_material_scripts(src)
    # point the index at the copied textures
    tex_index = {k: os.path.join(dst, os.path.relpath(v, src)) for k, v in tex_index.items()}
    for root, _, files in os.walk(dst):
        for f in files:
            if f.endswith(".sdf"):
                path = os.path.join(root, f)
                tree = read_xml(path)
                convert_materials(tree, tex_index, out_models, report)
                strip_classic(tree, report)
                write_xml(tree, path)
            elif f == "model.config":
                # some configs point at model.sdf for an old SDF version only: fine as is
                pass
    # remove now-empty script folders
    for root, dirs, _ in os.walk(dst, topdown=False):
        for d in dirs:
            p = os.path.join(root, d)
            if not os.listdir(p):
                os.rmdir(p)
    return tex_index


def port_world(src_world, out_world, tex_index, out_models, report):
    tree = read_xml(src_world)
    sdf = tree.getroot()
    sdf.set("version", "1.8")
    world = sdf.find("world")
    for tag in ("state", "gui", "physics"):
        for el in list(world.findall(tag)):
            world.remove(el)
    convert_materials(tree, tex_index, out_models, report)
    strip_classic(tree, report)
    # Classic worlds often set a black ambient light, which looks too dark with PBR
    for amb in world.findall("scene/ambient"):
        if amb.text and amb.text.split()[:3] == ["0", "0", "0"]:
            amb.text = "0.8 0.8 0.8 1"
    # gz sim systems + physics at the top of the world
    insert = [ET.fromstring(PHYSICS)]
    for filename, name, inner in GZ_SYSTEMS:
        insert.append(ET.fromstring(f'<plugin filename="{filename}" name="{name}">{inner}</plugin>'))
    for i, el in enumerate(insert):
        world.insert(i, el)
    if world.find("light") is None:
        world.append(ET.fromstring(
            '<light type="directional" name="sun"><cast_shadows>false</cast_shadows>'
            '<pose>0 0 10 0 0 0</pose><diffuse>0.9 0.9 0.9 1</diffuse>'
            '<specular>0.2 0.2 0.2 1</specular><direction>-0.5 0.1 -0.9</direction></light>'))
    write_xml(tree, out_world)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--models", required=True)
    ap.add_argument("--model-name", required=True)
    ap.add_argument("--world", required=True)
    ap.add_argument("--out-world", required=True)
    ap.add_argument("--out-models", required=True)
    a = ap.parse_args()

    report = {"textures": 0, "colors": 0, "unknown": set(), "plugins_removed": set()}
    tex_index = port_model_tree(a.models, a.model_name, a.out_models, report)
    port_world(a.world, a.out_world, tex_index, a.out_models, report)

    print(f"{a.model_name}: {report['textures']} textured materials, {report['colors']} colors")
    if report["plugins_removed"]:
        print("  removed Gazebo Classic plugins:", ", ".join(sorted(report["plugins_removed"])))
    if report["unknown"]:
        print("  WARNING unknown materials (set to grey):", ", ".join(sorted(report["unknown"])))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
