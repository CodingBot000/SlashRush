extends Node2D
class_name FeverImpactOverlay

const ViewportUtil := preload("res://scripts/utils/ViewportUtil.gd")
const OVERLAY_Z_INDEX := -10
const SPEED_LINE_COUNT := 100
const SPEED_LINE_MIN_WIDTH := 25.0
const SPEED_LINE_MAX_WIDTH := 45.0
const SPEED_LINE_VERTICAL_JITTER_RATIO := 0.42
const BURST_POOL_SIZE := 8
const BURST_RAY_COUNT := 12
const FLASH_SECONDS := 0.12
const DEFAULT_VIEWPORT_SIZE := Vector2(1280.0, 720.0)

var active := false
var speed_lines: Array[Line2D] = []
var burst_pool := []
var flash_layer: Polygon2D
var flash_tween: Tween
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var next_burst_delay := 0.0

func _ready() -> void:
	z_index = OVERLAY_Z_INDEX
	rng.randomize()
	_build_flash_layer()
	_build_speed_lines()
	_build_burst_pool()
	visible = false
	set_process(false)

func set_active(enabled: bool) -> void:
	if active == enabled:
		return
	active = enabled
	visible = enabled
	set_process(enabled)
	if enabled:
		_sync_flash_size()
		_prime_speed_lines()
		_start_flash()
		next_burst_delay = 0.0
	else:
		_stop_flash()
		_hide_speed_lines()
		_hide_bursts()

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	_update_speed_lines(delta)
	_update_burst_spawning(delta)
	_update_bursts(delta)

func _build_flash_layer() -> void:
	flash_layer = Polygon2D.new()
	flash_layer.name = "FeverStartFlash"
	flash_layer.color = Color(0.65, 1.0, 1.0, 0.0)
	flash_layer.z_index = 0
	add_child(flash_layer)
	_sync_flash_size()

func _build_speed_lines() -> void:
	for index in range(SPEED_LINE_COUNT):
		var line := Line2D.new()
		line.name = "SpeedLine%d" % index
		line.z_index = 1
		line.visible = false
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.set_meta("line_index", index)
		add_child(line)
		speed_lines.append(line)

func _build_burst_pool() -> void:
	for index in range(BURST_POOL_SIZE):
		var burst_node := Node2D.new()
		burst_node.name = "Burst%d" % index
		burst_node.z_index = 2
		burst_node.visible = false
		add_child(burst_node)

		var rays: Array[Line2D] = []
		for ray_index in range(BURST_RAY_COUNT):
			var ray := Line2D.new()
			ray.name = "Ray%d" % ray_index
			ray.begin_cap_mode = Line2D.LINE_CAP_ROUND
			ray.end_cap_mode = Line2D.LINE_CAP_ROUND
			ray.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
			burst_node.add_child(ray)
			rays.append(ray)

		burst_pool.append({
			"node": burst_node,
			"rays": rays,
			"directions": [],
			"age": 0.0,
			"duration": 0.0,
			"max_radius": 0.0,
			"active": false
		})

func _prime_speed_lines() -> void:
	for line in speed_lines:
		line.visible = true
		_reset_speed_line(line, true)

func _hide_speed_lines() -> void:
	for line in speed_lines:
		line.visible = false

func _update_speed_lines(delta: float) -> void:
	for line in speed_lines:
		var speed := float(line.get_meta("speed", 2000.0))
		line.position.x -= speed * delta
		_update_line_flicker(line)
		var line_length := line.points[1].x if line.points.size() > 1 else 0.0
		if line.position.x + line_length < -80.0:
			_reset_speed_line(line, false)

func _reset_speed_line(line: Line2D, randomize_x: bool) -> void:
	var viewport_size := _get_viewport_size()
	var length := rng.randf_range(300.0, 1180.0)
	var y_min := viewport_size.y * 0.02
	var y_max := viewport_size.y * 0.96
	var x: float = rng.randf_range(-viewport_size.x * 0.2, viewport_size.x * 1.2) if randomize_x else viewport_size.x + rng.randf_range(0.0, viewport_size.x * 0.55)
	var lane_index := int(line.get_meta("line_index", rng.randi_range(0, SPEED_LINE_COUNT - 1)))
	var lane_height := (y_max - y_min) / float(maxi(SPEED_LINE_COUNT, 1))
	var y := y_min + lane_height * (float(lane_index) + 0.5)
	y += rng.randf_range(-lane_height * SPEED_LINE_VERTICAL_JITTER_RATIO, lane_height * SPEED_LINE_VERTICAL_JITTER_RATIO)
	var slant := rng.randf_range(-28.0, 28.0)
	line.position = Vector2(x, y)
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(length, slant)])
	line.width = rng.randf_range(SPEED_LINE_MIN_WIDTH, SPEED_LINE_MAX_WIDTH)
	var alpha := rng.randf_range(0.12, 0.32)
	line.default_color = _random_fever_color(alpha)
	line.set_meta("speed", rng.randf_range(2200.0, 5200.0))
	line.set_meta("base_alpha", alpha)
	line.set_meta("phase", rng.randf_range(0.0, TAU))

