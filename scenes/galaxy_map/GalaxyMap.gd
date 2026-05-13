extends Node2D

const SYSTEMS = [
	# Core systems
	{"name": "Sol Prime",      "pos": Vector2( 480,  340), "faction": "Федерация",   "danger": 1, "color": Color(0.45, 0.85, 1.0),  "size": 11, "is_hq": true},
	{"name": "Krath Station",  "pos": Vector2( 750,  190), "faction": "Федерация",   "danger": 2, "color": Color(0.35, 0.65, 1.0),  "size": 9},
	{"name": "Auren Gate",     "pos": Vector2( 310,  195), "faction": "Торговцы",    "danger": 2, "color": Color(0.3,  1.0,  0.6),  "size": 10, "is_hq": true},
	{"name": "Nova Reach",     "pos": Vector2( 140,  360), "faction": "Независимые", "danger": 2, "color": Color(0.6,  0.9,  0.7),  "size": 8,  "is_hq": true},
	# Mid-rim
	{"name": "Vega Drift",     "pos": Vector2( 230,  510), "faction": "Независимые", "danger": 3, "color": Color(0.95, 0.95, 0.3),  "size": 10},
	{"name": "Pyrox",          "pos": Vector2( 840,  530), "faction": "Империя",     "danger": 3, "color": Color(1.0,  0.52, 0.22), "size": 9},
	{"name": "Helion Crossing","pos": Vector2( 600,  250), "faction": "Торговцы",    "danger": 2, "color": Color(0.5,  1.0,  0.85), "size": 9},
	{"name": "Orion Breach",   "pos": Vector2( 970,  280), "faction": "Империя",     "danger": 3, "color": Color(1.0,  0.7,  0.25), "size": 8,  "is_hq": true},
	{"name": "Thalara",        "pos": Vector2( 380,  450), "faction": "Независимые", "danger": 3, "color": Color(0.7,  0.55, 1.0),  "size": 8},
	{"name": "Cassian Rift",   "pos": Vector2( 700,  400), "faction": "Независимые", "danger": 3, "color": Color(0.55, 0.8,  0.55), "size": 8},
	# Outer rim / danger
	{"name": "Scarlet Nebula", "pos": Vector2( 980,  450), "faction": "Пираты",      "danger": 4, "color": Color(1.0,  0.28, 0.28), "size": 10, "is_hq": true},
	{"name": "Echo Void",      "pos": Vector2( 580,  610), "faction": "Нет",         "danger": 5, "color": Color(0.5,  0.5,  0.72), "size": 9},
	{"name": "Malachar Deep",  "pos": Vector2( 160,  590), "faction": "Пираты",      "danger": 4, "color": Color(0.9,  0.35, 0.35), "size": 8},
	{"name": "Void Station",   "pos": Vector2( 860,  650), "faction": "Нет",         "danger": 5, "color": Color(0.4,  0.4,  0.65), "size": 9},
	{"name": "Terminus",       "pos": Vector2( 430,  650), "faction": "Пираты",      "danger": 4, "color": Color(1.0,  0.4,  0.2),  "size": 8},
	{"name": "Darkfall",       "pos": Vector2(1060,  580), "faction": "Нет",         "danger": 5, "color": Color(0.35, 0.35, 0.6),  "size": 8},
	# ── Расширение: 20 систем ──────────────────────────────────────────────────
	{"name": "Pax Harbor",     "pos": Vector2(  80,  260), "faction": "Федерация",   "danger": 1, "color": Color(0.4,  0.82, 1.0),  "size": 9},
	{"name": "Crux Station",   "pos": Vector2(  75,  460), "faction": "Федерация",   "danger": 2, "color": Color(0.35, 0.65, 0.95), "size": 8},
	{"name": "Silk Route",     "pos": Vector2( 490,   90), "faction": "Торговцы",    "danger": 2, "color": Color(0.28, 0.95, 0.55), "size": 9},
	{"name": "Drift Market",   "pos": Vector2( 760,  105), "faction": "Торговцы",    "danger": 3, "color": Color(0.22, 0.82, 0.50), "size": 8},
	{"name": "Echo Station",   "pos": Vector2( 340,  130), "faction": "Независимые", "danger": 2, "color": Color(0.65, 0.90, 0.65), "size": 8},
	{"name": "Relay Point",    "pos": Vector2( 360,  285), "faction": "Независимые", "danger": 2, "color": Color(0.62, 0.85, 0.65), "size": 8},
	{"name": "Hyperion Falls", "pos": Vector2( 660,  162), "faction": "Независимые", "danger": 2, "color": Color(0.58, 0.90, 0.70), "size": 9},
	{"name": "Forge Station",  "pos": Vector2( 175,  490), "faction": "Независимые", "danger": 3, "color": Color(0.70, 0.55, 0.88), "size": 8},
	{"name": "Binary Junction","pos": Vector2( 750,  490), "faction": "Независимые", "danger": 3, "color": Color(0.55, 0.78, 0.55), "size": 8},
	{"name": "Kron Pass",      "pos": Vector2( 905,  318), "faction": "Империя",     "danger": 3, "color": Color(0.95, 0.58, 0.18), "size": 8},
	{"name": "Iron Throne",    "pos": Vector2(1115,  202), "faction": "Империя",     "danger": 3, "color": Color(1.0,  0.60, 0.18), "size": 9},
	{"name": "Citadel Prime",  "pos": Vector2(1130,  405), "faction": "Империя",     "danger": 4, "color": Color(1.0,  0.48, 0.12), "size": 10, "is_hq": true},
	{"name": "Skull Haven",    "pos": Vector2( 680,  725), "faction": "Пираты",      "danger": 4, "color": Color(1.0,  0.28, 0.28), "size": 9},
	{"name": "Rogue Station",  "pos": Vector2( 285,  715), "faction": "Пираты",      "danger": 4, "color": Color(0.90, 0.22, 0.32), "size": 8},
	{"name": "Crimson Expanse","pos": Vector2(1060,  145), "faction": "Пираты",      "danger": 4, "color": Color(1.0,  0.22, 0.22), "size": 9},
	{"name": "Derelict Nexus", "pos": Vector2( 510,  780), "faction": "Нет",         "danger": 5, "color": Color(0.45, 0.45, 0.70), "size": 8},
	{"name": "Abyss Gate",     "pos": Vector2(1135,  645), "faction": "Нет",         "danger": 5, "color": Color(0.38, 0.38, 0.62), "size": 9},
	{"name": "Shadowrift",     "pos": Vector2( 120,  740), "faction": "Нет",         "danger": 5, "color": Color(0.35, 0.35, 0.60), "size": 8},
	{"name": "Wanderer's End", "pos": Vector2(1205,  495), "faction": "Нет",         "danger": 5, "color": Color(0.40, 0.40, 0.65), "size": 8},
	{"name": "Nebula Shrine",  "pos": Vector2( 870,  738), "faction": "Нет",         "danger": 5, "color": Color(0.48, 0.40, 0.70), "size": 9},
	# ── Расширение: ещё 15 систем ─────────────────────────────────────────────
	{"name": "Bastion",        "pos": Vector2( 250,  300), "faction": "Федерация",   "danger": 2, "color": Color(0.40, 0.80, 1.0),  "size": 9},
	{"name": "Crossroads",     "pos": Vector2( 550,  380), "faction": "Торговцы",    "danger": 2, "color": Color(0.28, 0.92, 0.55), "size": 9},
	{"name": "Storm Passage",  "pos": Vector2( 900,  110), "faction": "Независимые", "danger": 3, "color": Color(0.62, 0.88, 0.68), "size": 8},
	{"name": "Frontier Gate",  "pos": Vector2( 200,  155), "faction": "Федерация",   "danger": 2, "color": Color(0.38, 0.78, 1.0),  "size": 8},
	{"name": "Solar Depths",   "pos": Vector2( 630,  530), "faction": "Независимые", "danger": 3, "color": Color(0.60, 0.88, 0.62), "size": 8},
	{"name": "Amber Cross",    "pos": Vector2( 450,  260), "faction": "Торговцы",    "danger": 2, "color": Color(0.25, 0.88, 0.52), "size": 9},
	{"name": "Iron Veil",      "pos": Vector2(1040,  440), "faction": "Империя",     "danger": 4, "color": Color(1.0,  0.50, 0.14), "size": 9},
	{"name": "Dead Zone Alpha","pos": Vector2( 310,  830), "faction": "Нет",         "danger": 5, "color": Color(0.38, 0.38, 0.60), "size": 8},
	{"name": "Nebula Watch",   "pos": Vector2( 760,  820), "faction": "Нет",         "danger": 5, "color": Color(0.44, 0.38, 0.68), "size": 8},
	{"name": "Outer Reach",    "pos": Vector2(1280,  160), "faction": "Нет",         "danger": 5, "color": Color(0.36, 0.36, 0.58), "size": 8},
	{"name": "Vortex Station", "pos": Vector2( 460,  570), "faction": "Независимые", "danger": 3, "color": Color(0.65, 0.82, 0.62), "size": 8},
	{"name": "Archon Prime",   "pos": Vector2( 385,  355), "faction": "Федерация",   "danger": 2, "color": Color(0.42, 0.82, 1.0),  "size": 9},
	{"name": "Sunfall",        "pos": Vector2( 820,  240), "faction": "Пираты",      "danger": 3, "color": Color(1.0,  0.30, 0.30), "size": 8},
	{"name": "Ghost Sector",   "pos": Vector2( 595,  700), "faction": "Нет",         "danger": 5, "color": Color(0.40, 0.38, 0.62), "size": 8},
	{"name": "Binary Falls",   "pos": Vector2( 990,  700), "faction": "Нет",         "danger": 4, "color": Color(0.42, 0.42, 0.65), "size": 8},
	# ── Дальние рубежи: 20 новых систем ───────────────────────────────────────
	{"name": "Apex Station",   "pos": Vector2( 122,   85), "faction": "Федерация",   "danger": 1, "color": Color(0.42, 0.82, 1.0),  "size": 8},
	{"name": "Zenith Market",  "pos": Vector2( 488,   40), "faction": "Торговцы",    "danger": 1, "color": Color(0.28, 1.0,  0.62), "size": 8},
	{"name": "Aurora Relay",   "pos": Vector2( 835,   50), "faction": "Независимые", "danger": 2, "color": Color(0.62, 0.90, 0.68), "size": 8},
	{"name": "Hammer Point",   "pos": Vector2(1148,   90), "faction": "Империя",     "danger": 3, "color": Color(1.0,  0.55, 0.18), "size": 8},
	{"name": "Outer Sanctum",  "pos": Vector2(1292,  265), "faction": "Империя",     "danger": 4, "color": Color(1.0,  0.45, 0.10), "size": 10, "is_hq": true},
	{"name": "Void's Edge",    "pos": Vector2(1385,  432), "faction": "Нет",         "danger": 5, "color": Color(0.38, 0.38, 0.62), "size": 8},
	{"name": "Crimson Gate",   "pos": Vector2(1382,  162), "faction": "Пираты",      "danger": 4, "color": Color(1.0,  0.22, 0.28), "size": 9},
	{"name": "Pioneer's Rest", "pos": Vector2( 165,  135), "faction": "Федерация",   "danger": 1, "color": Color(0.40, 0.80, 1.0),  "size": 8},
	{"name": "Tradewind",      "pos": Vector2( 915,  170), "faction": "Торговцы",    "danger": 2, "color": Color(0.25, 0.90, 0.52), "size": 8},
	{"name": "Deep Haven",     "pos": Vector2( 225,  368), "faction": "Независимые", "danger": 2, "color": Color(0.60, 0.88, 0.68), "size": 8},
	{"name": "Nexus Hub",      "pos": Vector2( 645,  688), "faction": "Независимые", "danger": 3, "color": Color(0.58, 0.82, 0.60), "size": 8},
	{"name": "Corsair Cove",   "pos": Vector2(  50,  690), "faction": "Пираты",      "danger": 4, "color": Color(0.92, 0.22, 0.30), "size": 9},
	{"name": "Ravager's Rest", "pos": Vector2( 105,  845), "faction": "Пираты",      "danger": 5, "color": Color(1.0,  0.18, 0.22), "size": 8},
	{"name": "Frontier's End", "pos": Vector2(  50,  535), "faction": "Нет",         "danger": 5, "color": Color(0.35, 0.35, 0.60), "size": 8},
	{"name": "Solar Crown",    "pos": Vector2( 635,  115), "faction": "Торговцы",    "danger": 2, "color": Color(0.28, 0.95, 0.58), "size": 8},
	{"name": "Far Citadel",    "pos": Vector2(1418,  545), "faction": "Империя",     "danger": 4, "color": Color(1.0,  0.48, 0.12), "size": 9},
	{"name": "Abyssal Gate",   "pos": Vector2(1205,  835), "faction": "Нет",         "danger": 5, "color": Color(0.38, 0.38, 0.62), "size": 9},
	{"name": "Oblivion",       "pos": Vector2( 745,  962), "faction": "Нет",         "danger": 5, "color": Color(0.35, 0.35, 0.58), "size": 8},
	{"name": "Phantom Shore",  "pos": Vector2( 475,  932), "faction": "Нет",         "danger": 5, "color": Color(0.40, 0.38, 0.62), "size": 8},
	{"name": "Elysium Port",   "pos": Vector2( 348,  758), "faction": "Независимые", "danger": 4, "color": Color(0.65, 0.55, 0.90), "size": 9},
]

