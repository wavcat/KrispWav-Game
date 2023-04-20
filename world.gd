extends Node2D
@onready var player = $Player
@onready var player_inventory = $UI/InventoryInterface/PlayerInventory
@onready var inventory_interface = $UI/InventoryInterface
@onready var hot_bar_inventory = $UI/HotBarInventory

const PickUp = preload("res://Data/Items/pick_up.tscn")

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
var outline = load("res://UI/Chunk_Outline.tscn")
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
	inventory_interface.set_player_inventory(player.player_inventory)
	player.toggle_inventory.connect(toggle_inventory_interface)
	inventory_interface.set_hotbar_inventory(player.hotbar_inventory)
	for node in get_tree().get_nodes_in_group("external_inventory"):
		node.toggle_inventory.connect(toggle_inventory_interface)



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



func choose(array):
	array.shuffle()
	return array[0]



func toggle_inventory_interface(external_inventory_owner = null):
	player_inventory.visible = not player_inventory.visible
	
	if external_inventory_owner and inventory_interface.visible:
		inventory_interface.set_external_inventory(external_inventory_owner)
	else:
		inventory_interface.clear_external_inventory()



func generate_chunks():
	# Set the size of the TextureRect node to match the world size
	$TextureRect.size = world_size
	
	# Create an empty dictionary to store the chunk data
	var chunk_dict = {}
	
	# Iterate over the world in chunk-sized steps
	for x in range(0, world_size.x, chunk_size.x):
		for y in range(0, world_size.y, chunk_size.y):
			# Calculate the position of the current chunk
			var chunk_pos = Vector2(x / chunk_size.x, y / chunk_size.y)
			
			# Create an empty list to store the chunk tile data
			var chunk_data = []
			
			# Iterate over the tiles in the current chunk
			for i in range(chunk_size.x):
				var row = []
				for j in range(chunk_size.y):
					# Add the tile position to the current row of the chunk data
					row.append(Vector2(x+i,y+j))
				
				# Add the row of tile positions to the chunk data
				chunk_data.append(row)
			
			# Add the chunk data to the dictionary using the chunk position as the key
			chunk_dict[chunk_pos] = chunk_data
			
			# Instantiate a new instance of the outline scene
			var chunk_outline = outline.instantiate()
			
			# Set the chunk property of the outline scene to the current chunk position
			chunk_outline.chunk = chunk_pos
			
			# Add the outline scene as a child of the ChunkBoundaries node
			$ChunkBoundaries.add_child(chunk_outline)



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
	# Initialize variables
	var itr = 0
	var n_tiles = 0
	var n_walkers = walkers.size()
	var max_tiles = width*height
	# Calculate the number of cells that need to be filled
	var fill_tiles = int(fill_percent * max_tiles)
	# Calculate the maximum number of iterations based on the number of cells that need to be filled and the number of walkers
	var max_iter = max(ceil(fill_tiles / n_walkers), max_iterations)
	# Create a grid mask to track which cells have already been filled
	var grid_mask = []
	grid_mask.resize((width - 2 * max_walkers - 1) * (height - 2 * max_walkers - 1))
	
	while itr < max_iter:
		# Change direction, with chance
		for walker in walkers:
			if rng.randf() < walker_direction_chance:
				walker.dir = GetRandomDirection()
		
		# Random: Maybe destroy walker?
		if n_walkers > 1 and rng.randf() < walker_destroy_chance:
			walkers.remove_at(rng.randi() % n_walkers)
			n_walkers -= 1
		
		# Spawn new walkers, with chance
		if n_walkers < walker_max_count and rng.randf() < walker_spawn_chance:
			# Choose a random walker to spawn the new walker from
			var walker = Walker.new()
			walker.dir = GetRandomDirection()
			walker.pos = walkers[rng.randi() % n_walkers].pos
			walkers.append(walker)
			n_walkers += 1
		
		# Advance walkers
		for i in range(n_walkers):
			var walker = walkers[i]
			var x = walker.pos.x + walker.dir.x
			var y = walker.pos.y + walker.dir.y
			# Check if the walker is within the boundaries of the grid
			if x >= 2 * max_walkers and x < width - 2 * max_walkers and y >= 2 * max_walkers and y < height - 2 * max_walkers:
				# Calculate the index of the cell in the grid mask
				var idx = x - max_walkers + (y - max_walkers) * (width - 2 * max_walkers - 1)
				# Check if the cell has already been filled
				if not grid_mask[idx]:
					# Fill the cell and update variables
					grid_mask[idx] = true
					grid[x][y] = Tiles.floor
					n_tiles += 1
					# Check if the desired number of cells have been filled
					if n_tiles >= fill_tiles:
						return
				# Update the walker's position
				walker.pos = Vector2(x, y)
		
		itr += 1



