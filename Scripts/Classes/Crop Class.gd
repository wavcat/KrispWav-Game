extends Resource
class_name Crop

@export var ID : int #This ID needs to be the same as the Seed Item for that particular Crop (i.e. the Apple Crop, and Apple Seed Item must have the same ID.
@export var Name : String 
@export var Stage1Time : int #How Long the first growth stage will last in seconds.
@export var Stage2Time : int #How Long the second growth stage will last in seconds.
@export var Stage3Time : int #How Long the third growth stage will last in seconds.
@export var Stage4Time : int #How Long the fourth growth stage will last in seconds.
@export var Repeats : bool #Whether or not the crop repeats it's growth cycle after being harvested for multiple harvests.
@export var TotalTime : int #Sum of each stage's growth times.
@export var BaseHarvestAmount : int #Base number of crops you'll get from harvesting it.
@export var Stage1AtlasCoords : Vector2 #Tile Coords for the first growth stage
@export var Stage2AtlasCoords : Vector2 #Tile Coords for the second growth stage
@export var Stage3AtlasCoords : Vector2 #Tile Coords for the third growth stage
@export var Stage4AtlasCoords : Vector2 #Tile Coords for the fourth growth stage
@export var NeedsSpace : bool  #Whether the crop needs space to grow. I.e. if a crop needs space and another crop is planted on the tile next to it, it won't grow.
@export var MinWaterLevel : int #Minimum water level needed to grow.
@export var MaxWaterLevel : int #Maximum water level allowed to grow.
@export_enum("Clay", "Clay Sand", "Clay Silt", "Loamy Clay", "Loamy Sand", "Loamy Silt","Sand", "Sandy Clay", "Sandy Silt", "Silt", "Silty Clay", "Silty Sand" ) var NeededSoil #What Soil Type the Crop needs to grow.
@export var ProduceItemID: int #ID of the Crop's Produce Item
