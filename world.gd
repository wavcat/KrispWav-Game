extends Node2D

var tile_size = Vector2(16,16) # in pixels
var world_size = Vector2(1024,1024) #in pixels
var chunk_tiles = Vector2(16,16) #in tiles
var chunk_size = Vector2(160,160) #in pixels, multiply how many tiles you want by tile size
var width = world_size.x/tile_size.x
var height = world_size.y/tile_size.y
var chunks = []
var tiles = []
var backgroundcoords = Vector2(1,6)
var dirtcoords = Vector2(3,8)
var outline = load("res://Chunks/chunk_outline.tscn")
var cliffs = []
var poisson_disc_sampling = PoissonDiscSampling.new()
var rng = RandomNumberGenerator.new()
var grid = []
var walkers = []
var max_walkers = 1
var max_iterations = 2000
var walker_max_count = 2
var walker_spawn_chance = 0.25
var walker_direction_chance = 0.5
var fill_percent = 0.5
var walker_destroy_chance = (0.2)
var neighbors4 = [ [1, 0], [-1, 0], [0, 1], [0, -1]]
var neighbors8 = [ [1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, -1], [1, -1], [-1, 1]]
var player_starting_tile
var Tiles = {
	"empty": -1,
	"wall": 0,
	"floor": 1,
	"dirt": 2
}

class Walker:
	var dir: Vector2
	var pos: Vector2

func _ready():
	_generate_world()

func _generate_world():
	rng.randomize()
	_init_walkers()
	_init_grid()
	_clear_tilemaps()
	_create_random_path()
	_create_walls()
	_remove_singletons()
	_pad_path()
	_remove_diagonals(Tiles.dirt)
	_spawn_tiles()
	generate_chunks()
	_generate_tree_points()
	_generate_tall_grass_points()
	_generate_rock_points()
	_set_player_starting_pos()
#	$Tilemap.set_cells_terrain_connect(1,cliffs,0,2)
	pass # Replace with function body.

func _process(delta):
	pass

func choose(array):
	array.shuffle()
	return array[0]

func generate_chunks():
	$TextureRect.size = world_size
	for x in world_size.x/chunk_size.x:
		for y in world_size.y/chunk_size.y: 
			chunks.append(Vector2(x,y))
	for chunk in chunks:
		var chunk_list = []
		var chunk_outline = outline.instantiate()
		chunk_outline.chunk = chunk
		$ChunkBoundaries.add_child(chunk_outline)
		for x in chunk_tiles.x:
			for y in chunk_tiles.y:
				chunk_list.append(Vector2(x,y))
				tiles.append(Vector2(chunk.x*chunk_tiles.x+x,chunk.y*chunk_tiles.y+y))

func _init_walkers():
	walkers = []
	for i in range(max_walkers):
		var walker = Walker.new()
		walker.dir = GetRandomDirection()
		walker.pos = Vector2(width/2,height/2)
		walkers.append(walker)
		
func _init_grid():
	grid = []
	for x in width:
		grid.append([])
		for y in height:
			grid[x].append(-1);

func GetRandomDirection():
	var directions = [[-1, 0], [1, 0], [0, 1], [0, -1]]
	var direction = directions[rng.randi()%4]
	return Vector2(direction[0], direction[1])

func _create_random_path():
	var itr = 0
	var n_tiles = 0
	while itr < max_iterations:
		# Change direction, with chance
		for i in range(walkers.size()):
			if rng.randf() < walker_direction_chance:
				walkers[i].dir = GetRandomDirection()
		# Random: Maybe destroy walker?
		for i in range(walkers.size()):
			if rng.randf() < walker_destroy_chance and walkers.size() > 1:
				walkers.remove_at(i);
				break; # Destroy only one walker per iteration
		# Spawn new walkers, with chance
		for i in range(walkers.size()):
			if rng.randf() < walker_spawn_chance and walkers.size() < walker_max_count:
				var walker = Walker.new()
				walker.dir = GetRandomDirection()
				walker.pos = walkers[i].pos
				walkers.append(walker)
		# Advance walkers
		for i in range(walkers.size()):
			if (walkers[i].pos.x + walkers[i].dir.x >= 2*max_walkers and 
				walkers[i].pos.x + walkers[i].dir.x < width-2*max_walkers and
				walkers[i].pos.y + walkers[i].dir.y >= 2*max_walkers and
				walkers[i].pos.y + walkers[i].dir.y < height-2*max_walkers):
					walkers[i].pos += walkers[i].dir
					if grid[walkers[i].pos.x][walkers[i].pos.y] == Tiles.empty:
						grid[walkers[i].pos.x][walkers[i].pos.y] = Tiles.floor
						n_tiles += 1
						if float(n_tiles)/float(width*height) >= fill_percent:
							return
		itr += 1