const CONNECTIONS = [
	[0,1],[0,2],[0,3],[0,4],[0,8],[0,9],
	[1,2],[1,6],[1,7],[1,9],
	[2,3],[2,8],
	[3,4],
	[4,8],[4,12],[4,14],
	[5,9],[5,10],[5,11],
	[6,7],[6,9],
	[7,10],
	[8,9],[8,14],
	[9,11],[9,5],
	[10,13],[10,15],
	[11,14],[11,13],
	[12,14],
	[13,15],
	[16,0],[16,3],[16,17],[16,21],
	[17,16],[17,3],[17,23],[17,33],
	[18,2],[18,6],[18,20],[18,22],
	[19,6],[19,1],[19,22],[19,26],
	[20,2],[20,18],[20,21],
	[21,0],[21,8],[21,20],[21,16],
	[22,6],[22,18],[22,19],[22,25],
	[23,3],[23,4],[23,17],[23,29],
	[24,9],[24,5],[24,28],[24,25],
	[25,7],[25,9],[25,24],[25,26],
	[26,7],[26,19],[26,27],[26,30],
	[27,26],[27,10],[27,32],[27,34],
	[28,14],[28,11],[28,24],[28,31],
	[29,12],[29,14],[29,23],[29,33],
	[30,7],[30,10],[30,26],
	[31,11],[31,14],[31,28],[31,35],
	[32,13],[32,15],[32,27],[32,34],
	[33,12],[33,29],[33,17],
	[34,15],[34,32],[34,27],
	[35,13],[35,28],[35,32],
	[36,16],[36,2],[36,21],[36,3],
	[37,0],[37,8],[37,9],[37,41],[37,47],
	[38,1],[38,19],[38,7],
	[39,16],[39,2],[39,20],
	[40,9],[40,11],[40,24],
	[41,6],[41,21],[41,0],[41,37],
	[42,25],[42,10],[42,27],
	[43,29],[43,33],
	[44,28],[44,35],
	[45,26],[45,30],
	[46,8],[46,11],[46,14],
	[47,21],[47,8],[47,0],[47,37],
	[48,1],[48,25],[48,6],
	[49,28],[49,31],[49,11],
	[50,13],[50,15],[50,32],
	# ── Connections for far-reach systems (51-70) ──────────────────────────────
	[51,58],[51,16],[51,39],
	[52,18],[52,65],[52,20],
	[53,19],[53,22],[53,38],
	[54,26],[54,30],[54,45],
	[55,45],[55,34],[55,26],[55,57],
	[56,34],[56,66],[56,55],
	[57,30],[57,45],[57,55],
	[58,51],[58,39],[58,16],
	[59,7],[59,25],[59,38],[59,53],
	[60,36],[60,21],[60,3],
	[61,28],[61,40],[61,11],
	[62,17],[62,33],[62,64],
	[63,33],[63,62],[63,43],
	[64,17],[64,62],[64,4],
	[65,6],[65,22],[65,52],
	[66,27],[66,42],[66,56],
	[67,35],[67,44],[67,32],
	[68,44],[68,69],[68,28],
	[69,43],[69,31],[69,68],
	[70,29],[70,43],[70,46],
]

# ── Космические явления (оригинальный масштаб) ────────────────────────────────
const PHENOMENA := [
	{"type": "blackhole",     "pos": Vector2(1180,  355), "name": "Аномалия X-1",       "size": 18, "radius": 210, "effect": "gravity_well"},
	{"type": "blackhole",     "pos": Vector2( 880,  395), "name": "Бездна Кай",         "size": 14, "radius": 190, "effect": "gravity_well"},
	{"type": "quasar",        "pos": Vector2( 700,  580), "name": "QSR-Alpha",          "size": 12, "radius": 185, "effect": "radiation"},
	{"type": "quasar",        "pos": Vector2( 260,  670), "name": "Двойное ядро",       "size": 10, "radius": 175, "effect": "radiation"},
	{"type": "pulsar",        "pos": Vector2( 400,  680), "name": "PSR-2271",           "size": 10, "radius": 165, "effect": "pulse_interference"},
	{"type": "pulsar",        "pos": Vector2(1070,  255), "name": "PSR-Kron",           "size":  9, "radius": 160, "effect": "pulse_interference"},
	{"type": "nebula",        "pos": Vector2( 540,  465), "name": "Туманность Ириса",   "size": 22, "radius": 230, "effect": "nebula_veil"},
	{"type": "nebula",        "pos": Vector2( 125,  330), "name": "Туманность Крейна",  "size": 18, "radius": 200, "effect": "nebula_veil"},
	{"type": "supernova",     "pos": Vector2(1055,  490), "name": "SN Реликт-7",        "size": 16, "radius": 195, "effect": "supernova_radiation"},
	{"type": "supernova",     "pos": Vector2( 205,  810), "name": "SN Пепел-3",         "size": 14, "radius": 180, "effect": "supernova_radiation"},
	{"type": "magnetar",      "pos": Vector2(1240,  595), "name": "MGT-Омега",          "size": 11, "radius": 175, "effect": "magnetic_storm"},
	{"type": "magnetar",      "pos": Vector2( 340,  570), "name": "MGT-Сигма",          "size": 10, "radius": 165, "effect": "magnetic_storm"},
	{"type": "ion_storm",     "pos": Vector2( 620,  185), "name": "Буря Ω-5",           "size": 14, "radius": 185, "effect": "ion_storm"},
	{"type": "ion_storm",     "pos": Vector2( 920,  680), "name": "Буря Дельта",        "size": 12, "radius": 175, "effect": "ion_storm"},
	{"type": "wormhole",      "pos": Vector2( 680,  308), "name": "Червоточина α",      "size": 10, "radius":  75, "effect": "wormhole", "pair_pos": Vector2(990, 595)},
	{"type": "wormhole",      "pos": Vector2( 990,  595), "name": "Червоточина β",      "size": 10, "radius":  75, "effect": "wormhole", "pair_pos": Vector2(680, 308)},
	{"type": "asteroid_field","pos": Vector2( 720,  680), "name": "Пояс Кандора",       "size": 20, "radius": 170, "effect": "asteroid_bonus"},
	{"type": "asteroid_field","pos": Vector2( 470,  148), "name": "Обломки Сириуса",    "size": 16, "radius": 155, "effect": "asteroid_bonus"},
]

const EFFECT_HALO_COLOR := {
	"gravity_well":        Color(0.90, 0.35, 0.08),
	"radiation":           Color(0.75, 0.18, 1.00),
	"pulse_interference":  Color(0.18, 1.00, 0.85),
	"nebula_veil":         Color(0.22, 0.50, 1.00),
	"supernova_radiation": Color(1.00, 0.55, 0.08),
	"magnetic_storm":      Color(1.00, 0.15, 0.80),
	"ion_storm":           Color(0.95, 0.90, 0.12),
	"asteroid_bonus":      Color(0.65, 0.52, 0.30),
	"wormhole":            Color(0.12, 0.92, 0.88),
}

# ── Константы прыжка ──────────────────────────────────────────────────────────
const JUMP_COST_PER_PX := 2.0
const JUMP_DAY_PX      := 130.0
const JUMP_MIN_COST    := 300
const FUEL_PER_PX      := 0.12
const TRAVEL_DUR       := 1.5

const ENCOUNTER_BASE   := 0.08
const ENCOUNTER_DANGER := 0.055

var current_idx:  int = 0
var selected_idx: int = -1
var bg_stars:     Array = []
var nebulae:      Array = []
var time_e:       float = 0.0

var _travel_active: bool    = false
var _travel_t:      float   = 0.0
var _travel_from:   Vector2 = Vector2.ZERO
var _travel_to:     Vector2 = Vector2.ZERO

# Камера (пан + зум)
var cam_pan:    Vector2 = Vector2.ZERO
var cam_zoom:   float   = 0.85        # комфортный масштаб для просмотра систем
var _dragging:  bool    = false
var _drag_from: Vector2 = Vector2.ZERO

# Режим детального осмотра явления
var _cv_active: bool       = false
var _cv_ph:     Dictionary = {}
var _cv_back_btn: Button   = null
var _ph_panel:  PanelContainer = null
var _ph_investigate_btn: Button = null

@onready var info_panel  = $UI/InfoPanel
@onready var lbl_name    = $UI/InfoPanel/VBox/SystemName
@onready var lbl_subname = $UI/InfoPanel/VBox/SubName
@onready var lbl_faction = $UI/InfoPanel/VBox/Faction
@onready var lbl_danger  = $UI/InfoPanel/VBox/Danger
@onready var dyn_info    = $UI/InfoPanel/VBox/DynInfo
@onready var btn_enter   = $UI/InfoPanel/VBox/EnterBtn
@onready var btn_jump    = $UI/InfoPanel/VBox/JumpBtn
@onready var lbl_credits  = $UI/TopBar/HBox/Credits
@onready var lbl_day      = $UI/TopBar/HBox/Day
@onready var lbl_location = $UI/TopBar/HBox/Location
@onready var lbl_status   = $UI/StatusLabel
@onready var btn_ship     = $UI/TopBar/HBox/ShipBtn
@onready var btn_menu     = $UI/TopBar/HBox/MenuBtn

func _ready() -> void:
	current_idx = GameManager.current_galaxy_idx
	_gen_background()
	info_panel.hide()
	btn_enter.pressed.connect(_on_enter)
	btn_jump.pressed.connect(_on_jump)
	btn_ship.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ship_view/ShipView.tscn"))
	btn_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Main.tscn"))
	var _cred_cb := func(v): lbl_credits.text = "💰 %d кред." % v
	GameManager.credits_changed.connect(_cred_cb)
	tree_exiting.connect(func(): GameManager.credits_changed.disconnect(_cred_cb))
	_refresh_topbar()
	lbl_status.text = "Текущая позиция: %s  |  🖱 Колёсико: зум  |  ЛКМ+тащи: пан  |  🔭 Нажми на явление" % SYSTEMS[current_idx]["name"]
	_add_bottom_bar()
	_build_ph_panel()

	# Центрировать камеру на текущей системе (defer — viewport может быть ещё не готов)
	call_deferred("_center_camera_on_current")
	queue_redraw()

func _center_camera_on_current() -> void:
	var vp := get_viewport_rect().size
	if vp == Vector2.ZERO:
		# Ещё не готов — повторим на следующий кадр
		call_deferred("_center_camera_on_current")
		return
	cam_pan = vp * 0.5 - SYSTEMS[current_idx]["pos"] * cam_zoom
	queue_redraw()

func _build_ph_panel() -> void:
	_ph_panel = PanelContainer.new()
	_ph_panel.anchor_left   = 1.0
	_ph_panel.anchor_right  = 1.0
	_ph_panel.anchor_top    = 0.5
	_ph_panel.anchor_bottom = 0.5
	_ph_panel.offset_left   = -340.0
	_ph_panel.offset_right  = -10.0
	_ph_panel.offset_top    = -130.0
	_ph_panel.offset_bottom =  130.0
	_ph_panel.hide()
	$UI.add_child(_ph_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_ph_panel.add_child(vb)

	var lbl_ph_name := Label.new()
	lbl_ph_name.name = "PhName"
	lbl_ph_name.add_theme_font_size_override("font_size", 18)
	lbl_ph_name.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	vb.add_child(lbl_ph_name)

	var lbl_ph_type := Label.new()
	lbl_ph_type.name = "PhType"
	lbl_ph_type.add_theme_font_size_override("font_size", 13)
	lbl_ph_type.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	vb.add_child(lbl_ph_type)

	var lbl_ph_effect := Label.new()
	lbl_ph_effect.name = "PhEffect"
	lbl_ph_effect.add_theme_font_size_override("font_size", 13)
	lbl_ph_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(lbl_ph_effect)

	_ph_investigate_btn = Button.new()
	_ph_investigate_btn.text = "🔭 Исследовать"
	_ph_investigate_btn.add_theme_font_size_override("font_size", 15)
	_ph_investigate_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.8))
	_ph_investigate_btn.pressed.connect(_on_investigate)
	vb.add_child(_ph_investigate_btn)

	var close_btn := Button.new()
	close_btn.text = "✕ Закрыть"
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(func(): _ph_panel.hide())
	vb.add_child(close_btn)

