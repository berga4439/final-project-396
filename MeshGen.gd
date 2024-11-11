extends MeshInstance3D

@export var DIM = 10
@export var UNITS = 1
@export var OFFSET = -10
@export var WALL_HEIGHT = 1
@export var PASSES = 5
@export var STEPS = 20

var mapPoints = []
var wall_meshes = ArrayMesh.new()
var material = StandardMaterial3D.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material.vertex_color_use_as_albedo = true
	material_override = material
	gen_map()
	gen_mesh()


func gen_map() -> void:
	mapPoints = []
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
	mesh = wall_meshes

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
				var debugColor = Color(1, 1, 1, 1)
				if(i == 0):
					xRel = UNITS / 2.0
					zRel = UNITS / 2.0
					indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
					debugColor = Color(1, 0, 0, 1)
				elif(i == 1):
					xRel = -(UNITS / 2.0)
					zRel = UNITS / 2.0
					indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
					debugColor = Color(0, 1, 0, 1)
				elif(i == 2):
					xRel = UNITS / 2.0
					zRel = -(UNITS / 2.0)
					indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
					debugColor = Color(0, 0, 1, 1)
				elif(i == 3):
					xRel = -(UNITS / 2.0)
					zRel = -(UNITS / 2.0)
					indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
					debugColor = Color(1, 0, 1, 1)
				var verts = PackedVector3Array([
					Vector3(tilePoints[i].x + xRel, 0, tilePoints[i].y),
					Vector3(tilePoints[i].x, 0, tilePoints[i].y + zRel),
					Vector3(tilePoints[i].x + xRel, WALL_HEIGHT, tilePoints[i].y),
					Vector3(tilePoints[i].x, WALL_HEIGHT, tilePoints[i].y + zRel)
				])
				var uvs = PackedVector2Array([
					Vector2(0, 1),
					Vector2(1, 1),
					Vector2(1, 0),
					Vector2(0, 0)
				])
				var colors = PackedColorArray([debugColor, debugColor, debugColor, debugColor])
				var surf = []
				surf.resize(ArrayMesh.ARRAY_MAX)
				surf[ArrayMesh.ARRAY_VERTEX] = verts
				surf[ArrayMesh.ARRAY_TEX_UV] = uvs
				surf[ArrayMesh.ARRAY_INDEX] = indices
				surf[ArrayMesh.ARRAY_COLOR] = colors
				wall_meshes.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf)
	elif count == 2:
		if patternMap == [1, 0, 0, 1] or patternMap == [0, 1, 1, 0]:
			for i in range(tilePoints.size()):
				if(tilePoints[i].isInterior):
					var xRel = 0
					var zRel = 0
					var indices = PackedInt32Array()
					var debugColor = Color(1, 1, 1, 1)
					if(i == 0):
						xRel = UNITS / 2.0
						zRel = UNITS / 2.0
						indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
						debugColor = Color(1, 0, 0, 1)
					elif(i == 1):
						xRel = -(UNITS / 2.0)
						zRel = UNITS / 2.0
						indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
						debugColor = Color(0, 1, 0, 1)
					elif(i == 2):
						xRel = UNITS / 2.0
						zRel = -(UNITS / 2.0)
						indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
						debugColor = Color(0, 0, 1, 1)
					elif(i == 3):
						xRel = -(UNITS / 2.0)
						zRel = -(UNITS / 2.0)
						indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
						debugColor = Color(1, 0, 1, 1)
					var verts = PackedVector3Array([
						Vector3(tilePoints[i].x + xRel, 0, tilePoints[i].y),
						Vector3(tilePoints[i].x, 0, tilePoints[i].y + zRel),
						Vector3(tilePoints[i].x + xRel, WALL_HEIGHT, tilePoints[i].y),
						Vector3(tilePoints[i].x, WALL_HEIGHT, tilePoints[i].y + zRel)
					])
					var uvs = PackedVector2Array([
						Vector2(0, 1),
						Vector2(1, 1),
						Vector2(1, 0),
						Vector2(0, 0)
					])
					var colors = PackedColorArray([debugColor, debugColor, debugColor, debugColor])
					var surf = []
					surf.resize(ArrayMesh.ARRAY_MAX)
					surf[ArrayMesh.ARRAY_VERTEX] = verts
					surf[ArrayMesh.ARRAY_TEX_UV] = uvs
					surf[ArrayMesh.ARRAY_INDEX] = indices
					surf[ArrayMesh.ARRAY_COLOR] = colors
					wall_meshes.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf)
		else:
			var isVertical = true
			var mid = UNITS / 2.0
			var indices = PackedInt32Array()
			var debugColor = Color(1, 1, 1, 1)
			if patternMap == [1, 1, 0, 0]:
				indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
				isVertical = false
				debugColor = Color(1, 0, 0, 1)
			elif patternMap == [0, 0, 1, 1]:
				indices = PackedInt32Array([2, 1, 0, 2, 3, 1])
				isVertical = false
				debugColor = Color(0, 1, 0, 1)
			elif patternMap == [1, 0, 1, 0]:
				indices = PackedInt32Array([1, 0, 3, 3, 0, 2])
				debugColor = Color(0, 0, 1, 1)
			else:
				indices = PackedInt32Array([3, 0, 1, 2, 0, 3])
				debugColor = Color(1, 0, 1, 1)
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
			var uvs = PackedVector2Array([
					Vector2(0, 1),
					Vector2(1, 1),
					Vector2(1, 0),
					Vector2(0, 0)
			])
			var colors = PackedColorArray([debugColor, debugColor, debugColor, debugColor])
			var surf = []
			surf.resize(ArrayMesh.ARRAY_MAX)
			surf[ArrayMesh.ARRAY_VERTEX] = verts
			surf[ArrayMesh.ARRAY_TEX_UV] = uvs
			surf[ArrayMesh.ARRAY_INDEX] = indices
			surf[ArrayMesh.ARRAY_COLOR] = colors
			wall_meshes.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf)
	elif count == 3:
		for i in range(tilePoints.size()):
			if(!tilePoints[i].isInterior):
				var xRel = 0
				var zRel = 0
				var indices = PackedInt32Array()
				var debugColor = Color(1, 1, 1, 1)
				if(i == 0):
					xRel = UNITS / 2.0
					zRel = UNITS / 2.0
					indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
					debugColor = Color(1, 0, 0, 1)
				elif(i == 1):
					xRel = -(UNITS / 2.0)
					zRel = UNITS / 2.0
					indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
					debugColor = Color(0, 1, 0, 1)
				elif(i == 2):
					xRel = UNITS / 2.0
					zRel = -(UNITS / 2.0)
					indices = PackedInt32Array([0, 3, 1, 0, 2, 3])
					debugColor = Color(0, 0, 1, 1)
				elif(i == 3):
					xRel = -(UNITS / 2.0)
					zRel = -(UNITS / 2.0)
					indices = PackedInt32Array([0, 1, 2, 1, 3, 2])
					debugColor = Color(1, 0, 1, 1)
				var verts = PackedVector3Array([
					Vector3(tilePoints[i].x + xRel, 0, tilePoints[i].y),
					Vector3(tilePoints[i].x, 0, tilePoints[i].y + zRel),
					Vector3(tilePoints[i].x + xRel, WALL_HEIGHT, tilePoints[i].y),
					Vector3(tilePoints[i].x, WALL_HEIGHT, tilePoints[i].y + zRel)
				])
				var uvs = PackedVector2Array([
					Vector2(0, 1),
					Vector2(1, 1),
					Vector2(1, 0),
					Vector2(0, 0)
				])
				var colors = PackedColorArray([debugColor, debugColor, debugColor, debugColor])
				var surf = []
				surf.resize(ArrayMesh.ARRAY_MAX)
				surf[ArrayMesh.ARRAY_VERTEX] = verts
				surf[ArrayMesh.ARRAY_TEX_UV] = uvs
				surf[ArrayMesh.ARRAY_INDEX] = indices
				surf[ArrayMesh.ARRAY_COLOR] = colors
				wall_meshes.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


class Point:
	var x: int
	var y: int
	var isInterior: bool
	
	@warning_ignore("shadowed_variable")
	func _init(x: int, y: int, isInterior: bool):
		self.x = x
		self.y = y
		self.isInterior = isInterior