func _create_walls():
	for x in width:
		for y in height:
			if grid[x][y] == Tiles.floor:
				for neighbor in neighbors4:
					if check_bounds(x, y, neighbor) && grid[x + neighbor[0]][y + neighbor[1]] == Tiles.empty:
						grid[x + neighbor[0]][y + neighbor[1]] = Tiles.wall



func _remove_singletons():
	# Iterate over all tiles except for the outer edges
	for x in range(1, width - 1):
		for y in range(1, height - 1):
			# If the tile is a wall
			if grid[x][y] == Tiles.wall:
				# Assume the tile is a "singleton" until we find a neighboring wall
				var single_tile = true
				for neighbor in neighbors4:
					# Check if the neighboring tile is within the bounds of the grid and is a wall
					if check_bounds(x, y, neighbor) && grid[x + neighbor[0]][y + neighbor[1]] == Tiles.wall:
						# If a neighboring wall is found, the tile is not a "singleton"
						single_tile = false
						break
				# If the tile is a "singleton", change it to a floor tile
				if single_tile:
					grid[x][y] = Tiles.floor



func check_bounds(x, y, neighbor):
	return x + neighbor[0] >= 1 && y + neighbor[1] >= 1 && y + neighbor[1] < height-1 && x + neighbor[0] < width-1 



func _pad_path():
	var bfs = []     # Queue for BFS traversal
	var visited = [] # 2D array to keep track of visited nodes
	for x in width:
		visited.append([]) # Initialize empty array for each row
		for y in height:
			if grid[x][y] == Tiles.wall:
				bfs.append(Vector2(x, y)) # Add wall tiles to BFS queue
				visited[x].append(0)     # Mark wall tiles as visited with 0 distance
			else:
				visited[x].append(60000) # Mark non-wall tiles as unvisited with a large distance
	while !bfs.is_empty():
		var pos = bfs.pop_front() # Get next tile from BFS queue
		for i in range(neighbors8.size()):
			var next = Vector2(pos.x + neighbors8[i][0], pos.y + neighbors8[i][1]) # Get neighboring tile
			if next.x >= 1 and next.x < width-1 and next.y >= 1 and next.y < height-1 and (
				visited[next.x][next.y] == 60000 # Check if neighboring tile is within bounds and unvisited
				):
					visited[next.x][next.y] = visited[pos.x][pos.y] + 1 # Mark neighboring tile as visited with updated distance
					bfs.append(next) # Add neighboring tile to BFS queue
	for x in width:
		for y in height:
			if x == 0 or y == 0 or x == width-1 or y == height-1:
				continue # Skip tiles on the edge of the grid
			if grid[x][y] == Tiles.floor and visited[x][y] >= 2:
				grid[x][y] = Tiles.dirt # Convert floor tiles with distance >= 2 to dirt tiles




func _remove_diagonals(tile_index):
	for x in width:
		for y in height:
			# Check if on edges
			if x == 0 or y == 0 or x == width-1 or y == height-1:
				continue
			# If not on edges, make sure all surrounding tiles are floor and this is wall
			var pos = Vector2(x, y);
			if grid[pos.x][pos.y] == tile_index:
				if (grid[pos.x - 1][pos.y] == Tiles.floor and grid[pos.x + 1][pos.y] == Tiles.floor and
				grid[pos.x][pos.y - 1] == Tiles.floor and grid[pos.x][pos.y + 1] == Tiles.floor):
					grid[pos.x][pos.y] = Tiles.floor
				# Check if diagonal tile
				if (grid[pos.x - 1][pos.y] == Tiles.floor and grid[pos.x][pos.y-1] == Tiles.floor and
				grid[pos.x - 1][pos.y-1] == tile_index) or (grid[pos.x + 1][pos.y] == Tiles.floor and grid[pos.x][pos.y+1] == Tiles.floor and
				grid[pos.x + 1][pos.y+1] == tile_index) or (grid[pos.x + 1][pos.y] == Tiles.floor and grid[pos.x][pos.y-1] == Tiles.floor and
				grid[pos.x + 1][pos.y-1] == tile_index) or (grid[pos.x - 1][pos.y] == Tiles.floor and grid[pos.x][pos.y+1] == Tiles.floor and
				grid[pos.x - 1][pos.y+1] == tile_index):
					grid[pos.x][pos.y] = Tiles.floor



