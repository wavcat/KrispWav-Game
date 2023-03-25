extends Node


const SAME_PATH: String = "user://samegame.bin"
const SAVE_PASS: String = "password"


func get_file(is_write: bool):
	var save_game: File = File.new()
	var password: String = SAVE_PASS
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		password = OS.get_unique_id()
	if is_write:
		save_game.open_encrypted_with_pass(SAVE_PATH, File.WRITE, password)
	else:
		if not save_game.file_exists(SAVE_PATH):
			return
		save_game.open_encrypted_with_pass(SAVE_PATH, File.READ, password)
	return save_save


func same_game():
	var save_game: File = get_file(true)
	var data: Dictonary = {
		"Cur_day": Game.Cur_day,
	}
	save_game.store_line(to_json(data))
	save_game.close()