func _create_walls():
	for x in width:
		for y in height:
			if grid[x][y] == Tiles.floor:
				for neighbor in neighbors4:
					if check_bounds(x, y, neighbor) && grid[x + neighbor[0]][y + neighbor[1]] == Tiles.empty:
						grid[x + neighbor[0]][y + neighbor[1]] = Tiles.wall

func _remove_singletons():
	for x in width:
		for y in height:
			if grid[x][y] == Tiles.wall:
				var single_tile = true
				for neighbor in neighbors4:
					if check_bounds(x, y, neighbor) && grid[x + neighbor[0]][y + neighbor[1]] == Tiles.wall:
						single_tile = false
						break
				if single_tile:
					grid[x][y] = Tiles.floor

func check_bounds(x, y, neighbor):
	return x + neighbor[0] >= 1 && y + neighbor[1] >= 1 && y + neighbor[1] < height-1 && x + neighbor[0] < width-1 

func _pad_path():
	var bfs = []
	var visited = []
	for x in width:
		visited.append([])
		for y in height:
			if grid[x][y] == Tiles.wall:
				bfs.append(Vector2(x, y))
				visited[x].append(0)
			else:
				visited[x].append(60000)
	while !bfs.is_empty():
		var position = bfs.pop_front()
		for i in range(neighbors8.size()):
			var next = Vector2(position.x + neighbors8[i][0], position.y + neighbors8[i][1])
			if next.x >= 1 and next.x < width-1 and next.y >= 1 and next.y < height-1 and (
				visited[next.x][next.y] == 60000
				):
					visited[next.x][next.y] = visited[position.x][position.y] + 1
					bfs.append(next)    
	for x in width:
		for y in height:
			if x == 0 or y == 0 or x == width-1 or y == height-1:
				continue
			if grid[x][y] == Tiles.floor and visited[x][y] >= 2:
				grid[x][y] = Tiles.dirt

func _remove_diagonals(tile_index):
	for x in width:
		for y in height:
			# Check if on edges
			if x == 0 or y == 0 or x == width-1 or y == height-1:
				continue
			# If not on edges, make sure all surrounding tiles are floor and this is wall
			var position = Vector2(x, y);
			if grid[position.x][position.y] == tile_index:
				if (grid[position.x - 1][position.y] == Tiles.floor and grid[position.x + 1][position.y] == Tiles.floor and
				grid[position.x][position.y - 1] == Tiles.floor and grid[position.x][position.y + 1] == Tiles.floor):
					grid[position.x][position.y] = Tiles.floor
				# Check if diagonal tile
				if (grid[position.x - 1][position.y] == Tiles.floor and grid[position.x][position.y-1] == Tiles.floor and
				grid[position.x - 1][position.y-1] == tile_index) or (grid[position.x + 1][position.y] == Tiles.floor and grid[position.x][position.y+1] == Tiles.floor and
				grid[position.x + 1][position.y+1] == tile_index) or (grid[position.x + 1][position.y] == Tiles.floor and grid[position.x][position.y-1] == Tiles.floor and
				grid[position.x + 1][position.y-1] == tile_index) or (grid[position.x - 1][position.y] == Tiles.floor and grid[position.x][position.y+1] == Tiles.floor and
				grid[position.x - 1][position.y+1] == tile_index):
					grid[position.x][position.y] = Tiles.floor

func _spawn_tiles():
	var count = []
	for x in width:
		for y in height:
			match grid[x][y]:
				Tiles.empty:
					$Tilemap.set_cells_terrain_connect(0,[Vector2(x,y)],0,2)
					pass
				Tiles.floor:
					pass
				Tiles.dirt:
					$Tilemap.set_cells_terrain_connect(0,[Vector2(x,y)],0,1)
					count.append(Vector2(x,y))
