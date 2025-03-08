# This node was created by Foyezes
# x.com/Foyezes
# bsky.app/profile/foyezes.bsky.social

@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeParallaxMapping

func _get_name():
	return "ParallaxMapping"

func _get_category():
	return "Color"

func _get_description():
	return "Outputs UV for Parallax/Depth Mapping & Parallax Occlusion Mapping"

func _get_output_port_count():
	return 1
	
func _get_input_port_count():
	return 2

func _get_return_icon_type():
	return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_output_port_name(port):
		return "uv"
			
func _get_output_port_type(port):
	return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_input_port_name(port):
	match port:
		0:
			return "Height Map"
		1:
			return "UV"
			
func _get_input_port_type(port):
	match port:
		0:
			return VisualShaderNode.PORT_TYPE_SAMPLER
		1:
			return VisualShaderNode.PORT_TYPE_VECTOR_2D

func _get_property_count():
	return 3

func _get_property_name(index):
	match index:
		0:
			return "Mode"
		1:
			return "Flip Tanget"
		2:
			return "Flip Binormal"

func _get_property_options(index):
	match index:
		0:
			return ["Simple Offset", "Parallax Occlusion"]
		1:
			return ["No(Default)", "Yes"]
		2:
			return ["No(Default)", "Yes"]
			
func _get_property_default_index(index):
	match index:
		0:
			return 0
		1:
			return 0
		2:
			return 0

func _get_global_code(mode):
	var method = get_option_index(0)
	match method:
		0:
			return "
				uniform float heightmap_scale : hint_range(-16.0, 16.0, 0.001) = 5.0;
			"
		1:
			return "
				uniform float heightmap_scale : hint_range(-16.0, 16.0, 0.001) = 5.0;
				uniform int heightmap_min_layers : hint_range(1, 64) = 8;
				uniform int heightmap_max_layers : hint_range(1, 64) = 16;
				"
			
