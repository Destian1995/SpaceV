extends CanvasLayer

# References — assigned in scene
@onready var lbl_credits: Label = $TopBar/Credits
@onready var lbl_day: Label    = $TopBar/Day
@onready var lbl_location: Label = $TopBar/Location

@onready var bar_hull: ProgressBar    = $ShipPanel/Hull/Bar
@onready var bar_shields: ProgressBar = $ShipPanel/Shields/Bar
@onready var bar_engines: ProgressBar = $ShipPanel/Engines/Bar
@onready var bar_weapons: ProgressBar = $ShipPanel/Weapons/Bar

@onready var crew_list: VBoxContainer = $CrewPanel/List
@onready var event_popup: PanelContainer = $EventPopup
@onready var event_title: Label  = $EventPopup/VBox/Title
@onready var event_desc: Label   = $EventPopup/VBox/Desc
@onready var event_choices: VBoxContainer = $EventPopup/VBox/Choices

func _ready() -> void:
	GameManager.credits_changed.connect(_on_credits_changed)
	event_popup.hide()

func update_hull(value: float, max_value: float) -> void:
	bar_hull.max_value = max_value
	bar_hull.value = value

func update_shields(pct: float) -> void:
	bar_shields.value = pct

func update_location(system_name: String) -> void:
	lbl_location.text = "📍 " + system_name

func show_event(event: Dictionary) -> void:
	event_title.text = event["title"]
	event_desc.text  = event["desc"]
	# Clear old buttons
	for child in event_choices.get_children():
		child.queue_free()
	# Add choice buttons
	for choice_text in event["choices"]:
		var btn := Button.new()
		btn.text = choice_text
		btn.pressed.connect(_on_event_choice.bind(event, choice_text))
		event_choices.add_child(btn)
	event_popup.show()

func _on_event_choice(event: Dictionary, choice: String) -> void:
	print("[HUD] Event '%s' → choice: '%s'" % [event["id"], choice])
	event_popup.hide()
	# TODO: dispatch to EventDirector result handler

func _on_credits_changed(amount: int) -> void:
	lbl_credits.text = "💰 %d" % amount
