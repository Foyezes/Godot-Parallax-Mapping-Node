# Godot 4 Parallax Mapping Node
This is an addon for Godot 4.2+ that adds the `ParallaxMapping` node to the visual shader system. This node outputs UV based on height map for `Simple Offset Mapping` & `Parallax Occlusion Mapping`.

![ParallaxMapping](https://github.com/user-attachments/assets/f6111926-ebba-4a85-ad95-d945d6b52fb8)

# Method
This node is directly ported from Godot's built in parallax occlusion shader available in `StandardMaterial3D`. The only difference is that the UV is calculated in fragment shader instead of vertex shader, because there's no way to access vertex shader directly from fragment shader.

# Installation
You can get it from the Asset Store in editor. Or extract the zip file and copy the folder to your project. You'll need to restart the editor for the node to appear in visual shader.
