extends Node

########################################################################################################
# Global game variables
########################################################################################################
var version = 0.1 # general version of this game
const HIGHSCORE_PATH = "user://highscore.dat" # where the highscore is safed on the filesystem.
const HIGHSCORE_PW = "code0"
const CONFIG_PATH = "user://config.ini"
const HOW_MANY_HIGHSCORES = 500 
var config # the global game userconfig


########################################################################################################
# Global game/helper functions
########################################################################################################
func pad2(st):
	# pads the string with one 0
	if st.length() < 2:
		return "0" + st
	else:
		return st

func computeColor(st):
  # computes "classic" rgb colors from string
  var commulated=0;
  for ch in st:
    commulated = commulated + ch.to_ascii()[0]
  var communist = commulated%235 + 20
  var co = Color( 
    pad2(("%x" % [communist])) +
    pad2(("%x" % [int(pow(int(communist),2)) % 255])) +
    pad2(("%x" % [int(pow(int(communist),3)) % 255])) #+ 
  )
  return co

func computeColorBB(toColor, text):
	## returns a line in bb encoding
	## colors it with computed color of color string
	var color = computeColor(toColor)
	return "[color=#" + color.to_html(false) + "]" + text + "[/color]"

func createFile(path, password = ""):
	# Create the file if its not here
	var file = File.new()
	if file.file_exists(path):
		return
	else:
		if password == "":
			file.open( path, file.WRITE)
		else:
			file.open_encrypted_with_pass(path, file.WRITE, password)
		file.close()

func putHighscore(score, team): 
	# puts a line into the crypted highscore file.
	# info: crypto cannot append line atm...
	var file = File.new()
	print("PUT ERROR: " + str( file.open_encrypted_with_pass( HIGHSCORE_PATH, file.READ_WRITE, HIGHSCORE_PW) ))
#	file.open( HIGHSCORE_PATH, file.READ_WRITE) #, "code0" )
	var tup = {}
	tup["score"] = score
	tup["team"] = team
	tup["date"] = OS.get_datetime(true)
	tup["stage"] = getStage()
	var line = to_json(tup)
	var cont = file.get_as_text()
#	var lines = cont.split("\n")
	
	
	# Only store max count of highscore entries.
	var oldHighscore = getHighscore(-1)
	if oldHighscore.size() > HOW_MANY_HIGHSCORES:
		sortHighscore(oldHighscore) # highest first
		oldHighscore.resize(HOW_MANY_HIGHSCORES) # remove rest
		
	file.close()
	file.open_encrypted_with_pass( HIGHSCORE_PATH, file.WRITE, HIGHSCORE_PW) 
	file.store_string(cont + line + "\n")
	file.close()

func cmp(elemA, elemB):
	if elemA.score > elemB.score:
		return true
	else:
		return false
		
func sortHighscore(highscoreArray):
	highscoreArray.sort_custom(self, "cmp")
	return highscoreArray

func getTeam():
	## returns an array with playernames
	var result = []
	var players = get_tree().get_root().get_node("Control").players
	for idx in players:
		result.append(players[idx].name)
	return result

func getScore():
	## returns the current score
	return get_tree().get_root().get_node("Control/game").finalScore

func getStage():
	## returns the current stage.
	return get_tree().get_root().get_node("Control/game").stage

func getHighscore(cnt):
	# returns the N sorted highscore items
	# info: crypto cannot append line atm...
	# if cnt == -1 all items are returned
	createFile(HIGHSCORE_PATH, HIGHSCORE_PW)
	var file = File.new()
	print("get ERROR: " + str( file.open_encrypted_with_pass( HIGHSCORE_PATH, file.READ, HIGHSCORE_PW )))
#	file.open( HIGHSCORE_PATH, file.READ ) #, "code0" )
	var obj
	var result = []
	var lines = file.get_as_text().split("\n")
	for line in lines:
		if validate_json(line) == "":
			obj = parse_json(line)
			result.append(obj)
	file.close()
	sortHighscore(result)
	if result.size() >= cnt and cnt != -1:
		result.resize(cnt) # only the first n elements, rest is NULL!
	return result
			
func _ready():
	## Create highscore file.
	createFile(HIGHSCORE_PATH, HIGHSCORE_PW)
	#	putHighscore(5000, ["Foo1", "Baa"])
	#	putHighscore(1100, ["Foo2", "Baa"])
	#	putHighscore(1120, ["Foo3", "Baa"])
	#	print( getHighscore(20) )

	createFile(CONFIG_PATH)	
	config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err == OK: 
		if not config.has_section_key("player", "defaultname"):
			config.set_value("player", "defaultname", "unknown")		
		if not config.has_section_key("player", "defaultserver"):
			config.set_value("player", "defaultserver", "127.0.0.1")					
		# Store a variable if and only if it hasn't been defined yet
		if not config.has_section_key("audio", "mute"):
			config.set_value("audio", "mute", false)
		# Save the changes by overwriting the previous file
		config.save(CONFIG_PATH)
	else:
		print("could not load userconfig from: " + CONFIG_PATH)