func _update_line_flicker(line: Line2D) -> void:
	var color := line.default_color
	var base_alpha := float(line.get_meta("base_alpha", 0.14))
	var phase := float(line.get_meta("phase", 0.0))
	color.a = clamp(base_alpha * (0.65 + sin(elapsed * 18.0 + phase) * 0.35), 0.03, 0.22)
	line.default_color = color

func _update_burst_spawning(delta: float) -> void:
	next_burst_delay -= delta
	if next_burst_delay > 0.0:
		return
	_start_burst()
	next_burst_delay = rng.randf_range(0.08, 0.18)

func _start_burst() -> void:
	for burst in burst_pool:
		if bool(burst["active"]):
			continue
		var node: Node2D = burst["node"]
		var viewport_size := _get_viewport_size()
		node.position = Vector2(
			rng.randf_range(90.0, maxf(100.0, viewport_size.x - 90.0)),
			rng.randf_range(90.0, maxf(100.0, viewport_size.y * 0.78))
		)
		node.visible = true

		var directions := []
		var rays: Array = burst["rays"]
		for ray in rays:
			var angle := rng.randf_range(0.0, TAU)
			directions.append(Vector2(cos(angle), sin(angle)))
			ray.width = rng.randf_range(2.0, 5.0)
			ray.default_color = _random_fever_color(rng.randf_range(0.34, 0.58))
			ray.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
			ray.visible = true

		burst["directions"] = directions
		burst["age"] = 0.0
		burst["duration"] = rng.randf_range(0.24, 0.42)
		burst["max_radius"] = rng.randf_range(70.0, 170.0)
		burst["active"] = true
		return

func _update_bursts(delta: float) -> void:
	for burst in burst_pool:
		if not bool(burst["active"]):
			continue
		var age: float = float(burst["age"]) + delta
		var duration: float = maxf(float(burst["duration"]), 0.01)
		var t: float = clamp(age / duration, 0.0, 1.0)
		if t >= 1.0:
			burst["active"] = false
			var finished_node: Node2D = burst["node"]
			finished_node.visible = false
			continue

		var eased: float = 1.0 - pow(1.0 - t, 3.0)
		var radius: float = lerpf(8.0, float(burst["max_radius"]), eased)
		var alpha_multiplier: float = 1.0 - t
		var rays: Array = burst["rays"]
		var directions: Array = burst["directions"]
		for index in range(rays.size()):
			var ray: Line2D = rays[index]
			var direction: Vector2 = directions[index]
			var color := ray.default_color
			color.a = clamp(color.a * alpha_multiplier, 0.0, 0.6)
			ray.default_color = color
			ray.points = PackedVector2Array([direction * radius * 0.18, direction * radius])

		burst["age"] = age

func _hide_bursts() -> void:
	for burst in burst_pool:
		burst["active"] = false
		var node: Node2D = burst["node"]
		node.visible = false

func _start_flash() -> void:
	_stop_flash()
	flash_layer.color = Color(0.85, 1.0, 1.0, 0.18)
	flash_tween = create_tween()
	flash_tween.tween_property(flash_layer, "color:a", 0.0, FLASH_SECONDS)

func _stop_flash() -> void:
	if flash_tween:
		flash_tween.kill()
		flash_tween = null
	if flash_layer:
		flash_layer.color.a = 0.0

func _sync_flash_size() -> void:
	if flash_layer == null:
		return
	var viewport_size := _get_viewport_size()
	flash_layer.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(viewport_size.x, 0.0),
		viewport_size,
		Vector2(0.0, viewport_size.y)
	])

func _random_fever_color(alpha: float) -> Color:
	match rng.randi_range(0, 6):
		0:
			return Color(1.0, 0.18, 0.26, alpha)
		1:
			return Color(1.0, 0.64, 0.18, alpha)
		2:
			return Color(1.0, 0.94, 0.2, alpha)
		3:
			return Color(0.24, 1.0, 0.46, alpha)
		4:
			return Color(0.18, 0.95, 1.0, alpha)
		5:
			return Color(0.42, 0.5, 1.0, alpha)
		_:
			return Color(1.0, 0.28, 0.95, alpha)

func _get_viewport_size() -> Vector2:
	return ViewportUtil.get_visible_viewport_size(self, DEFAULT_VIEWPORT_SIZE)
