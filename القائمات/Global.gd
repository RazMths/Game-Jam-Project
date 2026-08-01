extends Node


var score = 0 
var pos = Vector2.ZERO 

#لعمل حفظ في اللعبة استدعي التابع Global.save_data() في المكان المناسب 

func _ready():
	load_data()

func save():#هنا نضع البيانات التي نريد حفظها 
	var dict = {"score": score,
	"pos": pos}
	
	return dict 

#اذا اردت حذف الملف يدوويا ستجده في هذا المسار على حاسوبك
#C:\Users\اسم كمبيوترك\AppData\Roaming\Godot\app_userdata\اسم المشروع الذي تعمل عليه 
#هذا المتغير يحوي مسار الملف و اسمه و اللاحقة 
var file_path = "user://saved_data.save"

func save_data():#هذا التابع يقوم بفتح ملف جايسون و كتابة البيانات داخله 
	var save_game = FileAccess.open(file_path,FileAccess.WRITE)
	var json_string = JSON.stringify(save())
	save_game.store_line(json_string)


func load_data():#هذا الابع يقوم بتحميل البيانات من الملف الى داخل اللعبة  
	if not FileAccess.file_exists(file_path):
		return
	var save_game = FileAccess.open(file_path,FileAccess.READ)
	while save_game.get_position() < save_game.get_length():
		var json_string = save_game.get_line()
		var json  = JSON.new()
		var prase_result = json.parse(json_string)
		var node_data = json.get_data()

		score = node_data["score"]
		pos = node_data["pos"]