func _add_bottom_bar() -> void:
	var bottom_panel := PanelContainer.new()
	bottom_panel.anchor_left   = 0.0
	bottom_panel.anchor_top    = 1.0
	bottom_panel.anchor_right  = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_top    = -80.0
	bottom_panel.offset_bottom = -32.0
	$UI.add_child(bottom_panel)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 16)
	bottom_panel.add_child(hb)

	var enter_btn := Button.new()
	enter_btn.text = "🚀 Войти в систему"
	enter_btn.add_theme_font_size_override("font_size", 16)
	enter_btn.custom_minimum_size = Vector2(210, 44)
	enter_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
	enter_btn.pressed.connect(_on_enter)
	hb.add_child(enter_btn)

	var ship_btn2 := Button.new()
	ship_btn2.text = "🛸 Мой корабль"
	ship_btn2.add_theme_font_size_override("font_size", 16)
	ship_btn2.custom_minimum_size = Vector2(180, 44)
	ship_btn2.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ship_view/ShipView.tscn"))
	hb.add_child(ship_btn2)

	var save_btn := Button.new()
	save_btn.text = "💾 Сохранить"
	save_btn.add_theme_font_size_override("font_size", 16)
	save_btn.custom_minimum_size = Vector2(160, 44)
	save_btn.pressed.connect(func():
		GameManager.save_game()
		lbl_status.text = "✅ Игра сохранена!")
	hb.add_child(save_btn)

	var q_count: int = GameManager.active_quests.size()
	var quest_lbl := Label.new()
	quest_lbl.text = "📋 Квестов: %d" % q_count
	quest_lbl.add_theme_font_size_override("font_size", 15)
	var q_col := Color(0.3, 1.0, 0.55) if q_count > 0 else Color(0.5, 0.5, 0.6)
	quest_lbl.add_theme_color_override("font_color", q_col)
	quest_lbl.custom_minimum_size = Vector2(140, 0)
	quest_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hb.add_child(quest_lbl)

	# Кнопки зума
	var zoom_out := Button.new()
	zoom_out.text = "🔍−"
	zoom_out.add_theme_font_size_override("font_size", 16)
	zoom_out.custom_minimum_size = Vector2(60, 44)
	zoom_out.pressed.connect(func(): _apply_zoom(-0.08))
	hb.add_child(zoom_out)

	var zoom_in := Button.new()
	zoom_in.text = "🔍+"
	zoom_in.add_theme_font_size_override("font_size", 16)
	zoom_in.custom_minimum_size = Vector2(60, 44)
	zoom_in.pressed.connect(func(): _apply_zoom(0.08))
	hb.add_child(zoom_in)

	var menu_btn2 := Button.new()
	menu_btn2.text = "☰ Меню"
	menu_btn2.add_theme_font_size_override("font_size", 16)
	menu_btn2.custom_minimum_size = Vector2(110, 44)
	menu_btn2.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Main.tscn"))
	hb.add_child(menu_btn2)

func _apply_zoom(delta: float, pivot: Vector2 = Vector2(-1e9, -1e9)) -> void:
	var vp := get_viewport_rect().size
	if pivot.x < -1e8:
		pivot = vp * 0.5
	var old_zoom := cam_zoom
	cam_zoom = clampf(cam_zoom + delta, 0.08, 3.0)
	var ratio := cam_zoom / old_zoom
	cam_pan = pivot + (cam_pan - pivot) * ratio
	queue_redraw()

func _gen_background() -> void:
	var vp := get_viewport_rect().size
	var rng := RandomNumberGenerator.new()
	rng.seed = 77421

	var neb_cols := [
		Color(0.2,0.05,0.45,0.06), Color(0.05,0.15,0.5,0.05),
		Color(0.4,0.1,0.2,0.05),   Color(0.05,0.3,0.35,0.06),
	]
	for i in 22:
		nebulae.append({
			"pos": Vector2(rng.randf_range(0,vp.x), rng.randf_range(0,vp.y)),
			"r":   rng.randf_range(80, 220),
			"col": neb_cols[rng.randi() % neb_cols.size()],
			"ph":  rng.randf_range(0, TAU),
		})

	var palettes := [
		[1.0,1.0,1.0],[0.7,0.8,1.0],[0.5,0.6,1.0],
		[1.0,0.95,0.7],[1.0,0.75,0.45],[0.9,0.9,1.0],
	]
	for i in 600:
		var pal: Array = palettes[rng.randi() % palettes.size()]
		bg_stars.append({
			"pos": Vector2(rng.randf_range(0,vp.x*1.2), rng.randf_range(0,vp.y*1.2)),
			"r":   rng.randf_range(0.4, 2.4),
			"br":  rng.randf_range(0.3, 1.0),
			"ph":  rng.randf_range(0, TAU),
			"spd": rng.randf_range(0.3, 1.8),
			"cr": pal[0], "cg": pal[1], "cb": pal[2],
		})

func _process(delta: float) -> void:
	time_e += delta
	if _travel_active:
		_travel_t = minf(_travel_t + delta / TRAVEL_DUR, 1.0)
		if _travel_t >= 1.0:
			_travel_active = false
	queue_redraw()

# ── Конвертация экранных координат в мировые ──────────────────────────────────
func _screen_to_world(sp: Vector2) -> Vector2:
	return (sp - cam_pan) / cam_zoom

# ── Главная функция отрисовки ──────────────────────────────────────────────────
func _draw() -> void:
	var vp := get_viewport_rect().size

	# ── Режим детального осмотра явления ──────────────────────────────────────
	if _cv_active:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(0.005, 0.005, 0.018, 1.0))
		# Фоновые звёзды
		for s in bg_stars:
			var br: float = s["br"] + sin(time_e * s["spd"] + s["ph"]) * 0.15
			draw_circle(s["pos"], s["r"], Color(s["cr"]*br, s["cg"]*br, s["cb"]*br, min(br,1.0)))
		_draw_phenomenon_closeup(_cv_ph, vp)
		return

	# ── Фон (экранное пространство) ───────────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.008, 0.008, 0.022, 1))
	for n in nebulae:
		var pulse: float = sin(time_e * 0.18 + n["ph"]) * 0.008
		draw_circle(n["pos"], n["r"],
			Color(n["col"].r, n["col"].g, n["col"].b, n["col"].a + pulse))
		draw_circle(n["pos"], n["r"] * 0.55,
			Color(n["col"].r * 1.3, n["col"].g * 1.3, n["col"].b * 1.3, n["col"].a * 0.6))
	for s in bg_stars:
		var br: float = s["br"] + sin(time_e * s["spd"] + s["ph"]) * 0.2
		var sz: float = s["r"]  + sin(time_e * s["spd"] * 1.4 + s["ph"]) * 0.25
		sz = max(0.3, sz)
		draw_circle(s["pos"], sz, Color(s["cr"]*br, s["cg"]*br, s["cb"]*br, min(br,1.0)))

	# ── Мировые объекты (с трансформом камеры) ────────────────────────────────
	var xf := Transform2D()
	xf.x = Vector2(cam_zoom, 0.0)
	xf.y = Vector2(0.0, cam_zoom)
	xf.origin = cam_pan
	draw_set_transform_matrix(xf)

	# Явления
	for ph in PHENOMENA:
		_draw_phenomenon(ph)

	# Линии связи
	for c in CONNECTIONS:
		var a: Vector2 = SYSTEMS[c[0]]["pos"]
		var b: Vector2 = SYSTEMS[c[1]]["pos"]
		var is_active: bool = c[0] == current_idx or c[1] == current_idx
		var alpha: float = 0.55 if is_active else 0.28
		var col: Color = Color(0.35, 0.55, 0.9, alpha) if is_active else Color(0.18, 0.28, 0.55, alpha)
		if is_active:
			draw_line(a, b, Color(col.r,col.g,col.b,0.12), 4.0 / cam_zoom)
		draw_line(a, b, col, 1.5 / cam_zoom)

	# Системы
	for i in SYSTEMS.size():
		_draw_system(i)

	# Анимация перелёта
	if _travel_active:
		_draw_travel_dot()

	# Сбросить трансформ
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_travel_dot() -> void:
	var pos := _travel_from.lerp(_travel_to, _travel_t)
	var pulse := 0.7 + sin(time_e * 18.0) * 0.3
	for i in 10:
		var trail_t := _travel_t - float(i + 1) * 0.016
		if trail_t < 0.0: break
		var tp    := _travel_from.lerp(_travel_to, trail_t)
		var alpha := (1.0 - float(i) / 10.0) * 0.45 * pulse
		draw_circle(tp, maxf(3.0 - float(i) * 0.25, 0.5) / cam_zoom, Color(0.55, 0.85, 1.0, alpha))
	draw_circle(pos, 16.0 / cam_zoom, Color(0.35, 0.72, 1.0, 0.06 * pulse))
	draw_circle(pos, 10.0 / cam_zoom, Color(0.50, 0.85, 1.0, 0.14 * pulse))
	draw_circle(pos,  6.0 / cam_zoom, Color(0.70, 0.95, 1.0, 0.32 * pulse))
	draw_circle(pos,  3.5 / cam_zoom, Color(0.88, 0.98, 1.0, 0.75 * pulse))
	draw_circle(pos,  1.8 / cam_zoom, Color(1.0,  1.0,  1.0, 1.0))


