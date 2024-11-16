extends MeshInstance3D


const WALL = preload("res://Materials/Wall.tres") 
const TORCH = preload("res://Scenes/torch.tscn")
@onready var placed_objects: Node3D = $"../../Objects"
@onready var player: CharacterBody3D = $"../../Player"

@export var DIM = 10
@export var UNITS = 1
@export var OFFSET = -10
@export var WALL_HEIGHT = 1
@export var PASSES = 5
@export var STEPS = 20
@export var DECAL_PERCENTAGE = 0.2

var mapPoints = []
var wall_meshes = ArrayMesh.new()
var placement_points = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material_override = WALL
	reload_map()

func place_torch(pos: Vector3, rot: Vector3) -> void:
	var torch_instance = TORCH.instantiate()
	torch_instance.position = pos
	torch_instance.look_at_from_position(pos, pos + rot, Vector3.UP)
	placed_objects.add_child(torch_instance)

func reload_map() -> void:
	placement_points = []
	gen_map()
	gen_mesh()
	var surface_tool = SurfaceTool.new()
	var finished_wall_mesh = ArrayMesh.new()
	for i in range(wall_meshes.get_surface_count()):
		surface_tool.create_from(wall_meshes, i)
		surface_tool.generate_normals()
		surface_tool.generate_tangents()
		finished_wall_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_tool.commit_to_arrays()) 
	mesh = finished_wall_mesh
	for child in get_children():
		if child is StaticBody3D:
			child.queue_free()
	create_trimesh_collision()
	for child in placed_objects.get_children():
		child.queue_free()
	placement_points.shuffle()
	var selection = placement_points.size() * DECAL_PERCENTAGE
	for i in range(selection):
		place_torch(placement_points[i][0], placement_points[i][1])
	var spawnPoints = []
	for p in mapPoints:
		if p.isInterior:
			spawnPoints.append([p.x, p.y])
	spawnPoints.shuffle()
	player.position = Vector3(spawnPoints[0][0], player.position.y, spawnPoints[0][1])

func gen_map() -> void:
	mapPoints = []
	wall_meshes = ArrayMesh.new()
	for i in range(DIM + 1):
		for j in range(DIM + 1):
			mapPoints.append(Point.new(j*UNITS + OFFSET, i*UNITS + OFFSET, false))
	@warning_ignore("integer_division")
	mapPoints[((DIM+1)/2) + (((DIM+1)/2)*(DIM+1))].isInterior = true
	for p in range(PASSES):
		@warning_ignore("integer_division")
		var xPick = DIM / 2
		@warning_ignore("integer_division")
		var yPick = DIM / 2
		for s in range(STEPS):
			var rand_dir = randi() % 4
			if rand_dir == 0:
				xPick += 1
			elif rand_dir == 1:
				xPick -= 1
			elif rand_dir == 2:
				yPick += 1
			else:
				yPick -= 1
			if xPick > DIM-1:
				xPick = DIM-1
			if xPick < 1:
				xPick = 1
			if yPick > DIM-1:
				yPick = DIM-1
			if yPick < 1:
				yPick = 1
			mapPoints[xPick + yPick*(DIM+1)].isInterior = true

func gen_mesh() -> void:
	for i in range(DIM):
		for j in range(DIM):
			new_quad(get_tile(j, i))

func get_tile(xCoord: int, yCoord: int) -> Array:
	var temp = []
	temp.append(mapPoints[xCoord + yCoord * (DIM+1)])
	temp.append(mapPoints[xCoord+1 + yCoord * (DIM+1)])
	temp.append(mapPoints[xCoord + (yCoord+1) * (DIM+1)])
	temp.append(mapPoints[xCoord+1 + (yCoord+1) * (DIM+1)])
	return temp

