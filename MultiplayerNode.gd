extends Node2D

@export var _text_console : TextEdit
@export var _table : Node2D
@export var _hostButton : Button
@export var _networkPanel : Control
@export var _multiplayerPanel: Control
@export var _nickname : LineEdit
@export var _player_list : VBoxContainer
@export var _lobby: Panel
@export var _clientControls: Control
@export var _assets: Node2D
@export var _flop: Array[Node2D]
@export var _hand: Array[Node2D]
@export var _playerIcons: Node2D
@export var _myPlayerIcon: TextureRect
@export var _titleSequence: AnimationPlayer
@export var _raiseLabel: Label
@export var _raiseSlider: HSlider
@export var _playControls: VBoxContainer
@export var _potLabel: Label
@export var _ipAddressInput: LineEdit
@export var _avatarPicker: MenuButton
@export var _avatarImage: TextureRect
@export var _callButton: Button
@export var _foldButton: Button
@export var _checkButton: Button
@export var _raiseButton: Button
@export var _raiseBar: HBoxContainer
@export var _noisePlayer: AudioStreamPlayer


const _audio_check = preload("res://Sounds/check.mp3")
const _audio_ready = [
	preload("res://Sounds/ready/r1.mp3"),
	preload("res://Sounds/ready/r2.mp3"),
	preload("res://Sounds/ready/r4.mp3"),
	preload("res://Sounds/ready/r5.mp3"),
	preload("res://Sounds/ready/r6.mp3")
]
const _audio_fold = preload("res://Sounds/fold.mp3")
const _audio_raise = preload("res://Sounds/raise.mp3")
const _audio_call = preload("res://Sounds/call.mp3")

func playReadySound():
	_noisePlayer.pitch_scale = randf_range(0.85, 1.15)
	_noisePlayer.stream = _audio_ready[randi_range(0, _audio_ready.size()-1)]
	_noisePlayer.play()
	pass

func playSound(audio):
	_noisePlayer.pitch_scale = randf_range(0.85, 1.15)
	_noisePlayer.stream = audio
	_noisePlayer.play()
	pass

const avatars = [
	preload("res://Avatars/Javid.png"), 
	preload("res://Avatars/Hopson.png"), 
	preload("res://Avatars/Duck.png"),
	preload("res://Avatars/Cat.png"), 
	preload("res://Avatars/Slide.png"),
	preload("res://Avatars/Patrick.png"),
	preload("res://Avatars/Bidoof.png"),
	preload("res://Avatars/Lola.png")
	]
const avatar_names = [
	"David", 
	"Matthew", 
	"Let", 
	"Catarina", 
	"Ronald",
	"Patrick",
	"Rui",
	"Lola"
	]

var player_list_item = preload("res://GameObjects/PlayerList.tscn")
var player_icon = preload("res://GameObjects/Player.tscn")

class LocalPlayer:
	var nickname : String = ""
	var avatar_id : int = 0
	var id : int = -1
	var bet = 0
	var money = 1000
	var blind = 0
	var folded = false
	var isTurn = false
	var ready = false
	var found = false


var player_list = []

var ingame = false


func l(text):
	#if _text_console != null:
		#_text_console.text += text + "\n"
	print(text)

var avatar_id = 0

func _avatar_chosen(idx):
	_avatarImage.texture = avatars[idx]
	avatar_id = idx
	
func _ready():
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.connected_to_server.connect(_connected_to_server)
	_avatarPicker.get_popup().clear()
	for i in avatars.size():
		_avatarPicker.get_popup().add_icon_item(avatars[i], avatar_names[i])
	_avatarImage.texture = avatars[0]
	_avatarPicker.get_popup().index_pressed.connect(_avatar_chosen)
	pass


func _process(delta):
	pass

func start_game():
	_table.startGame()
	updateHands()
	ServerUpdatePlayerList()
	PStartGame.rpc()
	_table.currentPlayer = -1
	onTurn()
	ingame = true
	pass