# ── Детальный осмотр явления (только для исследовательских кораблей) ──────────
func _draw_phenomenon_closeup(ph: Dictionary, vp: Vector2) -> void:
	var center := vp * 0.5
	var sz := float(ph["size"]) * 7.5  # очень большой размер
	var t := time_e

	# Частичная копия _draw_phenomenon, но рисуется в центре экрана в screen-space
	# с повышенной детализацией
	match ph["type"]:
		"blackhole":
			var rot := t * 0.30
			for ring in 9:
				var rf := 1.0 + ring * 0.50
				var ra := sz * rf
				var rb := sz * rf * 0.38
				var al := 0.60 - ring * 0.06
				var rc := Color(0.88 - ring * 0.08, 0.42 - ring * 0.04, 0.10, al)
				for seg in 72:
					var a0 := float(seg) / 72.0 * TAU + rot * (1.0 - ring * 0.12)
					var a1 := float(seg+1) / 72.0 * TAU + rot * (1.0 - ring * 0.12)
					draw_line(center + Vector2(cos(a0)*ra, sin(a0)*rb),
							  center + Vector2(cos(a1)*ra, sin(a1)*rb),
							  rc, 1.5 + (3.0 - ring * 0.28) * 0.5)
			# Горячий газ внутри диска
			for pi2 in 60:
				var pa := float(pi2) / 60.0 * TAU + rot * 1.5
				var pr := sz * (0.8 + randf_range(-0.2, 0.4))
				var pb2 := sz * 0.38
				draw_circle(center + Vector2(cos(pa)*pr, sin(pa)*pb2),
							sz * 0.04, Color(1.0, 0.75, 0.3, 0.30))
			draw_circle(center, sz * 3.5, Color(0.55, 0.18, 0.05, 0.05))
			draw_circle(center, sz * 2.2, Color(0.70, 0.28, 0.08, 0.09))
			draw_circle(center, sz * 1.1, Color(0.80, 0.35, 0.10, 0.14))
			draw_circle(center, sz * 0.95, Color(0.02, 0.01, 0.04, 1.0))
			draw_circle(center, sz * 0.70, Color(0.0, 0.0, 0.0, 1.0))
			draw_circle(center, sz * 0.25, Color(0.0, 0.0, 0.0, 1.0))

		"quasar":
			var pulse := 0.55 + sin(t * 3.8) * 0.40
			var pulse2 := 0.5 + sin(t * 5.2 + 1.0) * 0.45
			draw_circle(center, sz * 5.0, Color(0.55, 0.20, 1.0, 0.03 * pulse))
			draw_circle(center, sz * 3.5, Color(0.65, 0.28, 1.0, 0.06 * pulse))
			draw_circle(center, sz * 2.2, Color(0.75, 0.40, 1.0, 0.10 * pulse))
			draw_circle(center, sz * 1.4, Color(0.85, 0.55, 1.0, 0.16 * pulse))
			var jet_angle := t * 0.12
			var jet_len := sz * 9.0
			var jet_fwd := Vector2(cos(jet_angle), sin(jet_angle))
			for ji in 10:
				var jf := float(ji + 1) / 10.0
				var jw := 5.0 * (1.0 - jf) + 0.5
				var ja := (0.25 * pulse) * (1.0 - jf)
				draw_line(center + jet_fwd * sz * 1.2 * jf, center + jet_fwd * jet_len * jf,
						  Color(0.75, 0.45, 1.0, ja), jw)
				draw_line(center - jet_fwd * sz * 1.2 * jf, center - jet_fwd * jet_len * jf,
						  Color(0.75, 0.45, 1.0, ja), jw)
			# Ядро с деталями
			draw_circle(center, sz * 1.1, Color(0.60, 0.25, 1.0, 0.90))
			draw_circle(center, sz * 0.70, Color(0.80, 0.55, 1.0, pulse2))
			for ci in 20:
				var ca := float(ci) / 20.0 * TAU + t * 0.5
				var cr := sz * (0.3 + sin(t * 2.0 + ci) * 0.1)
				draw_circle(center + Vector2(cos(ca)*cr, sin(ca)*cr), sz * 0.04,
							Color(1.0, 0.9, 1.0, 0.8))
			draw_circle(center, sz * 0.35, Color(1.0, 0.90, 1.0, 1.0))
			draw_circle(center, sz * 0.12, Color(1.0, 1.0, 1.0, 1.0))

		"pulsar":
			var spin := fmod(t * 2.8, TAU)
			var beam_len := sz * 11.0
			var beam_pulse := 0.5 + sin(t * 14.0) * 0.45
			for bi in 2:
				var ba := spin + float(bi) * PI
				var bdir := Vector2(cos(ba), sin(ba))
				for bw in 7:
					var bf := float(bw + 1) / 7.0
					var balf := (1.0 - bf) * 0.65 * beam_pulse
					draw_line(center + bdir * sz * 1.0, center + bdir * beam_len * bf,
							  Color(0.35, 1.0, 0.85, balf), 5.0 * (1.0 - bf * 0.6))
			# Конус рассеивания
			for ci in 3:
				var spread := (float(ci) + 1.0) * 0.05
				for bi in 2:
					var ba := spin + float(bi) * PI
					var bdir := Vector2(cos(ba + spread), sin(ba + spread))
					draw_line(center, center + bdir * beam_len * 0.8,
							  Color(0.35, 1.0, 0.85, 0.08 * beam_pulse), 1.5)
					bdir = Vector2(cos(ba - spread), sin(ba - spread))
					draw_line(center, center + bdir * beam_len * 0.8,
							  Color(0.35, 1.0, 0.85, 0.08 * beam_pulse), 1.5)
			var flash := maxf(0.0, sin(t * 14.0))
			draw_circle(center, sz * 3.0, Color(0.35, 1.0, 0.85, flash * 0.12))
			draw_circle(center, sz * 1.8, Color(0.50, 1.0, 0.90, flash * 0.20))
			draw_circle(center, sz * 0.85, Color(0.20, 0.70, 0.65, 0.90))
			draw_circle(center, sz * 0.55, Color(0.50, 1.0, 0.90, 0.95))
			draw_circle(center, sz * 0.25, Color(0.90, 1.0, 1.0, 1.0))
			draw_circle(center, sz * 0.10, Color(1.0, 1.0, 1.0, 1.0))

		"nebula":
			var pulse := 0.5 + sin(t * 0.55) * 0.22
			var rng_neb := RandomNumberGenerator.new()
			rng_neb.seed = hash(ph["name"] + "cv")
			for layer in 40:
				var ang := rng_neb.randf_range(0, TAU)
				var dist_neb := rng_neb.randf_range(sz * 0.3, sz * 4.5)
				var rsz2 := rng_neb.randf_range(sz * 0.5, sz * 2.0)
				var hue_s := sin(t * 0.2 + layer * 0.3) * 0.08
				var cols := [
					Color(0.18+hue_s, 0.28, 0.85, 0.08*pulse),
					Color(0.38, 0.15+hue_s, 0.70, 0.10*pulse),
					Color(0.55, 0.32, 0.90, 0.08*pulse),
					Color(0.72, 0.20, 0.65, 0.07*pulse),
				]
				draw_circle(center + Vector2(cos(ang)*dist_neb, sin(ang)*dist_neb), rsz2, cols[layer % 4])
			draw_circle(center, sz * 2.8, Color(0.30, 0.20, 0.75, 0.06 * pulse))
			draw_circle(center, sz * 1.5, Color(0.45, 0.30, 0.88, 0.12 * pulse))
			draw_circle(center, sz * 0.8, Color(0.65, 0.48, 0.95, 0.25 * pulse))
			draw_circle(center, sz * 0.35, Color(0.88, 0.75, 1.0, 0.55 * pulse))
			draw_circle(center, sz * 0.12, Color(1.0,  0.95, 1.0, 0.90 * pulse))

		"supernova":
			var expand := fmod(t * 0.18, 1.0)
			var wave_r := sz * (2.2 + expand * 4.0)
			for wi in 5:
				var wr := wave_r - float(wi) * sz * 0.55
				if wr > 0:
					draw_arc(center, wr, 0, TAU, 64,
						Color(1.0, 0.55 - wi*0.10, 0.08, (1.0-expand)*0.20*(1.0-wi*0.18)),
						2.0 - wi * 0.3)
			draw_circle(center, sz * 4.5, Color(1.0, 0.40, 0.05, 0.04))
			draw_circle(center, sz * 3.0, Color(1.0, 0.55, 0.12, 0.07))
			var rng_sv := RandomNumberGenerator.new()
			rng_sv.seed = hash(ph["name"] + "svcv")
			for fi in 24:
				var fa := float(fi) / 24.0 * TAU + t * 0.03
				var fl := sz * (2.2 + rng_sv.randf_range(0.5, 3.0))
				draw_line(center + Vector2(cos(fa), sin(fa)) * sz * 0.5,
						  center + Vector2(cos(fa), sin(fa)) * fl,
						  Color(1.0, 0.62, 0.18, 0.15), 1.2)
			var cp := 0.5 + sin(t * 8.0) * 0.42
			draw_circle(center, sz * 0.70, Color(0.50, 0.85, 1.0, 0.90))
			draw_circle(center, sz * 0.42, Color(0.80, 0.95, 1.0, cp))
			draw_circle(center, sz * 0.20, Color(1.0, 1.0, 1.0, 1.0))
			draw_circle(center, sz * 0.08, Color(1.0, 1.0, 1.0, 1.0))

		"magnetar":
			var m_spin := t * 1.8
			var burst := maxf(0.0, sin(t * 6.5))
			for mi in 8:
				var ma := float(mi) / 8.0 * TAU * 0.5 + m_spin
				var mb := ma + PI
				var mid_off := Vector2(cos(ma + PI * 0.5), sin(ma + PI * 0.5)) * sz * 3.5
				var pa := center + Vector2(cos(ma), sin(ma)) * sz * 1.4
				var pb := center + Vector2(cos(mb), sin(mb)) * sz * 1.4
				for seg2 in 20:
					var sf := float(seg2) / 20.0
					var ef := float(seg2 + 1) / 20.0
					var lp0 := pa.lerp(pb, sf) + mid_off * sin(sf * PI)
					var lp1 := pa.lerp(pb, ef) + mid_off * sin(ef * PI)
					draw_line(lp0, lp1, Color(1.0, 0.18, 0.82, 0.25 + burst * 0.15), 1.2)
			draw_circle(center, sz * 3.0, Color(1.0, 0.15, 0.80, burst * 0.12))
			draw_circle(center, sz * 1.8, Color(1.0, 0.28, 0.88, burst * 0.20))
			draw_circle(center, sz * 0.80, Color(0.72, 0.08, 0.65, 0.92))
			draw_circle(center, sz * 0.50, Color(0.90, 0.30, 0.92, 0.96))
			draw_circle(center, sz * 0.25, Color(1.0, 0.82, 1.0, 1.0))
			draw_circle(center, sz * 0.10, Color(1.0, 1.0, 1.0, 1.0))

		"ion_storm":
			var i_swirl := t * 1.2
			var zap := maxf(0.0, sin(t * 9.5 + 0.7))
			for li in 48:
				var a0 := float(li) / 48.0 * TAU + i_swirl + sin(t * 0.4 + li) * 0.3
				var a1 := a0 + 0.22 + sin(t * 0.6 + li * 0.8) * 0.10
				var r0 := sz * (1.1 + sin(t * 0.7 + li * 0.5) * 0.4)
				var r1 := sz * (2.0 + sin(t * 0.5 + li * 0.7) * 0.6)
				draw_line(center + Vector2(cos(a0)*r0, sin(a0)*r0),
						  center + Vector2(cos(a1)*r1, sin(a1)*r1),
						  Color(0.95, 0.88, 0.12, 0.22 + zap * 0.12), 1.2)
			for zi in 8:
				var za := float(zi) / 8.0 * TAU + i_swirl * 1.5
				var zlen := sz * (2.5 + sin(t * 3.0 + zi * 1.3) * 1.0)
				draw_line(center, center + Vector2(cos(za)*zlen, sin(za)*zlen),
						  Color(0.98, 0.95, 0.35, zap * 0.60), 2.0)
			draw_circle(center, sz * 1.5, Color(0.95, 0.88, 0.15, 0.10 + zap * 0.08))
			draw_circle(center, sz * 0.80, Color(0.98, 0.95, 0.28, 0.78))
			draw_circle(center, sz * 0.45, Color(1.0, 1.0, 0.70, 0.92))
			draw_circle(center, sz * 0.20, Color(1.0, 1.0, 1.0, 1.0))

		"wormhole":
			var w_spin := t * 1.5
			var ring_pulse := 0.55 + sin(t * 4.2) * 0.38
			for ri in 6:
				var rr := sz * (0.7 + ri * 0.35)
				draw_arc(center, rr, w_spin + ri * TAU / 6.0,
						 w_spin + ri * TAU / 6.0 + TAU * 0.65, 48,
						 Color(0.12, 0.92, 0.88, ring_pulse * (0.60 - ri * 0.08)), 2.0 - ri * 0.25)
			# Пространственное искажение — концентрические волны
			for wi in 4:
				var wr := sz * (1.5 + float(wi) * 0.4 + sin(t * 2.0 + wi) * 0.15)
				draw_arc(center, wr, 0, TAU, 64,
						 Color(0.12, 0.92, 0.88, 0.08 * ring_pulse * (1.0 - wi * 0.2)), 1.0)
			draw_circle(center, sz * 0.95, Color(0.05, 0.45, 0.45, 0.94))
			draw_circle(center, sz * 0.65, Color(0.08, 0.70, 0.68, ring_pulse))
			draw_circle(center, sz * 0.38, Color(0.18, 0.95, 0.92, 1.0))
			draw_circle(center, sz * 0.15, Color(1.0, 1.0, 1.0, 1.0))

		"asteroid_field":
			var rng_ast := RandomNumberGenerator.new()
			rng_ast.seed = hash(ph["name"] + "astcv")
			var ast_spin := t * 0.15
			for ai in 80:
				var a_ang := float(ai) / 80.0 * TAU + ast_spin * (1.0 + rng_ast.randf_range(-0.3, 0.3))
				var a_dist := sz * rng_ast.randf_range(0.8, 3.5)
				var a_r    := rng_ast.randf_range(3.0, 10.0)
				var a_br   := rng_ast.randf_range(0.30, 0.65)
				draw_circle(center + Vector2(cos(a_ang)*a_dist, sin(a_ang)*a_dist), a_r,
							Color(a_br, a_br * 0.88, a_br * 0.60, 0.85))
			# Крупные валуны
			for bi in 6:
				var ba := float(bi) / 6.0 * TAU + ast_spin * 0.6
				var bd := sz * 2.2
				draw_circle(center + Vector2(cos(ba)*bd, sin(ba)*bd), 16.0,
							Color(0.58, 0.52, 0.38, 0.92))
				draw_circle(center + Vector2(cos(ba)*bd, sin(ba)*bd), 10.0,
							Color(0.72, 0.65, 0.48, 0.75))
				draw_circle(center + Vector2(cos(ba)*bd, sin(ba)*bd), 5.0,
							Color(0.85, 0.80, 0.60, 0.60))

	# ── Информационная панель поверх изображения ───────────────────────────────
	var effect_descs := {
		"gravity_well":        "Гравитационный колодец: прыжки +60% стоим., +40% топлива",
		"radiation":           "Радиационное облучение: −8% корпуса при прибытии",
		"pulse_interference":  "Пульсарные помехи: +1 день к любому прыжку",
		"nebula_veil":         "Туманная завеса: прыжки −20% стоимость",
		"supernova_radiation": "Реликтовая радиация: −12% корпуса при прибытии",
		"magnetic_storm":      "Магнитный шторм: оружие замедляется в бою",
		"ion_storm":           "Ионный шторм: +50% расход топлива",
		"asteroid_bonus":      "Богатые минералы: бонус к добыче ресурсов",
		"wormhole":            "Пространственная червоточина: нестабильный портал",
	}
	var type_names := {
		"blackhole": "⬛ ЧЁРНАЯ ДЫРА", "quasar": "✨ КВАЗАР", "pulsar": "⚡ ПУЛЬСАР",
		"nebula": "🌫 ТУМАННОСТЬ", "supernova": "💥 ОСТАТОК СВЕРХНОВОЙ",
		"magnetar": "🌀 МАГНЕТАР", "ion_storm": "⚡ ИОННЫЙ ШТОРМ",
		"wormhole": "🌀 ЧЕРВОТОЧИНА", "asteroid_field": "🪨 ПОЛЕ АСТЕРОИДОВ",
	}

	var info_x: float = vp.x * 0.06
	var info_y: float = vp.y * 0.10

	# Полупрозрачный фон плашки
	draw_rect(Rect2(info_x - 16, info_y - 12, 560, 160), Color(0, 0, 0, 0.62))

	draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y),
		ph["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 28,
		Color(0.95, 0.90, 1.0, 0.98))
	draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y + 36),
		type_names.get(ph["type"], ph["type"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
		Color(0.70, 0.65, 0.90, 0.90))
	draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y + 60),
		effect_descs.get(ph["effect"], ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
		Color(0.85, 0.85, 0.55, 0.90))

	var dist_to_cur: float = ph["pos"].distance_to(SYSTEMS[current_idx]["pos"])
	var dist_ly: int = int(dist_to_cur / 5.0)   # конвертация обратно в "световые годы"
	draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y + 82),
		"Расстояние от текущей позиции: ~%d св. лет" % dist_ly,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.60, 0.75, 0.90, 0.80))

	var ship_type: String = GameManager.current_ship.get("ship_type", "")
	if ship_type == "Исследовательский":
		draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y + 104),
			"✅ Исследовательский корабль — сканирование завершено", HORIZONTAL_ALIGNMENT_LEFT,
			-1, 14, Color(0.3, 1.0, 0.6, 0.92))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(info_x, info_y + 104),
			"⚠  Нужен Исследовательский корабль для полного сканирования",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.75, 0.25, 0.82))

	# Hint to exit
	draw_string(ThemeDB.fallback_font, Vector2(vp.x * 0.5 - 140, vp.y - 60),
		"← Назад (кнопка или Escape)", HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
		Color(0.6, 0.6, 0.7, 0.75))