func _get_code(input_vars, output_vars, mode, type):
	if type == VisualShader.TYPE_FRAGMENT:
		var method = get_option_index(0)
		var flipTangent = get_option_index(1)
		var flipBinormal = get_option_index(2)
		match [method, flipTangent, flipBinormal]:
			[0, 0, 0]: #Method: Simple, flipTangent: No, flipBinormal: No
				return """
				{
				vec2 base_uv = %s;
				vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT, -BINORMAL, NORMAL));
				float depth = 1.0 - texture(%s, base_uv).r;
				vec2 ofs = base_uv - view_dir.xy * depth * heightmap_scale * 0.01;
				base_uv = ofs;
				%s = base_uv;
				}
				""" % [input_vars[1], input_vars[0], output_vars[0]]
			[0, 1, 0]: #Method: Simple, flipTangent: Yes, flipBinormal: No
				return """
				{
				vec2 base_uv = %s;
				vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(-TANGENT, -BINORMAL, NORMAL));
				float depth = 1.0 - texture(%s, base_uv).r;
				vec2 ofs = base_uv - view_dir.xy * depth * heightmap_scale * 0.01;
				base_uv = ofs;
				%s = base_uv;
				}
				""" % [input_vars[1], input_vars[0], output_vars[0]]
			[0, 0, 1]: #Method: Simple, flipTangent: No, flipBinormal: Yes
				return """
				{
				vec2 base_uv = %s;
				vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT, BINORMAL, NORMAL));
				float depth = 1.0 - texture(%s, base_uv).r;
				vec2 ofs = base_uv - view_dir.xy * depth * heightmap_scale * 0.01;
				base_uv = ofs;
				%s = base_uv;
				}
				""" % [input_vars[1], input_vars[0], output_vars[0]]
			[0, 1, 1]: #Method: Simple, flipTangent: Yes, flipBinormal: Yes
				return """
				{
				vec2 base_uv = %s;
				vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(-TANGENT, BINORMAL, NORMAL));
				float depth = 1.0 - texture(%s, base_uv).r;
				vec2 ofs = base_uv - view_dir.xy * depth * heightmap_scale * 0.01;
				base_uv = ofs;
				%s = base_uv;
				}
				""" % [input_vars[1], input_vars[0], output_vars[0]]
			[1, 0, 0]: #Method: POM, flipTangent: No, flipBinormal: No
				return """
				{
				vec2 base_uv = %s;
				vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT, -BINORMAL, NORMAL));
				float num_layers = mix(float(heightmap_max_layers), float(heightmap_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
				float layer_depth = 1.0 / num_layers;
				float current_layer_depth = 0.0;
				vec2 p = view_dir.xy * heightmap_scale * 0.01;
				vec2 delta = p / num_layers;
				vec2 ofs = base_uv;
				float depth = 1.0 - texture(%s, ofs).r;
				float current_depth = 0.0;
				while (current_depth < depth) {
					ofs -= delta;
					depth = 1.0 - texture(%s, ofs).r;
					current_depth += layer_depth;
				}
				vec2 prev_ofs = ofs + delta;
				float after_depth = depth - current_depth;
				float before_depth = (1.0 - texture(%s, prev_ofs).r) - current_depth + layer_depth;
				float weight = after_depth / (after_depth - before_depth);
				ofs = mix(ofs, prev_ofs, weight);
				base_uv = ofs;
				%s = base_uv;
				}
				""" % [input_vars[1], input_vars[0], input_vars[0], input_vars[0], output_vars[0]]
			[1, 1, 0]: #Method: POM, flipTangent: Yes, flipBinormal: No
				return """
				{
				vec2 base_uv = %s;
				vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(-TANGENT, -BINORMAL, NORMAL));
				float num_layers = mix(float(heightmap_max_layers), float(heightmap_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
				float layer_depth = 1.0 / num_layers;
				float current_layer_depth = 0.0;
				vec2 p = view_dir.xy * heightmap_scale * 0.01;
				vec2 delta = p / num_layers;
				vec2 ofs = base_uv;
				float depth = 1.0 - texture(%s, ofs).r;
				float current_depth = 0.0;
				while (current_depth < depth) {
					ofs -= delta;
					depth = 1.0 - texture(%s, ofs).r;
					current_depth += layer_depth;
				}
				vec2 prev_ofs = ofs + delta;
				float after_depth = depth - current_depth;
				float before_depth = (1.0 - texture(%s, prev_ofs).r) - current_depth + layer_depth;
				float weight = after_depth / (after_depth - before_depth);
				ofs = mix(ofs, prev_ofs, weight);
				base_uv = ofs;
				%s = base_uv;
				}
				""" % [input_vars[1], input_vars[0], input_vars[0], input_vars[0], output_vars[0]]
			[1, 0, 1]: #Method: POM, flipTangent: No, flipBinormal: Yes
				return """
				{
				vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT, BINORMAL, NORMAL));
				float num_layers = mix(float(heightmap_max_layers), float(heightmap_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
				float layer_depth = 1.0 / num_layers;
				float current_layer_depth = 0.0;
				vec2 p = view_dir.xy * heightmap_scale * 0.01;
				vec2 delta = p / num_layers;
				vec2 ofs = base_uv;
				float depth = 1.0 - texture(%s, ofs).r;
				float current_depth = 0.0;
				while (current_depth < depth) {
					ofs -= delta;
					depth = 1.0 - texture(%s, ofs).r;
					current_depth += layer_depth;
				}
				vec2 prev_ofs = ofs + delta;
				float after_depth = depth - current_depth;
				float before_depth = (1.0 - texture(%s, prev_ofs).r) - current_depth + layer_depth;
				float weight = after_depth / (after_depth - before_depth);
				ofs = mix(ofs, prev_ofs, weight);
				base_uv = ofs;
				%s = base_uv;
				}
				""" % [input_vars[1], input_vars[0], input_vars[0], input_vars[0], output_vars[0]]
			[1, 1, 1]: #Method: POM, flipTangent: Yes, flipBinormal: Yes
				return """
				vec2 base_uv = %s;
				vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(-TANGENT, BINORMAL, NORMAL));
				float num_layers = mix(float(heightmap_max_layers), float(heightmap_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
				float layer_depth = 1.0 / num_layers;
				float current_layer_depth = 0.0;
				vec2 p = view_dir.xy * heightmap_scale * 0.01;
				vec2 delta = p / num_layers;
				vec2 ofs = base_uv;
				float depth = 1.0 - texture(%s, ofs).r;
				float current_depth = 0.0;
				while (current_depth < depth) {
					ofs -= delta;
					depth = 1.0 - texture(%s, ofs).r;
					current_depth += layer_depth;
				}
				vec2 prev_ofs = ofs + delta;
				float after_depth = depth - current_depth;
				float before_depth = (1.0 - texture(%s, prev_ofs).r) - current_depth + layer_depth;
				float weight = after_depth / (after_depth - before_depth);
				ofs = mix(ofs, prev_ofs, weight);
				base_uv = ofs;
				%s = base_uv;
				}
				""" % [input_vars[1], input_vars[0], input_vars[0], input_vars[0], output_vars[0]]

func _is_available(mode, type):
	if type == VisualShader.TYPE_VERTEX:
		return false
	elif type == VisualShader.TYPE_FRAGMENT:
		return true