func _on_host_pressed():
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_server(7777);
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		l("Failed to start multiplayer server.")
		return
	else:
		l("HOSTING ON PORT 7777")
	_networkPanel.hide()
	multiplayer.multiplayer_peer = peer;

func _on_join_pressed():
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_client(_ipAddressInput.text)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		l("Failed to start multiplayer client.")
		return
	else:
		l("JOINED ON LOCALHOST:7777")
		_multiplayerPanel.hide()
		_lobby.show()
	multiplayer.multiplayer_peer = peer

func _on_ready_pressed():
	ready.rpc();
	pass # Replace with function body.

func end_game(winner = null, rank = ""):
	if(!multiplayer.is_server()):
		return
	ingame = false
	for i in range(player_queue.size()-1,-1,-1):
		_table.players.push_back(player_queue[i])	
		SetPlayerID.rpc_id(player_queue[i].id,player_queue[i].id)
		player_queue.remove_at(i)
	for p in _table.players:
		for i in range(_table.players.size()-1,-1,-1):
			if _table.players[i].disconnected:
				_table.players.remove_at(i)
			else:
				_table.players[i].ready = false
	PEndGame.rpc(winner, rank)
	for p in _table.players:
		if p.money == 0:
			multiplayer.multiplayer_peer.disconnect_peer(p.id)
	ServerUpdatePlayerList()
	
@rpc("reliable")
func PEndGame(winner, rank):
	if(winner != null):
		var txt = ""
		var otherTxt = ""
		for i in range(winner.size()):
			if(getLocalPlayerByID(winner[i]) == null):
				continue
			if i != 0:
				txt += "and "
			txt += getLocalPlayerByID(winner[i]).nickname + " "
			otherTxt = rank
		if(winner.size() == 1):
			txt += "WINS"
		else:
			txt += "WIN"
		_titleSequence.announce(txt, otherTxt)
	_table.table = []
	#for i in range(_hand.size()):
		#_hand[i].hideCard()
	#for i in range(_hand.size()):
		#_hand[i].hide()
	#for i in range(_flop.size()):
		#_flop[i].hide()
	#for c in _playerIcons.get_children():
		#_playerIcons.remove_child(c)
	#_playerIcons.hide()
	_clientControls.hide()
	_lobby.show()

#@rpc("reliable")
#func PLuckedOut():

@rpc("reliable")
func PStartGame():
	if(!multiplayer.is_server()):
		l("RESTARTING GAME")
		_table.table = []
		updateTableClient()
		_playerIcons.show()
		for p in _playerIcons.get_children():
			p.hideCards()
		

@rpc("any_peer","reliable")
func ready():
	var id = multiplayer.get_remote_sender_id()
	if(multiplayer.is_server()):
		if(ingame):
			return
		_table.players[indexPlayerByID(id)].ready = true
		ServerUpdatePlayerList()
		PReady.rpc()
		l(str(id) + " is ready.")
		if(checkReady()):
			l("EVERYONE IS READY!")
			setUnready()
			start_game()