# ── Отрисовка явления в мировом пространстве ──────────────────────────────────
func _draw_phenomenon(ph: Dictionary) -> void:
	var pos: Vector2 = ph["pos"]
	var sz:  float   = float(ph["size"])
	var t := time_e

	match ph["type"]:
		"blackhole":
			var rot := t * 0.35
			for ring in 5:
				var rf := 1.0 + ring * 0.55
				var ra := sz * rf
				var rb := sz * rf * 0.38
				var al := 0.55 - ring * 0.09
				var rc := Color(0.85 - ring * 0.10, 0.38 - ring * 0.06, 0.08, al)
				for seg in 48:
					var a0 := float(seg)   / 48.0 * TAU + rot * (1.0 - ring * 0.15)
					var a1 := float(seg+1) / 48.0 * TAU + rot * (1.0 - ring * 0.15)
					draw_line(pos + Vector2(cos(a0)*ra, sin(a0)*rb),
							  pos + Vector2(cos(a1)*ra, sin(a1)*rb),
							  rc, (1.2 + (2.0 - ring * 0.3) * 0.5) / cam_zoom)
			draw_circle(pos, sz * 3.2, Color(0.55, 0.18, 0.05, 0.06))
			draw_circle(pos, sz * 2.0, Color(0.70, 0.28, 0.08, 0.10))
			draw_circle(pos, sz * 0.95, Color(0.02, 0.01, 0.04, 1.0))
			draw_circle(pos, sz * 0.70, Color(0.0,  0.0,  0.0,  1.0))
			_draw_ph_label(pos, sz * 2.2, ph["name"], "⬛ ЧЁРНАЯ ДЫРА", Color(0.85,0.45,0.12,0.80), Color(0.70,0.30,0.08,0.65))

		"quasar":
			var pulse := 0.55 + sin(t * 3.8) * 0.40
			var pulse2 := 0.5 + sin(t * 5.2 + 1.0) * 0.45
			draw_circle(pos, sz * 3.5, Color(0.55, 0.20, 1.0, 0.04 * pulse))
			draw_circle(pos, sz * 2.2, Color(0.70, 0.35, 1.0, 0.08 * pulse))
			draw_circle(pos, sz * 1.4, Color(0.85, 0.55, 1.0, 0.15 * pulse))
			var jet_angle := t * 0.12
			var jet_len   := sz * 7.0
			var jet_fwd   := Vector2(cos(jet_angle), sin(jet_angle))
			for ji in 6:
				var jf := float(ji + 1) / 6.0
				draw_line(pos + jet_fwd * sz * 1.2 * jf, pos + jet_fwd * jet_len * jf,
						  Color(0.75, 0.45, 1.0, (0.22*pulse)*(1.0-jf)), (3.5*(1.0-jf)+0.5)/cam_zoom)
				draw_line(pos - jet_fwd * sz * 1.2 * jf, pos - jet_fwd * jet_len * jf,
						  Color(0.75, 0.45, 1.0, (0.22*pulse)*(1.0-jf)), (3.5*(1.0-jf)+0.5)/cam_zoom)
			draw_circle(pos, sz * 1.1, Color(0.60, 0.25, 1.0, 0.90))
			draw_circle(pos, sz * 0.70, Color(0.80, 0.55, 1.0, pulse2))
			draw_circle(pos, sz * 0.35, Color(1.0, 0.90, 1.0, 1.0))
			_draw_ph_label(pos, sz * 3.0, ph["name"], "✨ КВАЗАР", Color(0.80,0.55,1.0,0.80), Color(0.65,0.40,0.95,0.65))

		"pulsar":
			var spin := fmod(t * 2.8, TAU)
			var beam_len := sz * 9.0
			var beam_pulse := 0.5 + sin(t * 14.0) * 0.45
			for bi in 2:
				var ba := spin + float(bi) * PI
				var bdir := Vector2(cos(ba), sin(ba))
				for bw in 4:
					var bf := float(bw + 1) / 4.0
					draw_line(pos + bdir * sz * 1.0, pos + bdir * beam_len * bf,
							  Color(0.35, 1.0, 0.85, (1.0-bf)*0.55*beam_pulse),
							  (3.5*(1.0-bf*0.6))/cam_zoom)
			var flash := maxf(0.0, sin(t * 14.0))
			draw_circle(pos, sz * 2.5, Color(0.35, 1.0, 0.85, flash * 0.15))
			draw_circle(pos, sz * 1.6, Color(0.50, 1.0, 0.90, flash * 0.25))
			draw_circle(pos, sz * 0.85, Color(0.20, 0.70, 0.65, 0.90))
			draw_circle(pos, sz * 0.55, Color(0.50, 1.0,  0.90, 0.95))
			draw_circle(pos, sz * 0.28, Color(0.90, 1.0,  1.0,  1.0))
			_draw_ph_label(pos, sz * 2.8, ph["name"], "⚡ ПУЛЬСАР", Color(0.40,1.0,0.82,0.80), Color(0.30,0.88,0.72,0.65))

		"nebula":
			var pulse := 0.5 + sin(t * 0.55) * 0.22
			var hue_shift := sin(t * 0.20) * 0.08
			var c1 := Color(0.18 + hue_shift, 0.28, 0.85, 0.055 * pulse)
			var c2 := Color(0.38, 0.15 + hue_shift, 0.70, 0.075 * pulse)
			var c3 := Color(0.55, 0.32, 0.90, 0.055 * pulse)
			var rng_neb := RandomNumberGenerator.new()
			rng_neb.seed = hash(ph["name"])
			for layer in 18:
				var ang := rng_neb.randf_range(0, TAU)
				var dist_neb := rng_neb.randf_range(sz * 0.5, sz * 4.8)
				var rsz  := rng_neb.randf_range(sz * 0.8, sz * 2.6)
				draw_circle(pos + Vector2(cos(ang)*dist_neb, sin(ang)*dist_neb), rsz,
							[c1, c2, c3][layer % 3])
			draw_circle(pos, sz * 3.2, Color(0.30, 0.20, 0.75, 0.05 * pulse))
			draw_circle(pos, sz * 1.8, Color(0.45, 0.30, 0.88, 0.10 * pulse))
			draw_circle(pos, sz * 0.9, Color(0.65, 0.48, 0.95, 0.22 * pulse))
			draw_circle(pos, sz * 0.4, Color(0.88, 0.75, 1.0,  0.45 * pulse))
			_draw_ph_label(pos, sz * 3.2, ph["name"], "🌫 ТУМАННОСТЬ", Color(0.65,0.48,0.95,0.80), Color(0.50,0.35,0.85,0.65))

		"supernova":
			var expand := fmod(t * 0.22, 1.0)
			var wave_r  := sz * (2.5 + expand * 3.5)
			var wave_al := (1.0 - expand) * 0.18
			for wi in 3:
				var wr := wave_r - float(wi) * sz * 0.7
				if wr > 0:
					draw_arc(pos, wr, 0, TAU, 48,
						Color(1.0, 0.55 - wi*0.12, 0.08, wave_al*(1.0-wi*0.28)), (1.8-wi*0.4)/cam_zoom)
			draw_circle(pos, sz * 4.2, Color(1.0, 0.40, 0.05, 0.04))
			draw_circle(pos, sz * 2.6, Color(1.0, 0.55, 0.12, 0.07))
			var rng_sv := RandomNumberGenerator.new()
			rng_sv.seed = hash(ph["name"] + "sv")
			for fi in 12:
				var fa := float(fi) / 12.0 * TAU + t * 0.04
				var fl := sz * (2.0 + rng_sv.randf_range(0.5, 2.8))
				draw_line(pos + Vector2(cos(fa), sin(fa)) * sz * 0.6,
						  pos + Vector2(cos(fa), sin(fa)) * fl,
						  Color(1.0, 0.62, 0.18, 0.12), 1.0 / cam_zoom)
			var cp := 0.5 + sin(t * 8.0) * 0.42
			draw_circle(pos, sz * 0.70, Color(0.50, 0.85, 1.0, 0.88))
			draw_circle(pos, sz * 0.42, Color(0.80, 0.95, 1.0, cp))
			draw_circle(pos, sz * 0.20, Color(1.0,  1.0,  1.0, 1.0))
			_draw_ph_label(pos, sz * 4.0, ph["name"], "💥 СВЕРХНОВАЯ", Color(1.0,0.65,0.18,0.82), Color(0.90,0.48,0.10,0.65))

		"magnetar":
			var m_spin := t * 1.8
			var burst := maxf(0.0, sin(t * 6.5))
			for mi in 4:
				var ma := float(mi) / 4.0 * TAU + m_spin
				var mid_off := Vector2(cos(ma + PI * 0.5), sin(ma + PI * 0.5)) * sz * 3.5
				var pa := pos + Vector2(cos(ma), sin(ma)) * sz * 1.4
				var pb := pos + Vector2(cos(ma + PI), sin(ma + PI)) * sz * 1.4
				for seg2 in 14:
					var sf := float(seg2) / 14.0
					var ef := float(seg2 + 1) / 14.0
					draw_line(pa.lerp(pb, sf) + mid_off * sin(sf * PI),
							  pa.lerp(pb, ef) + mid_off * sin(ef * PI),
							  Color(1.0, 0.18, 0.82, 0.20 + burst * 0.15), 1.0 / cam_zoom)
			draw_circle(pos, sz * 2.8, Color(1.0, 0.15, 0.80, burst * 0.10))
			draw_circle(pos, sz * 1.6, Color(1.0, 0.28, 0.88, burst * 0.18))
			draw_circle(pos, sz * 0.80, Color(0.72, 0.08, 0.65, 0.90))
			draw_circle(pos, sz * 0.50, Color(0.90, 0.30, 0.92, 0.95))
			draw_circle(pos, sz * 0.25, Color(1.0,  0.82, 1.0,  1.0))
			_draw_ph_label(pos, sz * 2.8, ph["name"], "🌀 МАГНЕТАР", Color(1.0,0.28,0.88,0.82), Color(0.88,0.18,0.78,0.65))

		"ion_storm":
			var i_swirl := t * 1.2
			var zap := maxf(0.0, sin(t * 9.5 + 0.7))
			for li in 24:
				var a0 := float(li) / 24.0 * TAU + i_swirl + sin(t * 0.4 + li) * 0.3
				var a1 := a0 + 0.25 + sin(t * 0.6 + li * 0.8) * 0.12
				var r0 := sz * (1.2 + sin(t * 0.7 + li * 0.5) * 0.4)
				var r1 := sz * (2.2 + sin(t * 0.5 + li * 0.7) * 0.6)
				draw_line(pos + Vector2(cos(a0)*r0, sin(a0)*r0),
						  pos + Vector2(cos(a1)*r1, sin(a1)*r1),
						  Color(0.95, 0.88, 0.12, 0.18 + zap * 0.12), 1.2 / cam_zoom)
			for zi in 5:
				var za := float(zi) / 5.0 * TAU + i_swirl * 1.5
				var zlen := sz * (2.5 + sin(t * 3.0 + zi * 1.3) * 1.0)
				draw_line(pos, pos + Vector2(cos(za)*zlen, sin(za)*zlen),
						  Color(0.98, 0.95, 0.35, zap * 0.55), 1.5 / cam_zoom)
			draw_circle(pos, sz * 1.5, Color(0.95, 0.88, 0.15, 0.08 + zap * 0.08))
			draw_circle(pos, sz * 0.80, Color(0.98, 0.95, 0.28, 0.75))
			draw_circle(pos, sz * 0.45, Color(1.0,  1.0,  0.70, 0.90))
			draw_circle(pos, sz * 0.22, Color(1.0,  1.0,  1.0,  1.0))
			_draw_ph_label(pos, sz * 2.6, ph["name"], "⚡ ИОННЫЙ ШТОРМ", Color(0.98,0.90,0.22,0.82), Color(0.85,0.78,0.15,0.65))

		"wormhole":
			var w_spin := t * 1.5
			var ring_pulse := 0.55 + sin(t * 4.2) * 0.38
			if ph.has("pair_pos"):
				var pp2: Vector2 = ph["pair_pos"]
				for seg3 in 18:
					var sf2 := float(seg3) / 18.0
					var ef2 := float(seg3 + 1) / 18.0
					var al2 := sin(sf2 * PI) * 0.25 * (0.5 + sin(t * 2.0 + sf2 * TAU) * 0.4)
					draw_line(pos.lerp(pp2, sf2), pos.lerp(pp2, ef2),
							  Color(0.12, 0.92, 0.88, al2), 1.5 / cam_zoom)
			draw_circle(pos, sz * 3.0, Color(0.10, 0.88, 0.85, 0.04 * ring_pulse))
			draw_circle(pos, sz * 2.0, Color(0.15, 0.92, 0.88, 0.08 * ring_pulse))
			for ri in 3:
				var rr := sz * (1.0 + ri * 0.45)
				draw_arc(pos, rr, w_spin + ri * TAU / 3.0, w_spin + ri * TAU / 3.0 + TAU * 0.7, 32,
						 Color(0.12, 0.92, 0.88, ring_pulse * (0.55 - ri * 0.12)), 1.5 / cam_zoom)
			draw_circle(pos, sz * 0.95, Color(0.05, 0.45, 0.45, 0.92))
			draw_circle(pos, sz * 0.65, Color(0.08, 0.70, 0.68, ring_pulse))
			draw_circle(pos, sz * 0.35, Color(0.18, 0.95, 0.92, 1.0))
			draw_circle(pos, sz * 0.16, Color(1.0,  1.0,  1.0,  1.0))
			_draw_ph_label(pos, sz * 2.2, ph["name"], "🌀 ЧЕРВОТОЧИНА", Color(0.18,0.92,0.88,0.82), Color(0.12,0.78,0.75,0.65))

		"asteroid_field":
			var rng_ast := RandomNumberGenerator.new()
			rng_ast.seed = hash(ph["name"] + "ast")
			var ast_spin := t * 0.18
			for ai in 28:
				var a_ang := float(ai) / 28.0 * TAU + ast_spin * (1.0 + rng_ast.randf_range(-0.3, 0.3))
				var a_dist := sz * rng_ast.randf_range(1.2, 3.8)
				var a_r    := rng_ast.randf_range(1.2, 3.8)
				var a_br   := rng_ast.randf_range(0.35, 0.70)
				draw_circle(pos + Vector2(cos(a_ang)*a_dist, sin(a_ang)*a_dist), a_r,
							Color(a_br, a_br * 0.88, a_br * 0.62, 0.80))
			draw_arc(pos, sz * 2.5, 0, TAU, 48, Color(0.62, 0.55, 0.38, 0.10), sz * 2.0)
			for bi in 3:
				var ba := float(bi) / 3.0 * TAU + ast_spin * 0.7
				draw_circle(pos + Vector2(cos(ba)*sz*2.4, sin(ba)*sz*2.4), 5.5,
							Color(0.58, 0.52, 0.38, 0.90))
				draw_circle(pos + Vector2(cos(ba)*sz*2.4, sin(ba)*sz*2.4), 3.2,
							Color(0.72, 0.65, 0.48, 0.70))
			_draw_ph_label(pos, sz * 3.2, ph["name"], "🪨 ПОЛЕ АСТЕРОИДОВ", Color(0.72,0.64,0.42,0.82), Color(0.60,0.52,0.32,0.65))

