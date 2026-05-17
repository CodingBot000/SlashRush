extends Node
class_name BossFeverMode

signal started
signal ended
signal changed(fever, active, time_left)

const GameBalance := preload("res://scripts/data/GameBalance.gd")

var fever := 0
var active := false
var time_left := 0.0

func reset() -> void:
	fever = 0
	active = false
	time_left = 0.0
	changed.emit(fever, active, time_left)

func add_fever(amount: int) -> void:
	if active or amount <= 0:
		return
	fever = min(GameBalance.BOSS_FEVER_MAX, fever + amount)
	if fever >= GameBalance.BOSS_FEVER_MAX:
		start()
	else:
		changed.emit(fever, active, time_left)

func start() -> void:
	if active:
		return
	active = true
	fever = GameBalance.BOSS_FEVER_MAX
	time_left = GameBalance.BOSS_FEVER_DURATION
	started.emit()
	changed.emit(fever, active, time_left)

func update(delta: float) -> void:
	if not active:
		return
	time_left -= delta
	if time_left <= 0.0:
		end()
		return
	fever = max(0, int(round((time_left / GameBalance.BOSS_FEVER_DURATION) * float(GameBalance.BOSS_FEVER_MAX))))
	changed.emit(fever, active, time_left)

func end() -> void:
	if not active:
		return
	active = false
	time_left = 0.0
	fever = 0
	ended.emit()
	changed.emit(fever, active, time_left)

func get_time_ratio() -> float:
	if not active:
		return 0.0
	return clamp(time_left / GameBalance.BOSS_FEVER_DURATION, 0.0, 1.0)