func onTurn():
	_table.currentPlayer += 1
	if(_table.checkFlop()):
		_table.onRound()
		if(_table.table.size() == 0):
			_table.drawTable()
			_table.drawTable()
			_table.drawTable()
			updateTable.rpc(_table.cHand(_table.table))		
			_table.currentPlayer = 0
		elif(_table.table.size() == 3):
			_table.drawTable()
			updateTable.rpc(_table.cHand(_table.table))		
			_table.currentPlayer = 0
		elif(_table.table.size() == 4):
			_table.drawTable()
			updateTable.rpc(_table.cHand(_table.table))		
			_table.currentPlayer = 0
		else:
			l("DECLARING A WINNER")
			var winners = _table.checkWinner()
			l("WINNER IS " + _table.cWinner(winners))
			for p in _table.players:
				p.money -= p.bet
				p.bet = 0
			if(winners.size() != 0):
				var value = _table.pot
				var split = value/winners.size()
				for w in winners:
					w[0].money += split
			var end_game_result = []
			var combo = 0
			for w in winners:
				end_game_result.push_back(w[0].id)
				combo = w[1][0]
			var txt = ""
			match combo:
				_table.Rank.High: txt = "HIGH CARD"
				_table.Rank.Pair: txt = "PAIR"
				_table.Rank.TwoPair: txt = "TWO PAIR"
				_table.Rank.Three: txt = "THREE OF A KIND"
				_table.Rank.Straight: txt = "STRAIGHT"
				_table.Rank.Flush: txt = "FLUSH"
				_table.Rank.FullHouse: txt = "FULL HOUSE"
				_table.Rank.Four: txt = "FOUR OF A KIND"
				_table.Rank.StraightFlush: txt = "STRAIGHT FLUSH"
				_table.Rank.RoyalFlush: txt = "ROYAL STRAIGHT FLUSH"
			end_game(end_game_result, txt)
			return
			
	if(_table.currentPlayer == _table.players.size()):
		_table.currentPlayer = 0
	ServerUpdatePlayerList()
	
	
	if(!currentPlayer().disconnected && _table.getValidActions(currentPlayer()).size() == 1):
		PCheck(currentPlayer().id)
		onTurn()
		return
	
	if(currentPlayer().disconnected || _table.getValidActions(currentPlayer()).size() == 0):
		currentPlayer().played = true
		onTurn()
	else:
		setTurn.rpc(currentPlayer().id)
		setYourTurn.rpc_id(
			currentPlayer().id, 
			_table.calculateCash(currentPlayer()), 
			currentPlayer().bet, 
			_table.getValidActions(currentPlayer())
		)
	
func updateHands():
	for p in _table.players:
		updateHand.rpc_id(p.id,_table.cHand(p.hand),_table.calculateCash(p), p.bet)

var client_hand = []
var client_money = 0
var client_bet = 0


func parseHand(hand: String):
	var result = []
	var cards = hand.split(" ", false)
	for c in cards:
		var suit = _table.Card.suitType.HEART
		match c.left(1):
			'♦': suit = _table.Card.suitType.DIAMOND
			'♥': suit = _table.Card.suitType.HEART
			'♠': suit = _table.Card.suitType.SPADE
			'♣': suit = _table.Card.suitType.CLUB
		var value = c.substr(1,c.length() - 1)
		var valueInt = 0
		match value:
			"J": valueInt = 11
			"Q": valueInt = 12
			"K": valueInt = 13
			"A": valueInt = 14
			_: valueInt = int(value)
		var cardObject = _table.Card.new(suit, valueInt)
		result.push_back(cardObject)
	return result

func checkReady():
	if(_table.players.size() < 2):
		return false
	for p in _table.players:
		if p.ready == false && p.disconnected == false:
			return false
	return true

func setUnready():
	for p in _table.players:
		p.ready = false
			

func currentPlayer():
	if(_table.players.size() <= _table.currentPlayer || _table.currentPlayer == -1):
		return null
	return _table.players[_table.currentPlayer]

func indexPlayerByID(id):
	for i in range(_table.players.size()):
		if _table.players[i].id == id:
			return i
	return -1
	
var player_queue = [];

func _peer_connected(id):
	if(id == 1):
		l("HOST CONNECTION DETECTED!")
		PNickname.rpc_id(1,_nickname.text, avatar_id)
		return
	if(multiplayer.is_server()):
		var player = _table.Player.new()
		player.id = id
		if ingame:
			player_queue.push_back(player)
			l("PLAYER PUSHED INTO QUEUE : " + str(id))
			return
		else:
			_table.players.push_back(player)
		SetPlayerID.rpc_id(id,id)
		l("PLAYER CONNECTED : " + str(id))
	