func _draw_ph_label(pos: Vector2, y_off: float, name_txt: String, type_txt: String, nc: Color, tc: Color) -> void:
	if cam_zoom < 0.15:
		return
	var fs: int = clampi(int(12.0 / cam_zoom), 8, 24)
	var off: float = y_off + 10.0 / cam_zoom
	var w: float = 200.0 / cam_zoom
	draw_string(ThemeDB.fallback_font, pos + Vector2(-w * 0.5, off),
		name_txt, HORIZONTAL_ALIGNMENT_CENTER, w, fs, nc)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-w * 0.5, off + 14.0 / cam_zoom),
		type_txt, HORIZONTAL_ALIGNMENT_CENTER, w, clampi(int(10.0 / cam_zoom), 7, 20), tc)

func _get_affecting_phenomena(pos: Vector2) -> Array:
	var result: Array = []
	for ph in PHENOMENA:
		if pos.distance_to(ph["pos"]) <= float(ph["radius"]):
			result.append(ph)
	return result

func _draw_system(i: int) -> void:
	var s    = SYSTEMS[i]
	var pos: Vector2 = s["pos"]
	var col: Color   = s["color"]
	var sz:  float   = s["size"]
	# Минимальный видимый размер (4 пикселя на экране)
	var draw_sz: float = maxf(sz, 4.0 / cam_zoom)
	var is_current  := (i == current_idx)
	var is_selected := (i == selected_idx)
	var danger: int  = s["danger"]

	# ── Туман войны ───────────────────────────────────────────────────────────
	var visited: bool = i in GameManager.visited_systems
	var known: bool = visited
	if not known:
		for c in CONNECTIONS:
			if (c[0] == i and c[1] in GameManager.visited_systems) or \
			   (c[1] == i and c[0] in GameManager.visited_systems):
				known = true
				break
	var quest_revealed: bool = s["name"] in GameManager.quest_revealed_systems

	if not known and not quest_revealed:
		return

	if not visited:
		if quest_revealed:
			draw_circle(pos, draw_sz * 1.8, Color(col.r * 0.18, col.g * 0.18, col.b * 0.30, 0.50))
			draw_circle(pos, draw_sz * 0.9, Color(col.r * 0.30, col.g * 0.30, col.b * 0.42, 0.75))
			if cam_zoom >= 0.22:
				var fs: int = clampi(int(11.0 / cam_zoom), 8, 22)
				var w: float = 85.0 / cam_zoom
				draw_string(ThemeDB.fallback_font, pos + Vector2(-w*0.5, draw_sz + 18.0/cam_zoom),
					s["name"], HORIZONTAL_ALIGNMENT_CENTER, w, fs, Color(0.85, 0.75, 0.25, 0.85))
				draw_string(ThemeDB.fallback_font, pos + Vector2(-w*0.5, draw_sz + 32.0/cam_zoom),
					"[задание]", HORIZONTAL_ALIGNMENT_CENTER, w, clampi(int(10.0/cam_zoom),7,18), Color(0.95, 0.75, 0.15, 0.70))
		else:
			draw_circle(pos, draw_sz * 1.8, Color(col.r * 0.15, col.g * 0.15, col.b * 0.25, 0.45))
			draw_circle(pos, draw_sz * 0.9, Color(col.r * 0.25, col.g * 0.25, col.b * 0.35, 0.70))
			if cam_zoom >= 0.22:
				var fs: int = clampi(int(12.0 / cam_zoom), 8, 22)
				draw_string(ThemeDB.fallback_font, pos + Vector2(-15.0/cam_zoom, draw_sz + 18.0/cam_zoom),
					"???", HORIZONTAL_ALIGNMENT_CENTER, 35.0/cam_zoom, fs, Color(0.35, 0.38, 0.55, 0.70))
		if is_selected:
			draw_arc(pos, draw_sz + 13.0/cam_zoom, 0, TAU, 36, Color(1.0, 1.0, 1.0, 0.60), 1.5/cam_zoom)
		return

	# Danger glow
	if danger >= 4:
		var d_pulse: float = 0.06 + sin(time_e * 1.8 + i) * 0.03
		draw_circle(pos, draw_sz + 22.0/cam_zoom, Color(1.0, 0.2, 0.2, d_pulse))

	# Ореолы от явлений
	var affecting_ph := _get_affecting_phenomena(s["pos"])
	for aph in affecting_ph:
		var eff: String = aph["effect"]
		var hcol: Color = EFFECT_HALO_COLOR.get(eff, Color(1, 1, 1))
		var hp: float = 0.30 + sin(time_e * 1.5 + float(i) * 0.7) * 0.18
		draw_circle(pos, draw_sz + 30.0/cam_zoom, Color(hcol.r, hcol.g, hcol.b, hp * 0.06))
		draw_arc(pos, draw_sz + 22.0/cam_zoom, 0, TAU, 36, Color(hcol.r, hcol.g, hcol.b, hp * 0.50), 1.5/cam_zoom)

	# Звёздное свечение
	for gi in 10:
		var gt: float  = float(gi) / 9.0
		var tt: float = gt * gt
		var gr: float = draw_sz + 28.0 / cam_zoom * (1.0 - tt)
		var ga: float = 0.012 * (1.0 - gt) * (1.0 - gt)
		draw_circle(pos, gr, Color(col.r, col.g, col.b, ga))

	# Кольцо текущей позиции
	if is_current:
		var pulse: float = 0.5 + sin(time_e * 2.8) * 0.35
		draw_arc(pos, draw_sz + 16.0/cam_zoom, 0, TAU, 48, Color(0.2, 1.0, 0.4, pulse), 2.5/cam_zoom)
		draw_arc(pos, draw_sz + 22.0/cam_zoom, time_e * 0.5, time_e * 0.5 + TAU * 0.75, 32,
			Color(0.2, 1.0, 0.4, pulse * 0.4), 1.5/cam_zoom)

	# Кольцо выделения
	if is_selected:
		draw_arc(pos, draw_sz + 13.0/cam_zoom, 0, TAU, 48, Color(1.0, 1.0, 1.0, 0.85), 2.0/cam_zoom)
		for tk in 4:
			var ta: float = tk / 4.0 * TAU + time_e * 0.8
			draw_line(pos + Vector2(cos(ta), sin(ta)) * (draw_sz + 10.0/cam_zoom),
					  pos + Vector2(cos(ta), sin(ta)) * (draw_sz + 18.0/cam_zoom),
					  Color(1.0, 1.0, 0.3, 0.9), 2.0/cam_zoom)

	# Тело звезды
	draw_circle(pos, draw_sz,        Color(col.r * 0.35, col.g * 0.35, col.b * 0.45, 0.88))
	draw_circle(pos, draw_sz * 0.88, col)
	draw_circle(pos, draw_sz * 0.70, Color(minf(col.r+0.18,1.0), minf(col.g+0.18,1.0), minf(col.b+0.12,1.0), 0.80))
	draw_circle(pos, draw_sz * 0.50, Color(minf(col.r+0.30,1.0), minf(col.g+0.30,1.0), minf(col.b+0.22,1.0), 0.72))
	draw_circle(pos, draw_sz * 0.30, Color(minf(col.r+0.42,1.0), minf(col.g+0.42,1.0), minf(col.b+0.32,1.0), 0.82))
	draw_circle(pos, draw_sz * 0.16, Color(1.0, 1.0, 1.0, 0.92))

	if is_current and cam_zoom >= 0.18:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-14.0/cam_zoom, -draw_sz - 14.0/cam_zoom),
			"▼", HORIZONTAL_ALIGNMENT_CENTER, 30.0/cam_zoom, clampi(int(14.0/cam_zoom),8,22), Color(0.2, 1.0, 0.4))

	# Подписи — только при достаточном зуме
	if cam_zoom < 0.18:
		return

	var fs_name: int = clampi(int(13.0 / cam_zoom), 8, 22)
	var fs_tag:  int = clampi(int(11.0 / cam_zoom), 7, 18)
	var w_name: float = 135.0 / cam_zoom
	var off_y: float  = draw_sz + 18.0 / cam_zoom

	var danger_name_col: Color
	match danger:
		1: danger_name_col = Color(0.40, 1.00, 0.50, 0.97)
		2: danger_name_col = Color(0.70, 1.00, 0.35, 0.95)
		3: danger_name_col = Color(1.00, 0.88, 0.15, 0.95)
		4: danger_name_col = Color(1.00, 0.52, 0.10, 0.97)
		_: danger_name_col = Color(1.00, 0.20, 0.20, 1.00)

	draw_string(ThemeDB.fallback_font, pos + Vector2(-w_name*0.5, off_y + 1.0/cam_zoom),
		s["name"], HORIZONTAL_ALIGNMENT_CENTER, w_name, fs_name, Color(0, 0, 0, 0.65))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-w_name*0.5, off_y),
		s["name"], HORIZONTAL_ALIGNMENT_CENTER, w_name, fs_name, danger_name_col)

	if cam_zoom < 0.28:
		return

	# Точки опасности
	var dot_r: float = 2.8 / cam_zoom
	var dot_spacing: float = 7.5 / cam_zoom
	var dots_w: float = 4.0 * dot_spacing
	var dot_base: Vector2 = pos + Vector2(-dots_w * 0.5, off_y + 14.0/cam_zoom)
	var dot_cols := [Color(0.40,1.00,0.50),Color(0.70,1.00,0.35),Color(1.00,0.88,0.15),Color(1.00,0.52,0.10),Color(1.00,0.20,0.20)]
	for di in 5:
		var dc: Color = dot_cols[di]
		draw_circle(dot_base + Vector2(di * dot_spacing, 0), dot_r,
					Color(dc.r, dc.g, dc.b, 0.92 if di < danger else 0.18))

	if cam_zoom < 0.38:
		return

	# Протекторат
	var is_protectorate: bool = GameManager.is_protectorate(s["name"])
	if is_protectorate:
		var pp: float = 0.50 + sin(time_e * 1.5 + float(i)) * 0.25
		draw_arc(pos, draw_sz + 14.0/cam_zoom, 0, TAU, 48, Color(1.0, 0.72, 0.1, pp * 0.65), 2.2/cam_zoom)

	# Война
	var at_war: bool = (s["faction"] in GameManager.war_targets)
	if at_war and not is_protectorate:
		var wp: float = 0.4 + sin(time_e * 4.5 + float(i)) * 0.35
		draw_arc(pos, draw_sz + 12.0/cam_zoom, 0, TAU, 48, Color(1.0, 0.15, 0.15, wp * 0.7), 2.0/cam_zoom)

	# Фракционный тег
	var is_player_hq: bool = (GameManager.faction_hq_system != "" and
		s["name"] == GameManager.faction_hq_system and GameManager.faction_leader_of != "")
	var faction_label: String = "🏴 " + GameManager.faction_leader_of if is_protectorate \
		else (GameManager.faction_leader_of if is_player_hq else s["faction"])
	var w_tag: float = 105.0 / cam_zoom
	var faction_tag_col: Color
	if is_protectorate:   faction_tag_col = Color(1.0, 0.80, 0.15, 0.90)
	elif is_player_hq:    faction_tag_col = Color(1.0, 0.88, 0.2, 0.75 + sin(time_e*2.0+i)*0.2)
	elif at_war:          faction_tag_col = Color(1.0, 0.2, 0.2, 0.55 + sin(time_e*3.0+i)*0.3)
	else:                 faction_tag_col = Color(col.r*0.5+0.2, col.g*0.5+0.2, col.b*0.4+0.3, 0.65)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-w_tag*0.5, off_y + 28.0/cam_zoom),
		faction_label, HORIZONTAL_ALIGNMENT_CENTER, w_tag, fs_tag, faction_tag_col)

	# HQ badge
	if s.get("is_hq", false) or is_player_hq:
		var hq_pulse: float = 0.55 + sin(time_e * 1.6 + float(i)) * 0.25
		var hq_r: float = draw_sz + 7.0/cam_zoom
		draw_arc(pos, hq_r, 0, TAU, 32, Color(col.r*0.6+0.4, col.g*0.6+0.4, 0.15, hq_pulse*0.55), 1.0/cam_zoom)

