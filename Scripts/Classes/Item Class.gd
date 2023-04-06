extends Resource

class_name ItemData

@export var ID : int #This ID needs to match the other classes ID if something is in multiple Databases (i.e. Crops, Decorations, etc)
@export var Name :String
@export_multiline var Description: String 
@export_enum("SEED", "SOIL","FLOOR_DECORATION","CROP","TOOL", "MATERIAL", "CONSUMABLE", "WALL","DECORATION") var ItemType #The Type of item it is in all Caps.
@export var ResourcePath : String
@export var Quantity : int #The total number of this item you have.
@export var Icon : Texture
@export var StackSize : int #The number of this item you have in that particular stack
@export var Stackable : bool = true
@export var BaseValue : int
@export var TileAtlasCoords : Vector2