func _spawn_tiles():
	var count = [] # Initialize an empty list to hold the counted tiles
	
	for x in width: # Loop through the x values in the width range
		for y in height: # Loop through the y values in the height range
			match grid[x][y]: # Match the value of the current grid tile
				
				Tiles.empty: # If the tile is empty
					$Tilemap.set_cells_terrain_connect(0,[Vector2(x,y)],0,2) # Set the terrain connect of the tile to 2
					pass # Continue to the next iteration of the loop
					
				Tiles.floor: # If the tile is a floor
					pass # Continue to the next iteration of the loop
					
				Tiles.dirt: # If the tile is dirt
					$Tilemap.set_cells_terrain_connect(0,[Vector2(x,y)],0,1) # Set the terrain connect of the tile to 1
					count.append(Vector2(x,y)) # Add the tile coordinate to the list of counted tiles
#					$Tilemap.set_cells_terrain_connect(0,[Vector2(x+1,y)],0,1) # Set the terrain connect of the right neighbor tile to 1 (commented out)
#					$Tilemap.set_cells_terrain_connect(0,[Vector2(x,y+1)],0,1) # Set the terrain connect of the bottom neighbor tile to 1 (commented out)
#					$Tilemap.set_cells_terrain_connect(0,[Vector2(x+1,y+1)],0,1) # Set the terrain connect of the bottom-right neighbor tile to 1 (commented out)
					
				Tiles.wall: # If the tile is a wall
					$Tilemap.set_cells_terrain_connect(0,[Vector2(x,y)],0,2) # Set the terrain connect of the tile to 2
					pass # Continue to the next iteration of the loop




func _generate_tree_points():
	# Initialize an empty set to hold the tile points
	var tile_points = []
	
	# Generate points using the Poisson disc sampling algorithm
	# The algorithm generates points with a minimum distance of 30 pixels and a radius of 48 pixels
	# The bounds are defined by a rectangle with corners at (0,0), (1024,0), (1024,1024), and (0,1024)
	var points = poisson_disc_sampling.generate_points(48,[Vector2(0,0),Vector2(1024,0),Vector2(1024,1024),Vector2(0,1024)], 30)
	
	# Loop through each generated point
	for point in points:
		# Convert the point to a tile coordinate on the Tilemap
		var tile = $Tilemap.local_to_map(point)
		
		# Check if the tile source ID is 1 (floor) or 2 (wall)
		var tile_source_id = $Tilemap.get_cell_source_id(0, tile)
		if tile_source_id != 1 and tile_source_id != 2:
			continue
		
		# Initialize a variable to track if the tile has an adjacent object
		var has_adjacent_object = false
		
		# Loop through the tile's neighbors
		for neighbor in neighbors4:
			# Get the neighbor tile coordinate
			var neighbor_tile = Vector2(tile.x + neighbor[0], tile.y + neighbor[1])
			
			# Check if the neighbor tile has a different source ID than the current tile
			if $Tilemap.get_cell_source_id(0, neighbor_tile) != tile_source_id:
				has_adjacent_object = true
				break
		
		# If the tile does not have an adjacent object and is not already a tree tile
		# Add the tile coordinate to the set of tree points
		if not has_adjacent_object and $Tilemap.get_cell_atlas_coords(2, tile) == Vector2i(-1,-1):
			tile_points.append(tile)
	
	# Loop through the set of tree points and set each tile to a tree
	for tile in tile_points:
		$Tilemap.set_cell(2, tile, 0, Vector2(0, 9), 0)



