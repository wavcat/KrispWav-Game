extends Resource

class_name Soil

@export var ID : int
@export_enum("Clay", "Clay Sand", "Clay Silt", "Loamy Clay", "Loamy Sand", "Loamy Silt","Sand", "Sandy Clay", "Sandy Silt", "Silt", "Silty Clay", "Silty Sand" ) var SoilType
@export var Sand : int #Numerical Number of how much Sand is in this soil type. All three values must add up to 10. (i.e. 4 Sand, 5 Silt, 1 Clay)
@export var Silt : int #Numerical Number of how much Silt is in this soil type. All three values must add up to 10. (i.e. 4 Sand, 5 Silt, 1 Clay)
@export var Clay : int #Numerical Number of how much Clay is in this soil type. All three values must add up to 10. (i.e. 4 Sand, 5 Silt, 1 Clay)
@export var SoilAtlasCoords : Vector2
