extends RefCounted
class_name ResourceLoadUtil

static func load_texture(resource_path: String) -> Texture2D:
	if resource_path.is_empty():
		return null
	if ResourceLoader.exists(resource_path, "Texture2D"):
		var imported_texture := load(resource_path)
		if imported_texture is Texture2D:
			return imported_texture

	var image := Image.new()
	if image.load(resource_path) == OK and not image.is_empty():
		return ImageTexture.create_from_image(image)
	return null

static func load_audio_stream(resource_path: String) -> AudioStream:
	if ResourceLoader.exists(resource_path, "AudioStream"):
		var resource := load(resource_path)
		if resource is AudioStream:
			return resource

	var lower_path := resource_path.to_lower()
	if lower_path.ends_with(".mp3"):
		return AudioStreamMP3.load_from_file(resource_path)
	if lower_path.ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(resource_path)
	if lower_path.ends_with(".wav"):
		return AudioStreamWAV.load_from_file(resource_path)
	return null
