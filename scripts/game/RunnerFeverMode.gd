extends Node
class_name RunnerFeverMode

signal started
signal ended
signal changed(fever, active, time_left)

const GameBalance := preload("res://scripts/data/GameBalance.gd")

var fever := 0
var active := false
var time_left := 0.0
var duration_seconds := GameBalance.FEVER_DURATION
var rush_stop_before_end := GameBalance.FEVER_RUSH_SPAWN_STOP_BEFORE_END

func configure(runner_config) -> void:
	if runner_config != null:
		duration_seconds = float(runner_config.fever_duration)
		rush_stop_before_end = float(runner_config.fever_rush_spawn_stop_before_end)
	else:
		duration_seconds = GameBalance.FEVER_DURATION
		rush_stop_before_end = GameBalance.FEVER_RUSH_SPAWN_STOP_BEFORE_END

func reset() -> void:
	fever = 0
	active = false
	time_left = 0.0
	changed.emit(fever, active, time_left)

func add_fever(amount: int) -> void:
	if active or amount <= 0:
		return
	fever = min(GameBalance.FEVER_MAX, fever + amount)
	if fever >= GameBalance.FEVER_MAX:
		start()
	else:
		changed.emit(fever, active, time_left)

func penalize_fever(amount: int) -> void:
	if active or amount <= 0:
		return
	fever = max(0, fever - amount)
	changed.emit(fever, active, time_left)

func start() -> void:
	if active:
		return
	active = true
	fever = GameBalance.FEVER_MAX
	time_left = duration_seconds
	started.emit()
	changed.emit(fever, active, time_left)

func update(delta: float) -> void:
	if not active:
		return
	time_left -= delta
	if time_left <= 0.0:
		end()
		return
	fever = max(0, int(round((time_left / duration_seconds) * float(GameBalance.FEVER_MAX))))
	changed.emit(fever, active, time_left)

func end() -> void:
	if not active:
		return
	active = false
	time_left = 0.0
	fever = 0
	ended.emit()
	changed.emit(fever, active, time_left)

func should_spawn_rush() -> bool:
	return active and time_left > rush_stop_before_end
