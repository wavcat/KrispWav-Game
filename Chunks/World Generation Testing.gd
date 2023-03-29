extends Node2D

var tile_size = Vector2(16,16) # in pixels
var world_size = Vector2(10000,10000) #in pixels
var chunk_tiles = Vector2(10,10) #in tiles
var chunk_size = Vector2(160,160) #in pixels, multiply how many tiles you want by tile size
var chunks = []
var tiles = {}
var backgroundcoords = Vector2(1,6)
var dirtcoords = Vector2(3,8)
var outline = load("res://Chunks/chunk_outline.tscn")


func _ready():
	$TextureRect.size = world_size
	for x in world_size.x/chunk_size.x:
		for y in world_size.y/chunk_size.y: 
			chunks.append(Vector2(x,y))
	for chunk in chunks:
		var tile_list = []
		var chunk_outline = outline.instantiate()
		chunk_outline.chunk = chunk
		$ChunkBoundaries.add_child(chunk_outline)
		for x in chunk_tiles.x:
			for y in chunk_tiles.y:
				tile_list.append(Vector2(x,y))
				#$Tilemap.set_cell(0,Vector2(chunk.x*chunk_tiles.x+x,chunk.y*chunk_tiles.y+y),0,backgroundcoords,0)
				if choose([0,0,0,0,0,0,0,0,0,0,1]) == 1:
					$Tilemap.set_cell(1,Vector2(chunk.x*chunk_tiles.x+x,chunk.y*chunk_tiles.y+y),0,dirtcoords,0)
		tiles[chunk] = tile_list
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func choose(array):
	array.shuffle()
	return array[0]
