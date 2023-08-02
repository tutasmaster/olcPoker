extends AnimationPlayer

@export var label: Label
@export var subLabel: Label

func _ready():
	pass # Replace with function body.

func announce(text, subtext = ""):
	stop()
	label.text = text
	subLabel.text = subtext
	play("announce")
