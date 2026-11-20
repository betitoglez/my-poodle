"""Procedural materials for the editable wardrobe, without external maps."""
import bpy


def surface(name, color, roughness, *, specular=0.3, metallic=0.0):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, 1)
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Specular IOR Level"].default_value = specular
    shader.inputs["Metallic"].default_value = metallic
    return material, shader


def textile(name, color, weave, *, coated=False):
    material, shader = surface(
        name, color, 0.65 if coated else 0.83,
        specular=0.24 if coated else 0.13,
    )
    nodes, links = material.node_tree.nodes, material.node_tree.links
    coords = nodes.new("ShaderNodeTexCoord")
    coords.label = "UV de patrón y coordenadas del tejido"
    has_uv_pattern = weave == "knit"
    texture_space = coords.outputs["UV" if has_uv_pattern else "Generated"]

    def noise(scale):
        node = nodes.new("ShaderNodeTexNoise")
        links.new(texture_space, node.inputs["Vector"])
        node.inputs["Scale"].default_value = scale
        node.inputs["Detail"].default_value = 2
        node.inputs["Roughness"].default_value = 0.65
        return node.outputs["Fac"]

    def yarn(axis, scale, distortion):
        node = nodes.new("ShaderNodeTexWave")
        node.bands_direction = axis
        node.inputs["Scale"].default_value = scale
        node.inputs["Distortion"].default_value = distortion
        node.inputs["Detail Scale"].default_value = 0.6
        links.new(texture_space, node.inputs["Vector"])
        return node.outputs["Fac"]

    def mix_height(operation, first, second):
        node = nodes.new("ShaderNodeMath")
        node.operation = operation
        for index, value in enumerate((first, second)):
            if isinstance(value, float):
                node.inputs[index].default_value = value
            else:
                links.new(value, node.inputs[index])
        return node.outputs[0]

    fibre = noise(205)
    if weave == "corduroy":
        # On a curved body both the front and the flank need visible wales.
        along_front = yarn("X", 5.8, 0.30)
        along_side = yarn("Y", 10.5, 0.37)
        geometry = nodes.new("ShaderNodeNewGeometry")
        normal = nodes.new("ShaderNodeSeparateXYZ")
        links.new(geometry.outputs["True Normal"], normal.inputs[0])
        facing_front = mix_height("ABSOLUTE", normal.outputs["Y"], 0.0)
        blend = nodes.new("ShaderNodeMapRange")
        blend.interpolation_type = "SMOOTHERSTEP"
        blend.inputs["From Min"].default_value = 0.22
        blend.inputs["From Max"].default_value = 0.74
        links.new(facing_front, blend.inputs["Value"])
        ribs = nodes.new("ShaderNodeMix")
        links.new(blend.outputs["Result"], ribs.inputs[0])
        links.new(along_side, ribs.inputs[2])
        links.new(along_front, ribs.inputs[3])
        pattern = ribs.outputs[0]
    elif weave == "knit":
        ribs = yarn("X", 7.3, 1.1)
        courses = yarn("Y", 8.9, 0.88)
        pattern = mix_height("MULTIPLY", ribs, courses)
    elif weave == "wool":
        ribs = mix_height("MAXIMUM", yarn("X", 10.5, 0.42), yarn("Y", 15.5, 0.46))
        pattern = mix_height("MULTIPLY", ribs, yarn("Z", 10.0, 0.52))
    else:
        warp = yarn("X", 43, 0.23)
        weft = yarn("Z", 36, 0.34)
        pattern = mix_height("MULTIPLY", warp, weft)

    macro = noise(5.0)
    grain = mix_height("MULTIPLY", fibre, 0.29)
    height = mix_height("ADD", pattern, grain)
    relief = nodes.new("ShaderNodeBump")
    relief.label = "Relieve de hilo"
    relief.inputs["Strength"].default_value = 0.39 if not coated else 0.25
    relief.inputs["Distance"].default_value = {"corduroy": 0.006, "knit": 0.008}.get(weave, 0.003)
    links.new(height, relief.inputs["Height"])
    links.new(relief.outputs["Normal"], shader.inputs["Normal"])

    variation = mix_height("ADD", mix_height("MULTIPLY", macro, 0.62),
                           mix_height("MULTIPLY", pattern, 0.38))
    dye = nodes.new("ShaderNodeValToRGB")
    dye.label = "Variación del tinte y de la trama"
    dye.color_ramp.elements[0].color = (*(channel * 0.61 for channel in color), 1)
    dye.color_ramp.elements[1].color = (*(channel * 1.34 for channel in color), 1)
    links.new(variation, dye.inputs["Fac"])
    color_output = dye.outputs["Color"]
    if weave == "wool":
        axes = nodes.new("ShaderNodeSeparateXYZ")
        links.new(texture_space, axes.inputs[0])
        shift = mix_height("MULTIPLY", yarn("Y", 4.4, 0.08), 0.046)
        z = mix_height("ADD", axes.outputs["Z"], shift)
        bands = []
        for center in (0.57, 0.68):
            distance = mix_height("ABSOLUTE", mix_height("SUBTRACT", z, center), 0.0)
            bands.append(mix_height("LESS_THAN", distance, 0.024))
        trim = nodes.new("ShaderNodeMixRGB")
        links.new(mix_height("MAXIMUM", *bands), trim.inputs[0])
        links.new(color_output, trim.inputs[1])
        trim.inputs[2].default_value = (0.61, 0.49, 0.33, 1)
        color_output = trim.outputs[0]
        material["creamPattern"] = True
    links.new(color_output, shader.inputs["Base Color"])
    shader.inputs["Sheen Weight"].default_value = 0.11 if coated else 0.24
    shader.inputs["Sheen Tint"].default_value = (*color, 1)
    shader.inputs["Sheen Roughness"].default_value = 0.63
    return material