@rpc("reliable")
func SetPlayerID(pID):
	myID = pID
var myID = -1
	
func _peer_disconnected(id):
	if(multiplayer.is_server()):
		for i in range(player_queue.size()-1,-1,-1):
				if player_queue[i].disconnected:
					player_queue.remove_at(i)
		_table.players[indexPlayerByID(id)].disconnected = true
		if(!ingame):
			for i in range(_table.players.size()-1,-1,-1):
				if _table.players[i].disconnected:
					_table.players.remove_at(i)
			ServerUpdatePlayerList()
		else:
			if(currentPlayer != null):
				if(currentPlayer().id == id):
					onTurn()
				else:
					setYourTurn.rpc_id(
						currentPlayer().id, 
						_table.calculateCash(currentPlayer()), 
						currentPlayer().bet, 
						_table.getValidActions(currentPlayer())
					)
	
	l("PEER DISCONNECTED : " + str(id))
	
func _server_disconnected():
	get_tree().reload_current_scene()
	l("SERVER DISCONNECTED")
	
func _connection_failed():
	get_tree().reload_current_scene()
	l("CONNECTION FAIL")
	
func _connected_to_server():
	l("SERVER CONNECTED")

func ServerUpdatePlayerList():
	var nicknames = []
	var ids = []
	var bids = []
	var avatars = []
	var money = []
	var blinds = []
	var readys = []
	var folded = []
	for p in _table.players:
		nicknames.push_back(p.nickname)
		ids.push_back(p.id)
		bids.push_back(p.bet)
		avatars.push_back(p.avatar_id)
		money.push_back(_table.calculateCash(p))
		blinds.push_back(p.blind)
		readys.push_back(p.ready)
		folded.push_back(p.folded)
	if(currentPlayer() != null):
		UpdatePlayerList.rpc(ids,nicknames,avatars,bids,money,blinds,currentPlayer().id,_table.pot, _table.currentBet, readys, folded )
	else:
		UpdatePlayerList.rpc(ids,nicknames,avatars,bids,money,blinds,-1,_table.pot, _table.currentBet, readys, folded )

@rpc("any_peer","reliable")
func PNickname(nickname, avatar_id):
	var id = multiplayer.get_remote_sender_id()
	if(multiplayer.is_server()):
		for p in player_queue:
			if(p.id == id):
				var n = nickname.substr(0,min(nickname.length(), 10))
				l("QUEUED PLAYER " + p.nickname + " CHANGED NICKNAME TO " + n + "!")
				p.nickname = n
				p.avatar_id = avatar_id
				return
		l("PLAYER " + _table.players[indexPlayerByID(id)].nickname + " CHANGED NICKNAME TO " + nickname + "!")
		var n = nickname.substr(0,min(nickname.length(), 10))
		_table.players[indexPlayerByID(id)].nickname = n
		_table.players[indexPlayerByID(id)].avatar_id = avatar_id
		ServerUpdatePlayerList()
		
func testAction(id, action):
	var act = _table.getValidActions(_table.players[indexPlayerByID(id)])
	for a in act:
		if a == action:
			return true
	return false

@rpc("any_peer","reliable")
func PCall(pID):
	var id = multiplayer.get_remote_sender_id()
	if(multiplayer.is_server()):
		if(currentPlayer() == null):
			return
		if(currentPlayer().id != id):
			l("PLAYER " + str(id) + " HAS TRIED TO CALL BUT IT WASN'T THEIR TURN.")
			return
		if testAction(id, _table.PLAYER_ACTIONS.CALL):
			_table.pCall(currentPlayer())
			l("PLAYER " + str(id) + " HAS CALLED!")
			PCall.rpc(id)
			onTurn()
		else:
			l("PLAYER " + str(id) + " HAS TRIED TO CALL BUT IT WASN'T AVAILABLE.")
	else:
		l("PLAYER " + str(pID) + " HAS CALLED!")
		playSound(_audio_call)
		
