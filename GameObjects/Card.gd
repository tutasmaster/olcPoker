extends Node2D

@export var valueLabel1 : Label
@export var valueLabel2 : Label
@export var sprite : Sprite2D
@export var animationPlayer : AnimationPlayer
@export var audioPlayer: AudioStreamPlayer
var sprites = [preload("res://Cards/Hearts.png"),
				preload("res://Cards/Diamonds.png"),
				preload("res://Cards/Spades.png"),
				preload("res://Cards/Clubs.png"),
				preload("res://Cards/Back.png")]
var labelAssets = [preload("res://GameObjects/CardLabelRed.tres"),
				preload("res://GameObjects/CardLabelRed.tres")]
var value = 'A'
var suit = 4


@export var scaleMultiplier = Vector2(2,2)
@export var positionOffset = Vector2(0,-34)

var startScale = Vector2()
var startPosition = Vector2()

func _ready():
	startScale = scale
	startPosition = position

func _on_mouse_entered():
	scale = Vector2(startScale.x*scaleMultiplier.x,startScale.y*scaleMultiplier.y)
	position.y = startPosition.y + positionOffset.y
	z_index = 1


func _on_mouse_exited():
	scale = Vector2(startScale.x,startScale.y)
	position.y = startPosition.y
	z_index = 0
	
func flipCard():
	showCard(value, suit)

func showCard(s,v):
	sprite.set_texture(sprites[suit])
	if(suit < 2):
		valueLabel1.modulate = Color(0.861,0.332,0.292,1)
		valueLabel2.modulate = Color(0.861,0.332,0.292,1)
	else:
		valueLabel1.modulate = Color(0.3,0.3,0.3,1)
		valueLabel2.modulate = Color(0.3,0.3,0.3,1)
	valueLabel1.text = value
	valueLabel2.text = value
	valueLabel1.show()
	valueLabel2.show()
	
func hideCard():
	animationPlayer.stop()
	updateCard(4,"")

var muted = false

func updateCard(s,v):
	suit = s
	value = v
	animationPlayer.play("flip")
	if(!muted):
		audioPlayer.play()

func _process(delta):
	pass