#					$Tilemap.set_cells_terrain_connect(0,[Vector2(x+1,y)],0,1)
#					$Tilemap.set_cells_terrain_connect(0,[Vector2(x,y+1)],0,1)
#					$Tilemap.set_cells_terrain_connect(0,[Vector2(x+1,y+1)],0,1)
				Tiles.wall:
					$Tilemap.set_cells_terrain_connect(0,[Vector2(x,y)],0,2)
					pass

func _generate_tree_points():
	var tiles = []
	var points = poisson_disc_sampling.generate_points(48,[Vector2(0,0),Vector2(1024,0),Vector2(1024,1024),Vector2(0,1024)], 30)
	for point in points:
		var tile = $Tilemap.local_to_map(point)
		if $Tilemap.get_cell_source_id(0,tile) == 1 or $Tilemap.get_cell_source_id(0,tile) == 2:
			if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[0][0],tile.y+neighbors4[0][1])): 
				if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[1][0],tile.y+neighbors4[1][1])):
					if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[2][0],tile.y+neighbors4[2][1])):
						if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[3][0],tile.y+neighbors4[3][1])):
							tiles.append($Tilemap.local_to_map(point))
	for tile in tiles:
		if $Tilemap.get_cell_atlas_coords(2,tile) == Vector2i(-1,-1):
			$Tilemap.set_cell(2,tile,0,Vector2(0,9),0)

func _generate_tall_grass_points():
	var tiles = []
	var points = poisson_disc_sampling.generate_points(16,[Vector2(0,0),Vector2(1024,0),Vector2(1024,1024),Vector2(0,1024)], 10)
	for point in points:
		var tile = $Tilemap.local_to_map(point)
		if $Tilemap.get_cell_source_id(0,tile) == 1:
			if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[0][0],tile.y+neighbors4[0][1])): 
				if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[1][0],tile.y+neighbors4[1][1])):
					if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[2][0],tile.y+neighbors4[2][1])):
						if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[3][0],tile.y+neighbors4[3][1])):
							tiles.append($Tilemap.local_to_map(point))
		else:
			tiles.append($Tilemap.local_to_map(point))
	for tile in tiles:
		if $Tilemap.get_cell_atlas_coords(2,tile) == Vector2i(-1,-1):
			$Tilemap.set_cell(2,tile,0,Vector2(4,8),0)

func _clear_tilemaps():
	$Tilemap.clear()

func _generate_rock_points():
	var tiles = []
	var points = poisson_disc_sampling.generate_points(16,[Vector2(0,0),Vector2(1024,0),Vector2(1024,1024),Vector2(0,1024)], 10)
	for point in points:
		var tile = $Tilemap.local_to_map(point)
		if $Tilemap.get_cell_source_id(0,tile) == 1:
			if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[0][0],tile.y+neighbors4[0][1])): 
				if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[1][0],tile.y+neighbors4[1][1])):
					if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[2][0],tile.y+neighbors4[2][1])):
						if $Tilemap.get_cell_source_id(0,tile) == $Tilemap.get_cell_source_id(0,Vector2(tile.x+neighbors4[3][0],tile.y+neighbors4[3][1])):
							tiles.append($Tilemap.local_to_map(point))
		else:
			tiles.append($Tilemap.local_to_map(point))
	for tile in tiles:
		if $Tilemap.get_cell_atlas_coords(2,tile) == Vector2i(-1,-1):
			$Tilemap.set_cell(2,tile,0,Vector2(5,8),0)


func _set_player_starting_pos():
	var possible_tiles = []
	for x in width:
		for y in height:
			if $Tilemap.get_cell_atlas_coords(2,Vector2(x,y)) == Vector2i(-1,-1) and $Tilemap.get_cell_source_id(0,Vector2(x,y)) == 2:
				possible_tiles.append(Vector2(x,y))
	player_starting_tile = choose(possible_tiles)
	$Player.global_position = $Tilemap.map_to_local(player_starting_tile)
	$Player/Camera2D.limit_left = 0+tile_size.x/2
	$Player/Camera2D.limit_top = 0+tile_size.y/2
	$Player/Camera2D.limit_right = world_size.x-tile_size.x/2
	$Player/Camera2D.limit_bottom = world_size.y-16-tile_size.y/2