def rubber(name, color, *, outsole=False):
    material, shader = surface(name, color, 0.80 if outsole else 0.63, specular=0.22)
    nodes, links = material.node_tree.nodes, material.node_tree.links
    grain = nodes.new("ShaderNodeTexNoise")
    grain.inputs["Scale"].default_value = 145
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.23
    bump.inputs["Distance"].default_value = 0.0035
    links.new(grain.outputs["Fac"], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    return material


def finish_acetate(material):
    nodes, links = material.node_tree.nodes, material.node_tree.links
    shader = nodes.get("Principled BSDF")
    if shader.inputs["Base Color"].is_linked:
        return
    coords = nodes.new("ShaderNodeTexCoord")
    swirls = nodes.new("ShaderNodeTexNoise")
    swirls.inputs["Scale"].default_value = 39
    swirls.inputs["Detail"].default_value = 2.4
    swirls.inputs["Distortion"].default_value = 1.8
    links.new(coords.outputs["Object"], swirls.inputs["Vector"])
    color = nodes.new("ShaderNodeValToRGB")
    color.color_ramp.elements[0].position = 0.28
    color.color_ramp.elements[0].color = (0.045, 0.016, 0.008, 1)
    color.color_ramp.elements[1].position = 0.70
    color.color_ramp.elements[1].color = (0.205, 0.090, 0.037, 1)
    links.new(swirls.outputs["Fac"], color.inputs["Fac"])
    links.new(color.outputs["Color"], shader.inputs["Base Color"])
    shader.inputs["Coat Weight"].default_value = 0.28
    shader.inputs["Coat Roughness"].default_value = 0.25


def lenses():
    material, _ = surface("Gafas · lentes claras", (0.9, 0.93, 0.95), 0.2)
    nodes, links = material.node_tree.nodes, material.node_tree.links
    transparent = nodes.new("ShaderNodeBsdfTransparent")
    reflection = nodes.new("ShaderNodeBsdfGlossy")
    reflection.inputs["Roughness"].default_value = 0.18
    mix = nodes.new("ShaderNodeMixShader")
    mix.inputs[0].default_value = 0.028
    links.new(transparent.outputs[0], mix.inputs[1])
    links.new(reflection.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], nodes.get("Material Output").inputs["Surface"])
    return material