@rpc("any_peer","reliable")
func PCheck(pID):
	var id = multiplayer.get_remote_sender_id()
	if(multiplayer.is_server()):
		if(currentPlayer() == null):
			return
		if(currentPlayer().id != id):
			l("PLAYER " + str(id) + " HAS TRIED TO CHECK BUT IT WASN'T THEIR TURN.")
			return
		if testAction(id, _table.PLAYER_ACTIONS.CHECK):
			_table.pCheck(currentPlayer())
			l("PLAYER " + str(id) + " HAS CHECKED!")
			PCheck.rpc(id)
			onTurn()
		else:
			l("PLAYER " + str(id) + " HAS TRIED TO CHECK BUT IT WASN'T AVAILABLE.")
	else:
		l("PLAYER " + str(pID) + " HAS CHECKED!")
		playSound(_audio_check)

@rpc("reliable")
func PReady():
	playReadySound()

@rpc("any_peer","reliable")
func PFold(pID):
	var id = multiplayer.get_remote_sender_id()
	if(multiplayer.is_server()):
		if(currentPlayer() == null):
			return
		if(currentPlayer().id != id):
			l("PLAYER " + str(id) + " HAS TRIED TO FOLD BUT IT WASN'T THEIR TURN.")
			return
		if testAction(id, _table.PLAYER_ACTIONS.FOLD):
			_table.pFold(currentPlayer())
			l("PLAYER " + str(id) + " HAS FOLDED!")
			PFold.rpc(id)
			onTurn()
		else:
			l("PLAYER " + str(id) + " HAS TRIED TO FOLD BUT IT WASN'T AVAILABLE.")
	else:
		l("PLAYER " + str(pID) + " HAS FOLDED!")
		playSound(_audio_fold)
		
@rpc("any_peer","reliable")
func PBet(pID, value):
	var id = multiplayer.get_remote_sender_id()
	if(multiplayer.is_server()):
		if(currentPlayer() == null):
			return
		if(currentPlayer().id != id):
			l("PLAYER " + str(id) + " HAS TRIED TO BET BUT IT WASN'T THEIR TURN.")
			return
		if testAction(id, _table.PLAYER_ACTIONS.BET):
			if(value < 1):
				l("PLAYER " + str(id) + " HAS TRIED TO BET LESS THAN 1$. DUMBASS!")
				return
			_table.pBet(currentPlayer(), value)
			l("PLAYER " + str(id) + " HAS BET!")
			PBet.rpc(id, value)
			onTurn()
		else:
			l("PLAYER " + str(id) + " HAS TRIED TO BET BUT IT WASN'T AVAILABLE.")
	else:
		l("PLAYER " + str(pID) + " HAS BET!")
		_titleSequence.announce("RAISED TO " + str(value) + "$")
		_noisePlayer.stream = _audio_raise
		_noisePlayer.play()

func getLocalPlayerByID(id):
	if(mLocalPlayer != null):
		if(id == mLocalPlayer.id):
			return mLocalPlayer
	for p in player_list:
		if p.id == id:
			return p
	return null

@rpc("reliable")
func setTurn(player):
	l("IT'S NOW " + str(player) + "'s TURN")
	var p = getLocalPlayerByID(player)
	if(p != null):
		#_titleSequence.announce(p.nickname + "'s TURN")
		_playControls.hide()

func isAction(actions, a):
	for action in actions:
		if action == a:
			return true
	return false

