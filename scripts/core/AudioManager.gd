extends Node

# ══════════════════════════════════════════════════════════════════════════════
# AudioManager — процедурная генерация звуков (не требует внешних файлов)
# Вызовы: AudioManager.play_sfx("laser"), AudioManager.play_sfx("explosion") ...
# Доступные звуки: laser, explosion, shield, hurt, victory, defeat, jump, click
# ══════════════════════════════════════════════════════════════════════════════

const SR := 44100  # частота дискретизации

var _players: Dictionary = {}  # name → AudioStreamPlayer

func _ready() -> void:
	_build("laser",     _gen_laser())
	_build("explosion", _gen_explosion())
	_build("shield",    _gen_shield())
	_build("hurt",      _gen_hurt())
	_build("victory",   _gen_victory())
	_build("defeat",    _gen_defeat())
	_build("jump",      _gen_jump())
	_build("click",     _gen_click())
	print("[AudioManager] %d звуков загружено" % _players.size())

func _build(name: String, wav: AudioStreamWAV) -> void:
	var player := AudioStreamPlayer.new()
	player.stream    = wav
	player.volume_db = -8.0
	add_child(player)
	_players[name] = player

func play_sfx(name: String) -> void:
	if not _players.has(name): return
	var p: AudioStreamPlayer = _players[name]
	if p.playing: p.stop()
	p.play()

# ── Вспомогательные функции генерации ────────────────────────────────────────

func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format   = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo   = false
	wav.mix_rate = SR
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v := clampi(int(samples[i] * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, v)
	wav.data = data
	return wav

func _sine(t: float, freq: float) -> float:
	return sin(t * TAU * freq)

func _noise(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(-1.0, 1.0)

# ── Конкретные звуки ──────────────────────────────────────────────────────────

func _gen_laser() -> AudioStreamWAV:
	# Короткий нисходящий свист (120 мс)
	var n := int(SR * 0.12)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / SR
		var env := pow(1.0 - t / 0.12, 1.5) * 0.65
		var freq := 900.0 - t * 4000.0
		s[i] = _sine(t, maxf(freq, 220.0)) * env
	return _to_wav(s)

func _gen_explosion() -> AudioStreamWAV:
	# Низкочастотный взрыв с шумом (500 мс)
	var n := int(SR * 0.5)
	var s := PackedFloat32Array(); s.resize(n)
	var rng := RandomNumberGenerator.new(); rng.seed = 12345
	for i in n:
		var t := float(i) / SR
		var env := pow(1.0 - t / 0.5, 0.35) * 0.90
		var bass := _sine(t, 80.0) * 0.45 + _sine(t, 120.0) * 0.30
		var noise := _noise(rng) * 0.40
		s[i] = (bass + noise) * env
	return _to_wav(s)

func _gen_shield() -> AudioStreamWAV:
	# Металлический звон щита (200 мс)
	var n := int(SR * 0.20)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / SR
		var env := pow(1.0 - t / 0.20, 0.45) * 0.45
		s[i] = (_sine(t, 440.0) + _sine(t, 660.0) * 0.5 + _sine(t, 880.0) * 0.25) * env
	return _to_wav(s)

func _gen_hurt() -> AudioStreamWAV:
	# Тупой удар в корпус (250 мс)
	var n := int(SR * 0.25)
	var s := PackedFloat32Array(); s.resize(n)
	var rng := RandomNumberGenerator.new(); rng.seed = 99999
	for i in n:
		var t := float(i) / SR
		var env := pow(1.0 - t / 0.25, 0.3) * 0.80
		s[i] = (_sine(t, 55.0) * 0.65 + _noise(rng) * 0.25) * env
	return _to_wav(s)

func _gen_victory() -> AudioStreamWAV:
	# Восходящее арпеджио C-E-G-C (800 мс)
	var freqs := [261.6, 329.6, 392.0, 523.3]
	var n_total := int(SR * 0.80)
	var s := PackedFloat32Array(); s.resize(n_total)
	for fi in freqs.size():
		var start := int(SR * fi * 0.195)
		var dur   := int(SR * 0.25)
		var freq: float = freqs[fi]
		for i in dur:
			var idx := start + i
			if idx >= n_total: break
			var t := float(i) / SR
			var env := sin(t / 0.25 * PI) * 0.48
			s[idx] += _sine(t, freq) * env + _sine(t, freq * 2.0) * env * 0.25
	return _to_wav(s)

func _gen_defeat() -> AudioStreamWAV:
	# Нисходящий минорный аккорд (1.2 с)
	var freqs := [392.0, 349.2, 311.1, 261.6]
	var n_total := int(SR * 1.2)
	var s := PackedFloat32Array(); s.resize(n_total)
	for fi in freqs.size():
		var start := int(SR * fi * 0.28)
		var dur   := int(SR * 0.50)
		var freq: float = freqs[fi]
		for i in dur:
			var idx := start + i
			if idx >= n_total: break
			var t := float(i) / SR
			var env := pow(1.0 - t / 0.50, 0.28) * 0.42
			s[idx] += _sine(t, freq) * env
	return _to_wav(s)

func _gen_jump() -> AudioStreamWAV:
	# Нарастающий вой гиперпрыжка (900 мс)
	var n := int(SR * 0.9)
	var s := PackedFloat32Array(); s.resize(n)
	var rng := RandomNumberGenerator.new(); rng.seed = 55555
	for i in n:
		var t := float(i) / SR
		var env := sin(t / 0.9 * PI) * 0.70
		var freq := 80.0 + t * 440.0
		s[i] = (_sine(t, freq) * 0.65 + _noise(rng) * 0.12) * env
	return _to_wav(s)

func _gen_click() -> AudioStreamWAV:
	# Короткий UI-клик (60 мс)
	var n := int(SR * 0.06)
	var s := PackedFloat32Array(); s.resize(n)
	for i in n:
		var t := float(i) / SR
		var env := pow(1.0 - t / 0.06, 2.5) * 0.40
		s[i] = _sine(t, 800.0) * env
	return _to_wav(s)