func new_quad(tilePoints: Array) -> void:
	var count = 0
	var patternMap = []
	for p in tilePoints:
		if(p.isInterior):
			patternMap.append(1)
			count += 1
		else:
			patternMap.append(0)
	if count == 0 or count == 4:
		return
	elif count == 1:
		for i in range(tilePoints.size()):
			if(tilePoints[i].isInterior):
				var xRel = 0
				var zRel = 0
				var indices = PackedInt32Array()
				var invert = true
				if(i == 0):
					xRel = UNITS / 2.0
					zRel = UNITS / 2.0
					indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
				elif(i == 1):
					xRel = -(UNITS / 2.0)
					zRel = UNITS / 2.0
					indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
					invert = false
				elif(i == 2):
					xRel = UNITS / 2.0
					zRel = -(UNITS / 2.0)
					indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
					invert = false
				elif(i == 3):
					xRel = -(UNITS / 2.0)
					zRel = -(UNITS / 2.0)
					indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
				var verts = PackedVector3Array([
					Vector3(tilePoints[i].x + xRel, 0, tilePoints[i].y),
					Vector3(tilePoints[i].x, 0, tilePoints[i].y + zRel),
					Vector3(tilePoints[i].x + xRel, WALL_HEIGHT, tilePoints[i].y),
					Vector3(tilePoints[i].x, WALL_HEIGHT, tilePoints[i].y + zRel)
				])
				var midpoint = (verts[3] + verts[0]) / 2.0
				var u_edge = verts[2] - verts[0]
				var v_edge = verts[1] - verts[0]
				var norm = u_edge.cross(v_edge)
				var uvs = PackedVector2Array()
				if(invert):
					norm = -norm
					uvs = PackedVector2Array([
						Vector2(0, 1),
						Vector2(1, 1),
						Vector2(0, 0),
						Vector2(1, 0)
					])
					
				else:
					uvs = PackedVector2Array([
						Vector2(1, 1),
						Vector2(0, 1),
						Vector2(1, 0),
						Vector2(0, 0)
					])
				placement_points.append([midpoint, norm])
				
				var surf = []
				surf.resize(ArrayMesh.ARRAY_MAX)
				surf[ArrayMesh.ARRAY_VERTEX] = verts
				surf[ArrayMesh.ARRAY_TEX_UV] = uvs
				surf[ArrayMesh.ARRAY_INDEX] = indices
				wall_meshes.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf)
	elif count == 2:
		if patternMap == [1, 0, 0, 1] or patternMap == [0, 1, 1, 0]:
			for i in range(tilePoints.size()):
				if(tilePoints[i].isInterior):
					var xRel = 0
					var zRel = 0
					var indices = PackedInt32Array()
					var invert = true
					if(i == 0):
						xRel = UNITS / 2.0
						zRel = UNITS / 2.0
						indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
					elif(i == 1):
						xRel = -(UNITS / 2.0)
						zRel = UNITS / 2.0
						indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
						invert = false
					elif(i == 2):
						xRel = UNITS / 2.0
						zRel = -(UNITS / 2.0)
						indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
						invert = false
					elif(i == 3):
						xRel = -(UNITS / 2.0)
						zRel = -(UNITS / 2.0)
						indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
					var verts = PackedVector3Array([
						Vector3(tilePoints[i].x + xRel, 0, tilePoints[i].y),
						Vector3(tilePoints[i].x, 0, tilePoints[i].y + zRel),
						Vector3(tilePoints[i].x + xRel, WALL_HEIGHT, tilePoints[i].y),
						Vector3(tilePoints[i].x, WALL_HEIGHT, tilePoints[i].y + zRel)
					])
					var midpoint = (verts[3] + verts[0]) / 2.0
					var u_edge = verts[2] - verts[0]
					var v_edge = verts[1] - verts[0]
					var norm = u_edge.cross(v_edge)
					var uvs = PackedVector2Array()
					if(invert):
						norm = -norm
						uvs = PackedVector2Array([
							Vector2(0, 1),
							Vector2(1, 1),
							Vector2(0, 0),
							Vector2(1, 0)
						])
					else:
						uvs = PackedVector2Array([
							Vector2(1, 1),
							Vector2(0, 1),
							Vector2(1, 0),
							Vector2(0, 0)
						])
					placement_points.append([midpoint, norm])
					
					var surf = []
					surf.resize(ArrayMesh.ARRAY_MAX)
					surf[ArrayMesh.ARRAY_VERTEX] = verts
					surf[ArrayMesh.ARRAY_TEX_UV] = uvs
					surf[ArrayMesh.ARRAY_INDEX] = indices
					wall_meshes.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf)
		else:
			var isVertical = true
			var mid = UNITS / 2.0
			var indices = PackedInt32Array()
			var invert = true
			if patternMap == [1, 1, 0, 0]:
				indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
				isVertical = false
				invert = false
			elif patternMap == [0, 0, 1, 1]:
				indices = PackedInt32Array([2, 1, 0, 2, 3, 1])
				isVertical = false
			elif patternMap == [1, 0, 1, 0]:
				indices = PackedInt32Array([1, 0, 3, 3, 0, 2])
			else:
				indices = PackedInt32Array([3, 0, 1, 2, 0, 3])
				invert = false
			var verts = PackedVector3Array()
			if isVertical:
				verts = PackedVector3Array([
					Vector3(tilePoints[0].x + mid, 0, tilePoints[0].y),
					Vector3(tilePoints[0].x + mid, 0, tilePoints[0].y + UNITS),
					Vector3(tilePoints[0].x + mid, WALL_HEIGHT, tilePoints[0].y),
					Vector3(tilePoints[0].x + mid, WALL_HEIGHT, tilePoints[0].y + UNITS)
				])
			else:
				verts = PackedVector3Array([
					Vector3(tilePoints[0].x, 0, tilePoints[0].y + mid),
					Vector3(tilePoints[0].x + UNITS, 0, tilePoints[0].y + mid),
					Vector3(tilePoints[0].x, WALL_HEIGHT, tilePoints[0].y + mid),
					Vector3(tilePoints[0].x + UNITS, WALL_HEIGHT, tilePoints[0].y + mid)
				])
			var midpoint = (verts[3] + verts[0]) / 2.0
			var u_edge = verts[2] - verts[0]
			var v_edge = verts[1] - verts[0]
			var norm = u_edge.cross(v_edge)
			var uvs = PackedVector2Array()
			if(invert):
				norm = -norm
				uvs = PackedVector2Array([
					Vector2(0, 1),
					Vector2(1, 1),
					Vector2(0, 0),
					Vector2(1, 0)
				])
			else:
				uvs = PackedVector2Array([
					Vector2(1, 1),
					Vector2(0, 1),
					Vector2(1, 0),
					Vector2(0, 0)
				])
				
			placement_points.append([midpoint, norm])
			var surf = []
			surf.resize(ArrayMesh.ARRAY_MAX)
			surf[ArrayMesh.ARRAY_VERTEX] = verts
			surf[ArrayMesh.ARRAY_TEX_UV] = uvs
			surf[ArrayMesh.ARRAY_INDEX] = indices
			wall_meshes.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf)
	elif count == 3:
		for i in range(tilePoints.size()):
			if(!tilePoints[i].isInterior):
				var xRel = 0
				var zRel = 0
				var indices = PackedInt32Array()
				var invert = true
				if(i == 0):
					xRel = UNITS / 2.0
					zRel = UNITS / 2.0
					indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
				elif(i == 1):
					xRel = -(UNITS / 2.0)
					zRel = UNITS / 2.0
					indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
					invert = false
				elif(i == 2):
					xRel = UNITS / 2.0
					zRel = -(UNITS / 2.0)
					indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
					invert = false
				elif(i == 3):
					xRel = -(UNITS / 2.0)
					zRel = -(UNITS / 2.0)
					indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
				var verts = PackedVector3Array([
					Vector3(tilePoints[i].x + xRel, 0, tilePoints[i].y),
					Vector3(tilePoints[i].x, 0, tilePoints[i].y + zRel),
					Vector3(tilePoints[i].x + xRel, WALL_HEIGHT, tilePoints[i].y),
					Vector3(tilePoints[i].x, WALL_HEIGHT, tilePoints[i].y + zRel)
				])
				var midpoint = (verts[3] + verts[0]) / 2.0
				var u_edge = verts[2] - verts[0]
				var v_edge = verts[1] - verts[0]
				var norm = u_edge.cross(v_edge)
				var uvs = PackedVector2Array()
				if(!invert):
					norm = -norm
					uvs = PackedVector2Array([
						Vector2(0, 1),
						Vector2(1, 1),
						Vector2(0, 0),
						Vector2(1, 0)
					])
				else:
					uvs = PackedVector2Array([
						Vector2(1, 1),
						Vector2(0, 1),
						Vector2(1, 0),
						Vector2(0, 0)
					])
				placement_points.append([midpoint, norm])
				
				var surf = []
				surf.resize(ArrayMesh.ARRAY_MAX)
				surf[ArrayMesh.ARRAY_VERTEX] = verts
				surf[ArrayMesh.ARRAY_TEX_UV] = uvs
				surf[ArrayMesh.ARRAY_INDEX] = indices
				wall_meshes.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_map_reload"):
		reload_map()
	if Input.is_action_just_pressed("release_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if Input.is_action_just_pressed("fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


class Point:
	var x: int
	var y: int
	var isInterior: bool
	
	@warning_ignore("shadowed_variable")
	func _init(x: int, y: int, isInterior: bool):
		self.x = x
		self.y = y
		self.isInterior = isInterior