func _unhandled_input(event: InputEvent) -> void:
	# Escape выходит из режима детального осмотра
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _cv_active:
			_exit_closeup()
			return

	# Зум колёсиком мыши
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(0.06, get_global_mouse_position())
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-0.06, get_global_mouse_position())
			return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mp := get_global_mouse_position()
		if event.pressed:
			if _cv_active:
				_exit_closeup()
				return

			var world_mp := _screen_to_world(mp)

			# Проверка клика по системе
			for i in SYSTEMS.size():
				var hit_r := maxf(float(SYSTEMS[i]["size"]) + 14.0, 14.0 / cam_zoom)
				if world_mp.distance_to(SYSTEMS[i]["pos"]) < hit_r:
					_on_system_clicked(i)
					_ph_panel.hide()
					return

			# Проверка клика по явлению
			for ph in PHENOMENA:
				var ph_sz := float(ph["size"])
				var ph_hit := maxf(ph_sz * 1.5, 30.0 / cam_zoom)
				if world_mp.distance_to(ph["pos"]) < ph_hit:
					_on_phenomenon_clicked(ph)
					return

			# Начать перетаскивание
			_dragging = true
			_drag_from = mp
			info_panel.hide()
			_ph_panel.hide()
			selected_idx = -1
		else:
			_dragging = false

	if event is InputEventMouseMotion and _dragging:
		cam_pan += event.relative
		queue_redraw()

func _on_phenomenon_clicked(ph: Dictionary) -> void:
	_ph_panel.show()
	var vb := _ph_panel.get_child(0)
	vb.get_child(0).text = ph["name"]

	var type_names := {
		"blackhole": "⬛ Чёрная дыра", "quasar": "✨ Квазар", "pulsar": "⚡ Пульсар",
		"nebula": "🌫 Туманность", "supernova": "💥 Остаток сверхновой",
		"magnetar": "🌀 Магнетар", "ion_storm": "⚡ Ионный шторм",
		"wormhole": "🌀 Червоточина", "asteroid_field": "🪨 Поле астероидов",
	}
	vb.get_child(1).text = type_names.get(ph["type"], ph["type"])

	var effect_descs := {
		"gravity_well": "Прыжок: +60% стоим., +40% топлива",
		"radiation": "При прибытии: −8% корпуса",
		"pulse_interference": "Прыжок: +1 день",
		"nebula_veil": "Прыжок: −20% стоимость",
		"supernova_radiation": "При прибытии: −12% корпуса",
		"magnetic_storm": "В бою: оружие замедлено ×1.3",
		"ion_storm": "Прыжок: +50% топлива",
		"asteroid_bonus": "Бонус добычи ресурсов",
		"wormhole": "Нестабильный пространственный портал",
	}
	vb.get_child(2).text = effect_descs.get(ph["effect"], "")
	vb.get_child(2).add_theme_color_override("font_color",
		EFFECT_HALO_COLOR.get(ph["effect"], Color(0.8, 0.8, 0.8)))

	var is_research: bool = GameManager.current_ship.get("ship_type", "") == "Исследовательский"
	_ph_investigate_btn.visible = true
	_ph_investigate_btn.disabled = false
	_ph_investigate_btn.text = "🔭 Исследовать" if is_research else "🔭 Осмотреть (ограниченно)"
	# Запомнить явление для кнопки
	_cv_ph = ph
	lbl_status.text = "Явление: %s  |  Нажми 🔭 для детального осмотра" % ph["name"]

func _on_investigate() -> void:
	if _cv_ph.is_empty():
		return
	_ph_panel.hide()
	_enter_closeup(_cv_ph)

func _enter_closeup(ph: Dictionary) -> void:
	_cv_active = true
	_cv_ph = ph
	# Создать кнопку "Назад"
	if _cv_back_btn == null:
		_cv_back_btn = Button.new()
		_cv_back_btn.text = "← Назад"
		_cv_back_btn.add_theme_font_size_override("font_size", 18)
		_cv_back_btn.custom_minimum_size = Vector2(140, 48)
		_cv_back_btn.anchor_left   = 1.0
		_cv_back_btn.anchor_right  = 1.0
		_cv_back_btn.anchor_top    = 1.0
		_cv_back_btn.anchor_bottom = 1.0
		_cv_back_btn.offset_left   = -160.0
		_cv_back_btn.offset_right  = -12.0
		_cv_back_btn.offset_top    = -70.0
		_cv_back_btn.offset_bottom = -14.0
		_cv_back_btn.pressed.connect(_exit_closeup)
		$UI.add_child(_cv_back_btn)
	_cv_back_btn.show()
	queue_redraw()

func _exit_closeup() -> void:
	_cv_active = false
	_cv_ph = {}
	if _cv_back_btn:
		_cv_back_btn.hide()
	queue_redraw()

func _calc_jump(from_idx: int, to_idx: int) -> Dictionary:
	var dist: float = SYSTEMS[from_idx]["pos"].distance_to(SYSTEMS[to_idx]["pos"])
	var raw_cost := int(dist * JUMP_COST_PER_PX)
	var cost: int  = maxi(JUMP_MIN_COST, (raw_cost / 50) * 50)
	var days: int  = maxi(1, int(dist / JUMP_DAY_PX))
	var cost_mult: float = 1.0
	var fuel_mult: float = 1.0
	var extra_days: int  = 0
	var effects_found: Array = []
	for check_pos in [SYSTEMS[from_idx]["pos"], SYSTEMS[to_idx]["pos"]]:
		for ph in _get_affecting_phenomena(check_pos):
			var eff: String = ph["effect"]
			if eff in effects_found:
				continue
			effects_found.append(eff)
			match eff:
				"gravity_well":
					cost_mult = maxf(cost_mult, 1.6)
					fuel_mult = maxf(fuel_mult, 1.4)
				"pulse_interference":
					extra_days += 1
				"nebula_veil":
					cost_mult = minf(cost_mult, 0.8)
				"ion_storm":
					fuel_mult = maxf(fuel_mult, 1.5)
	cost = maxi(JUMP_MIN_COST, int(cost * cost_mult / 50) * 50)
	var fuel_need: float = dist * FUEL_PER_PX * fuel_mult
	return {"cost": cost, "days": days + mini(extra_days, 2), "dist": int(dist), "fuel_need": fuel_need, "effects": effects_found}