@rpc("reliable")
func setYourTurn(money, bet, actions):
	client_money = money
	client_bet = bet
	l("IT'S NOW YOUR TURN")
	#_titleSequence.announce("YOUR TURN")
	l("YOU HAVE " + str(client_money) + "$ and have bet " + str(client_bet) + "$")
	_raiseSlider.min_value = 1
	_raiseSlider.step = 1
	_raiseSlider.value = 25
	_raiseSlider.max_value = mLocalPlayer.money
	
	
	if(isAction(actions,_table.PLAYER_ACTIONS.CALL)):
		_callButton.show()
	else:
		_callButton.hide()
		
	if(isAction(actions,_table.PLAYER_ACTIONS.CHECK)):
		_checkButton.show()
	else:
		_checkButton.hide()
		
	if(isAction(actions,_table.PLAYER_ACTIONS.BET)):
		_raiseButton.show()
		_raiseBar.show()
		_raiseLabel.show()
	else:
		_raiseButton.hide()
		_raiseBar.hide()
		_raiseLabel.hide()
	if(isAction(actions,_table.PLAYER_ACTIONS.FOLD)):
		_foldButton.show()
	else:
		_foldButton.hide()
	
	_playControls.show()

@rpc("reliable")
func updateHand(hand, money, bet):
	_lobby.hide()
	_clientControls.show()
	_assets.show()
	client_money = money
	client_bet = bet
	client_hand = parseHand(hand)
	for i in range(client_hand.size()):
		_hand[i].updateCard(client_hand[i].suit, str(_table.cValue(client_hand[i].value)))
	l("RECEIVED AND PARSED HAND: " + _table.cHand(client_hand));
	l("CASH: " + str(client_money) + " BET:" + str(client_bet));
	
@rpc("reliable")
func updateTable(table):
	_table.table = parseHand(table)
	updateTableClient()
	l("RECEIVED AND PARSED TABLE: " + _table.cHand(_table.table));

func updateTableClient():
	for i in range(_flop.size()):
		if(i < _table.table.size()):
			if(_flop[i].visible):
				_flop[i].showCard(_table.table[i].suit, str(_table.cValue(_table.table[i].value)))
			else:
				_flop[i].show()
				_flop[i].updateCard(_table.table[i].suit, str(_table.cValue(_table.table[i].value)))
			continue;
		_flop[i].hide()

var mLocalPlayer = null
var pot = 0
var currentBet = 0


func resetPlayerFound():
	for lp in _playerIcons.get_children():
		lp.found = false

