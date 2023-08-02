extends TextureRect

@export var nicknameLabel : Label
@export var moneyLabel : Label
@export var avatarTexture : TextureRect
@export var blindRect : TextureRect
@export var turnRect : AnimatedSprite2D
@export var cards: Array[Node2D]
@export var betLabel: Label
@export var readyImage: TextureRect

var found = false;

var id = -1

var blinds = [null,
			preload("res://Avatars/BB.png"),
			preload("res://Avatars/SB.png"),
			preload("res://Avatars/D.png")]

func updatePlayer(nickname, avatar, money, blind, bet, isTurn, isReady = false, isFolded = false):
	nicknameLabel.text = nickname
	avatarTexture.texture = avatar
	if(isFolded):
		avatarTexture.modulate = Color(1,1,1,0.4)
	else:
		avatarTexture.modulate = Color(1,1,1,1)
	moneyLabel.text = str(money) + "$"
	blindRect.set_texture(blinds[blind])
	betLabel.text = str(bet) + "$"
	if isTurn:
		turnRect.show()
		turnRect.play()
	else:
		turnRect.hide()
		
	if isReady:
		readyImage.show()
	else:
		readyImage.hide()
		
		
func cValue(val):
	match val:
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
	return str(val)
	
func showCards(hand):
	for i in range(hand.size()):
		cards[i].updateCard(hand[i].suit, cValue(hand[i].value))
		
func hideCards():
	for i in range(cards.size()):
		cards[i].hideCard()