func _generate_tall_grass_points():
	# Initialize an empty list to hold the tile points
	var tile_points = []
	
	# Generate points using the Poisson disc sampling algorithm
	# The algorithm generates points with a minimum distance of 10 pixels and a radius of 16 pixels
	# The bounds are defined by a rectangle with corners at (0,0), (1024,0), (1024,1024), and (0,1024)
	var points = poisson_disc_sampling.generate_points(16, [Vector2(0,0), Vector2(1024,0), Vector2(1024,1024), Vector2(0,1024)], 10)
	
	# Loop through each generated point
	for point in points:
		# Convert the point to a tile coordinate on the Tilemap
		var tile = $Tilemap.local_to_map(point)
		
		# Check if the tile source ID is not 1 (floor)
		if $Tilemap.get_cell_source_id(0, tile) != 1:
			tile_points.append(tile)
			continue
		
		# Check if all of the tile's neighbors have the same source ID as the current tile
		var all_neighbors_have_same_source_id = true
		for neighbor in neighbors4:
			if $Tilemap.get_cell_source_id(0, Vector2(tile.x + neighbor[0], tile.y + neighbor[1])) != 1:
				all_neighbors_have_same_source_id = false
				break
		
		# If all of the tile's neighbors have the same source ID and the tile is not already a tall grass tile
		# Add the tile coordinate to the list of tall grass points
		if all_neighbors_have_same_source_id and $Tilemap.get_cell_atlas_coords(2, tile) == Vector2i(-1,-1):
			tile_points.append(tile)
	
	# Loop through the list of tall grass points and set each tile to a tall grass
	for tile in tile_points:
		$Tilemap.set_cell(2, tile, 0, Vector2(4, 8), 0)



func _clear_tilemaps():
	$Tilemap.clear()



func _generate_rock_points():
	# Initialize an empty list to hold the tile points
	var tile_points = []
	
	# Generate points using the Poisson disc sampling algorithm
	# The algorithm generates points with a minimum distance of 10 pixels and a radius of 16 pixels
	# The bounds are defined by a rectangle with corners at (0,0), (1024,0), (1024,1024), and (0,1024)
	var points = poisson_disc_sampling.generate_points(16, [Vector2(0,0), Vector2(1024,0), Vector2(1024,1024), Vector2(0,1024)], 10)
	
	# Loop through each generated point
	for point in points:
		# Convert the point to a tile coordinate on the Tilemap
		var tile = $Tilemap.local_to_map(point)
		
		# Check if the tile source ID is not 1 (floor) and the tile is not already a grass tile
		if $Tilemap.get_cell_source_id(0, tile) != 1 and $Tilemap.get_cell_atlas_coords(2, tile) != Vector2i(4, 8):
			tile_points.append(tile)
			continue
		
		# Check if all of the tile's neighbors have the same source ID as the current tile
		var all_neighbors_have_same_source_id = true
		for neighbor in neighbors4:
			if $Tilemap.get_cell_source_id(0, Vector2(tile.x + neighbor[0], tile.y + neighbor[1])) != 1:
				all_neighbors_have_same_source_id = false
				break
		
		# If all of the tile's neighbors have the same source ID and the tile is not already a rock tile or a grass tile
		# Add the tile coordinate to the list of rock points
		if all_neighbors_have_same_source_id and $Tilemap.get_cell_atlas_coords(2, tile) == Vector2i(-1,-1) and $Tilemap.get_cell_atlas_coords(2, tile) != Vector2i(4, 8):
			tile_points.append(tile)
	
	# Loop through the list of rock points and set each tile to a rock
	for tile in tile_points:
		$Tilemap.set_cell(2, tile, 0, Vector2(5, 8), 0)



func _set_player_starting_pos():
	# Initialize an empty list to hold possible starting tiles
	var possible_tiles = []

	# Loop through each tile in the map
	for x in width:
		for y in height:
			# Check if the tile is an empty rock tile (atlas coords == Vector2i(-1,-1)) and has a source ID of 2 (rock)
			if $Tilemap.get_cell_atlas_coords(2, Vector2(x, y)) == Vector2i(-1, -1) and $Tilemap.get_cell_source_id(0, Vector2(x, y)) == 2:
				# If so, append the tile coordinate to the list of possible starting tiles
				possible_tiles.append(Vector2(x, y))

	# Choose a random tile from the list of possible starting tiles
	var player_starting_tile = choose(possible_tiles)

	# Set the player's global position to the local position of the chosen starting tile on the Tilemap
	$Player.global_position = $Tilemap.map_to_local(player_starting_tile)

	# Set the Camera2D limits based on the tile size and world size
	$Player/Camera2D.limit_left = 0 + tile_size.x / 2
	$Player/Camera2D.limit_top = 0 + tile_size.y / 2
	$Player/Camera2D.limit_right = world_size.x - tile_size.x / 2
	$Player/Camera2D.limit_bottom = world_size.y - 16 - tile_size.y / 2



#Receives the signal from the InventoryInterface node that an item has been dropped and instantiates the item into the world.
func _on_inventory_interface_drop_slot_data(slot_data):
	print ("This is processing")
	var pickup = PickUp.instantiate()
	pickup.slot_data = slot_data
	pickup.position = player.global_position-Vector2(24,24)
	add_child(pickup)
	pass # Replace with function body.