@rpc("any_peer", "reliable")
func UpdatePlayerList(ids, nicknames, avat, bets, money, blinds, turnId, pot, currentBet, readys, folded):
	for c in _hand:
		c.show()
	#for c in _playerIcons.get_children():
		#_playerIcons.remove_child(c)
	for c in _player_list.get_children():
		_player_list.remove_child(c)
		c.queue_free()
	
	player_list = []
	l("GOT A PLAYERLIST!")
	var mark = 0
	for i in range(ids.size()):
		var lp = getLocalPlayerByID(ids.size())
		if (lp == null):
			if(ids[i]==myID):
				mark = i
				if(mLocalPlayer == null):
					var lpp = LocalPlayer.new()
					mLocalPlayer = lpp
				lp = mLocalPlayer
			else:
				lp = LocalPlayer.new()
				player_list.push_back(lp)
		lp.id = ids[i]
		if(lp.id == turnId):
			lp.isTurn = true
		lp.nickname = nicknames[i]
		lp.avatar_id = avat[i]
		lp.bet = bets[i]
		lp.money = money[i]
		lp.blind = blinds[i]
		lp.ready = readys[i]
		lp.folded = folded[i]
		l("Loaded player " + str(lp.nickname) 
		+ " with a " + str(lp.bet) + "$ bet/" 
		+ str(lp.money) + "$ total, and the " + str(lp.blind) + " blind.")
		var la = Label.new()
		la.text = nicknames[i] + ":" + str(money[i]) + "$"
		_player_list.add_child(la)	
	#for i in range(mark):
		#player_list.push_back(player_list.pop_front())
	#player_list.reverse()
	resetPlayerFound()
	for i in range(player_list.size()):
		var fPlayer = false
		for p in _playerIcons.get_children():
			if p.id == player_list[i].id:
				p.found = true
				fPlayer = true
				p.updatePlayer(player_list[i].nickname, avatars[player_list[i].avatar_id], player_list[i].money, player_list[i].blind, player_list[i].bet, turnId == player_list[i].id, player_list[i].ready, player_list[i].folded)
				var offsetX = (1280)/(player_list.size()+1)
				var totalOffsetX = offsetX*(i+1)
				p.position = Vector2(totalOffsetX-100,0);
				p.flip_h = i < (player_list.size()/2)
				p.readyImage.flip_h = i < (player_list.size()/2)
				p.id = player_list[i].id
				break;
		if (!fPlayer):
			var pI : TextureRect = player_icon.instantiate()
			pI.updatePlayer(player_list[i].nickname, avatars[player_list[i].avatar_id], player_list[i].money, player_list[i].blind,player_list[i].bet, turnId == player_list[i].id, player_list[i].ready, player_list[i].folded)
			var offsetX = (1280)/(player_list.size()+1)
			var totalOffsetX = offsetX*(i+1)
			pI.position = Vector2(totalOffsetX-100,0);
			pI.flip_h = i < (player_list.size()/2)
			pI.readyImage.flip_h = i < (player_list.size()/2)
			pI.id = player_list[i].id
			pI.found = true
			_playerIcons.add_child(pI)
	if(mLocalPlayer != null):
		_myPlayerIcon.show()
		_myPlayerIcon.updatePlayer(mLocalPlayer.nickname, avatars[mLocalPlayer.avatar_id], mLocalPlayer.money, mLocalPlayer.blind, mLocalPlayer.bet, turnId == mLocalPlayer.id, mLocalPlayer.ready, mLocalPlayer.folded)
	_potLabel.text = "Pot: " + str(pot) + "$"
	for i in range(_playerIcons.get_children().size()-1,-1,-1):
		if(!_playerIcons.get_children()[i].found):
			var p = _playerIcons.get_children()[i]
			_playerIcons.remove_child(p)	
			p.queue_free()
	
	
func _on_call_pressed():
	if(!multiplayer.is_server()):
		PCall.rpc_id(1,0)
	pass

func _on_fold_pressed():
	if(!multiplayer.is_server()):
		PFold.rpc_id(1,0)
	pass

func _on_bet_pressed():
	if(!multiplayer.is_server()):
		PBet.rpc_id(1,0,int(_raiseSlider.value))
	pass

func _on_check_pressed():
	if(!multiplayer.is_server()):
		PCheck.rpc_id(1,0)
	pass


func _on_bet_slider_value_changed(value):
	_raiseLabel.text = "Raise by " + str(int(value)) + "$"
	pass


func _on_raise_decrease_pressed():
	_raiseSlider.value -= 25
	pass # Replace with function body.


func _on_raise_increase_pressed():
	_raiseSlider.value += 25
	pass # Replace with function body.

@rpc("any_peer", "reliable")
func ShowHands(id, hand):
	if(multiplayer.is_server()):
		return
	for p in _playerIcons.get_children():
		if p.id == id:
			p.showCards(parseHand(hand))
			break
	if (id == mLocalPlayer.id):
		for i in range(client_hand.size()):
			_hand[i].updateCard(client_hand[i].suit, _table.cValue(client_hand[i].value))

@rpc("any_peer","reliable")
func PShowHands():
	if(multiplayer.is_server()):
		if(ingame):
			return
		var id = multiplayer.get_remote_sender_id()
		for p in _table.players:
			var idx = indexPlayerByID(id)
			if(idx != -1):
				ShowHands.rpc(id, _table.cHand(_table.players[idx].hand))
			else:
				l("PLAYER " + id + " TRIED TO SHOW HANDS, BUT FAILED!")
	pass

func _on_show_hands_pressed():
	if(mLocalPlayer != null):
		PShowHands.rpc_id(1)
	pass # Replace with function body.
