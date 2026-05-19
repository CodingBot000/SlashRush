extends RefCounted
class_name NodeUtil

static func clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.queue_free()
