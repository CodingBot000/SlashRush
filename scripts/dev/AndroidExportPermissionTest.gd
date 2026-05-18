extends SceneTree

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"
const ANDROID_PRESET_SECTION := "preset.1"
const ANDROID_OPTIONS_SECTION := "preset.1.options"
const VIBRATE_PERMISSION := "android.permission.VIBRATE"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var config := ConfigFile.new()
	if config.load(EXPORT_PRESETS_PATH) != OK:
		_fail("export_presets.cfg should be loadable.")
		return

	if String(config.get_value(ANDROID_PRESET_SECTION, "platform", "")) != "Android":
		_fail("preset.1 should be the Android export preset.")
		return

	var permissions = config.get_value(ANDROID_OPTIONS_SECTION, "permissions/custom_permissions", PackedStringArray())
	if not _has_permission(permissions, VIBRATE_PERMISSION):
		_fail("Android export preset should request the VIBRATE permission for handheld haptics.")
		return

	quit()

func _has_permission(permissions, permission: String) -> bool:
	for value in permissions:
		if String(value) == permission:
			return true
	return false

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
