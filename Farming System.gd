extends TileMap

#This will be a dictionary that has all the properties of every crop you'll have in your game. (i.e. If I have Potatoes, Ill list potatoes here along with how many days it takes to grop, what season, etc.) 
#Anytime you need to check if a crop's requirements are met (i.e. for watering, if it's in season, how many it produces, etc.) those requirements need to be listed here.
var CropDatabase = {"Flower Crop":
	{"Crop Name" :"Flower Crop",
	"Requires Watering": true,
	"Base Stage Tile Coordinates": Vector2(0,8),
	"Stage 2 Tile Coordinates": Vector2(1,8) #This field will be the atlas coordinate for the base stage of this crop in your tileset.
	}}
var TilledTiles = []


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	get_tilled_tiles()
	randomly_assign_crop_data()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

#This function just randomly selects something from a list for variability
func choose(array):
	array.shuffle()
	return array[0]

#This Function basically looks at the Farming System Tilemap and obtains the coordinates for every tile that has a tilled dirt tile on it (It looks at layer 0 (the tilled dirt layer), then grabs the atlas coordinate for tilled dirt(3,8))
func get_tilled_tiles():
	for tile in self.get_used_cells_by_id(0,-1,Vector2i(3,8)):
		TilledTiles.append(tile)

#This Function is just going through the tiles that have been tilled and randomly deciding whether or not it has a crop on it or not, as well as whether it is watered or not.
func randomly_assign_crop_data():
	for tile in TilledTiles:
		self.get_cell_tile_data(0,tile).set_custom_data("Current Crop",choose([null,"Flower Crop"]))
		self.get_cell_tile_data(0,tile).set_custom_data("Is Watered?",choose([true,false]))
		#The below section basically searches for all tilled dirt tiles that have a crop on it named "Flower Crop", if it encounters any it obtains the "Flower Crop" ID from the Crop Database above and sets that tile's ID to that on the "Crop Layer" (layer 2)
		if self.get_cell_tile_data(0,tile).get_custom_data("Current Crop") == "Flower Crop":
			self.get_cell_tile_data(0,tile).set_custom_data("Current Crop Stage",0)
			self.set_cell(2,tile,0,CropDatabase["Flower Crop"]["Base Stage Tile Coordinates"])
		#Like the above section, this searches for all tilled dirt tiles that are watered, then sets that specific tile to the "Water" ID(2,8) on the "Water Layer" (layer 1)
		if self.get_cell_tile_data(0,tile).get_custom_data("Is Watered?") == true:
			self.set_cell(1,tile,0,Vector2(2,8))

"""The above system should be a good starting point, basically each tile has its' own custom data fields that can be set on the right under 'custom data layers'. Once those have been established
if you ever need to find out info about a tile you would use 'get_cell_tile_data().get_custom_data()' to pull that info about that tile. Inversely you can use
'get_cell_tile_data().set_custom_data()' to change or update any info on a tile. For example if a tilled spot isn't watered but you use a watering can on that
tile, in the watering can use function you'd have a call to set that tile's data such as 'get_cell_tile_data(0,tile).set_custom_data('is watered?',true)' and set it to being watered. 
Now that you can manage all of a tile's data you would use 'set_cell(), to update that tile on the given layer, for example once I update the tile's data to being watered I would then use 
set_cell(layer,tile, water_tile_atlas_id) to change the sprite of that tile to the water one."""