func _on_system_clicked(idx: int) -> void:
	selected_idx = idx
	var s        = SYSTEMS[idx]
	var visited  : bool   = idx in GameManager.visited_systems
	var name_txt : String = s["name"] if visited else "???"
	var d        : int    = s["danger"]
	var fac      : String = s["faction"] if visited else "???"
	var fac_col  : Color  = _faction_color(s["faction"]) if visited else Color(0.5, 0.5, 0.62)

	# ── Header ────────────────────────────────────────────────────────────────
	lbl_name.text = name_txt
	lbl_name.add_theme_color_override("font_color", fac_col)

	var is_current := (idx == current_idx)
	lbl_subname.text = "[ ТЕКУЩАЯ ПОЗИЦИЯ ]" if is_current else \
		("[ ПОСЕЩЕНО ]" if visited else "[ НЕ ИССЛЕДОВАНО ]")
	lbl_subname.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.55) if is_current else
		(Color(0.5, 0.75, 0.5) if visited else Color(0.42, 0.42, 0.52)))

	lbl_faction.text = "🏛  Фракция:  %s" % fac
	lbl_faction.add_theme_color_override("font_color", fac_col)

	var star_full := "★".repeat(d)
	var star_empty := "☆".repeat(5 - d)
	var dcol := Color(0.3, 1.0, 0.45) if d <= 1 else \
		(Color(1.0, 0.9, 0.15) if d <= 2 else \
		(Color(1.0, 0.6, 0.1) if d <= 3 else Color(1.0, 0.22, 0.22)))
	lbl_danger.text = "⚠  Опасность:  %s%s  (%d/5)" % [star_full, star_empty, d]
	lbl_danger.add_theme_color_override("font_color", dcol)

	# ── Clear dynamic rows ────────────────────────────────────────────────────
	for ch in dyn_info.get_children():
		ch.queue_free()

	btn_enter.visible = is_current
	btn_jump.visible  = not is_current

	if not is_current:
		var jmp        := _calc_jump(current_idx, idx)
		var fuel_need  : float = jmp["fuel_need"]
		var has_credits: bool  = GameManager.credits >= jmp["cost"]
		var has_fuel   : bool  = GameManager.fuel    >= fuel_need
		var days       : int   = jmp["days"]
		var days_txt   : String = "%d день" % days if days == 1 else \
			("%d дня" % days if days < 5 else "%d дней" % days)
		var dist_ly    : int   = jmp["dist"] / 5

		# Separator
		var sep := HSeparator.new()
		dyn_info.add_child(sep)

		# ── Cost row ──────────────────────────────────────────────────────────
		_info_row(dyn_info, "⚡  Прыжок",
			"%d кред." % jmp["cost"],
			Color(0.38, 0.72, 1.0),
			Color(0.25, 1.0, 0.55) if has_credits else Color(1.0, 0.28, 0.28))

		# ── Travel time ───────────────────────────────────────────────────────
		_info_row(dyn_info, "📅  В пути",
			days_txt,
			Color(0.55, 0.65, 0.85),
			Color(0.85, 0.90, 1.0))

		# ── Fuel ──────────────────────────────────────────────────────────────
		var fuel_col := Color(0.3, 1.0, 0.55) if has_fuel else Color(1.0, 0.38, 0.22)
		_info_row(dyn_info, "⛽  Топливо",
			"%.0f%%  (есть %.0f%%)" % [fuel_need, GameManager.fuel],
			fuel_col,
			fuel_col)

		# ── Distance ──────────────────────────────────────────────────────────
		_info_row(dyn_info, "📡  Расстояние",
			"%d св. лет" % dist_ly,
			Color(0.48, 0.52, 0.68),
			Color(0.65, 0.70, 0.85))

		# ── Reputation ────────────────────────────────────────────────────────
		if visited and s["faction"] != "Нет":
			var rep_val : int    = GameManager.faction_reputation.get(s["faction"], 0)
			var standing: String = GameManager.get_faction_standing(s["faction"])
			var rcol := Color(0.3, 1.0, 0.45) if rep_val >= 10 else \
				(Color(0.65, 0.65, 0.65) if rep_val >= -10 else Color(1.0, 0.35, 0.3))
			_info_row(dyn_info, "🎖  Репутация",
				"%s  %+d" % [standing, rep_val],
				Color(0.45, 0.55, 0.75), rcol)

		# ── Hazard effects ────────────────────────────────────────────────────
		if not jmp["effects"].is_empty():
			var hdr := Label.new()
			hdr.text = "  ⚠  HAZARD МАРШРУТА:"
			hdr.add_theme_font_size_override("font_size", 11)
			hdr.add_theme_color_override("font_color", Color(1.0, 0.78, 0.15))
			dyn_info.add_child(hdr)

			const EFF_DATA := {
				"gravity_well":        ["⚫", "Гравит. колодец",    "+60% кред / +40% топлива", Color(1.0,  0.50, 0.12)],
				"pulse_interference":  ["⚡", "Имп. помехи",        "+1 день в пути",           Color(0.25, 0.90, 1.0) ],
				"nebula_veil":         ["🌫", "Туманность",          "−20% стоимость",           Color(0.40, 0.60, 1.0) ],
				"ion_storm":           ["⚡", "Ионный шторм",        "+50% расход топлива",       Color(0.95, 0.92, 0.12)],
				"radiation":           ["☢", "Радиация",             "−8% корпуса",              Color(1.0,  0.38, 0.38)],
				"supernova_radiation": ["💥", "Сверхновая",           "−12% корпуса",             Color(1.0,  0.28, 0.10)],
				"magnetic_storm":      ["🌀", "Магн. буря",           "Оружие ×1.3 в бою",        Color(1.0,  0.18, 0.92)],
				"asteroid_bonus":      ["🪨", "Астероиды",            "+добыча ресурсов",          Color(0.72, 0.58, 0.35)],
				"wormhole":            ["🌀", "Червоточина",          "Нестаб. прыжок",           Color(0.12, 0.92, 0.88)],
			}
			for eff: String in jmp["effects"]:
				if not EFF_DATA.has(eff):
					continue
				var ed: Array = EFF_DATA[eff]
				_info_row(dyn_info,
					"  %s %s" % [ed[0], ed[1]], ed[2],
					ed[3], Color(ed[3].r * 0.65 + 0.32, ed[3].g * 0.65 + 0.32, ed[3].b * 0.65 + 0.32))

		# ── Can't jump warning ────────────────────────────────────────────────
		if not has_credits or not has_fuel:
			var warn := Label.new()
			warn.text = "  ✗  %s" % ("Недостаточно кредитов" if not has_credits else "Недостаточно топлива")
			warn.add_theme_font_size_override("font_size", 13)
			warn.add_theme_color_override("font_color", Color(1.0, 0.28, 0.28))
			dyn_info.add_child(warn)

		btn_jump.disabled = not (has_credits and has_fuel)

	info_panel.show()
	lbl_status.text = "%s  |  %s  |  Опасность %d/5  |  Топливо: %.0f/%.0f" % [
		name_txt, fac, d, GameManager.fuel, GameManager.max_fuel]

# ── Info panel helpers ────────────────────────────────────────────────────────

func _info_row(parent: VBoxContainer, ltext: String, rtext: String,
		lcol: Color, rcol: Color) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var ll := Label.new()
	ll.text = ltext
	ll.add_theme_font_size_override("font_size", 13)
	ll.add_theme_color_override("font_color", lcol)
	ll.custom_minimum_size = Vector2(148, 0)
	row.add_child(ll)
	var rl := Label.new()
	rl.text = rtext
	rl.add_theme_font_size_override("font_size", 13)
	rl.add_theme_color_override("font_color", rcol)
	rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(rl)

func _faction_color(faction: String) -> Color:
	match faction:
		"Федерация":    return Color(0.35, 0.72, 1.00)
		"Торговцы":     return Color(0.25, 1.00, 0.60)
		"Независимые":  return Color(0.72, 0.85, 0.62)
		"Пираты":       return Color(1.00, 0.28, 0.28)
		"Империя":      return Color(1.00, 0.55, 0.18)
		_:              return Color(0.50, 0.50, 0.62)

func _on_enter() -> void:
	var s: Dictionary = SYSTEMS[current_idx]
	GameManager.current_galaxy     = s["name"]
	GameManager.current_galaxy_idx = current_idx
	GameManager.current_danger     = s["danger"]
	GameManager.current_faction    = s["faction"]
	if not current_idx in GameManager.visited_systems:
		GameManager.visited_systems.append(current_idx)
	if not s["name"] in GameManager.visited_galaxy_names:
		GameManager.visited_galaxy_names.append(s["name"])
	GameManager.current_system_dead_enemies.clear()
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/star_system/StarSystemView.tscn")

func _on_jump() -> void:
	if selected_idx < 0 or selected_idx == current_idx:
		return
	var jmp: Dictionary = _calc_jump(current_idx, selected_idx)
	var fuel_need: float = jmp["fuel_need"]
	if not GameManager.spend_credits(jmp["cost"]):
		lbl_status.text = "❌ Недостаточно кредитов!"
		return
	if not GameManager.spend_fuel(fuel_need):
		GameManager.add_credits(jmp["cost"])
		lbl_status.text = "⛽ Недостаточно топлива! (нужно %.0f%%, есть %.0f%%)" % [fuel_need, GameManager.fuel]
		return

	var dest: Dictionary = SYSTEMS[selected_idx]
	var days_txt := "%d день" % jmp["days"] if jmp["days"] == 1 else "%d дня" % jmp["days"]
	lbl_status.text = "⚡ Прыжок к %s... (%s)" % [dest["name"], days_txt]
	btn_jump.disabled = true
	info_panel.hide()
	AudioManager.play_sfx("jump")

	_travel_from   = SYSTEMS[current_idx]["pos"]
	_travel_to     = SYSTEMS[selected_idx]["pos"]
	_travel_t      = 0.0
	_travel_active = true

	var to_idx := selected_idx
	var tween := create_tween()
	tween.tween_interval(TRAVEL_DUR)
	tween.tween_callback(func():
		current_idx  = to_idx
		selected_idx = -1
		var s: Dictionary = SYSTEMS[current_idx]
		GameManager.current_galaxy_idx = current_idx
		GameManager.current_galaxy     = s["name"]
		GameManager.current_danger     = s["danger"]
		GameManager.current_faction    = s["faction"]
		if not current_idx in GameManager.visited_systems:
			GameManager.visited_systems.append(current_idx)
		if not s["name"] in GameManager.visited_galaxy_names:
			GameManager.visited_galaxy_names.append(s["name"])
		GameManager.current_system_dead_enemies.clear()
		for _d in jmp["days"]:
			GameManager.advance_day()
		_refresh_topbar()

		# Камера следует за кораблём
		var vp := get_viewport_rect().size
		var target_pan: Vector2 = vp * 0.5 - (SYSTEMS[current_idx]["pos"] as Vector2) * cam_zoom
		var cam_tween := create_tween()
		cam_tween.tween_property(self, "cam_pan", target_pan, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Случайная встреча
		var encounter_chance: float = ENCOUNTER_BASE + float(s["danger"]) * ENCOUNTER_DANGER
		if randf() < encounter_chance:
			GameManager.pending_hyperspace_encounter = true
			var hull_loss := randf_range(0.05, 0.15)
			GameManager.ship_hull_pct = maxf(0.05, GameManager.ship_hull_pct - hull_loss)
			AudioManager.play_sfx("hurt")
			lbl_status.text = "⚠  ПЕРЕХВАТ В ГИПЕРПРОСТРАНСТВЕ!  −%.0f%% корпуса  →  Прибыли: %s" % [
				hull_loss * 100, s["name"]]
		else:
			GameManager.pending_hyperspace_encounter = false
			lbl_status.text = "✅ Прибыли: %s  (прошло %s)" % [s["name"], days_txt]

		# Эффекты прибытия от явлений
		GameManager.weapon_cooldown_modifier = 1.0
		var arrival_ph := _get_affecting_phenomena(SYSTEMS[to_idx]["pos"])
		var arrival_msg := ""
		for aph in arrival_ph:
			match aph["effect"]:
				"radiation":
					var rdmg := 0.08
					GameManager.ship_hull_pct = maxf(0.05, GameManager.ship_hull_pct - rdmg)
					arrival_msg += "  ☢ %s: −%.0f%% корп." % [aph["name"], rdmg * 100]
				"supernova_radiation":
					var rdmg := 0.12
					GameManager.ship_hull_pct = maxf(0.05, GameManager.ship_hull_pct - rdmg)
					arrival_msg += "  💥 %s: −%.0f%% корп." % [aph["name"], rdmg * 100]
				"magnetic_storm":
					GameManager.weapon_cooldown_modifier = 1.30
					arrival_msg += "  🌀 %s: оружие замедлено" % aph["name"]
				"asteroid_bonus":
					arrival_msg += "  🪨 %s: +добыча" % aph["name"]
		if arrival_msg != "":
			lbl_status.text += arrival_msg
			if "−" in arrival_msg:
				AudioManager.play_sfx("hurt")
		GameManager.save_game()
	)

func _refresh_topbar() -> void:
	lbl_credits.text  = "💰 %d кред." % GameManager.credits
	lbl_day.text      = "📅 День %d"   % GameManager.day
	lbl_location.text = "📍 %s"        % SYSTEMS[current_idx]["name"]
