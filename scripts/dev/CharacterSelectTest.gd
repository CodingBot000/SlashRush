extends SceneTree

const CHARACTER_SELECT_SCENE := preload("res://scenes/ui/CharacterSelect.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/game/MainMenu.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var character_select := CHARACTER_SELECT_SCENE.instantiate()
	root.add_child(character_select)
	await process_frame

	var card_row := character_select.get_node_or_null("SafeArea/Layout/CharacterScrollContainer/CharacterHBox")
	if card_row == null:
		_fail("CharacterSelect card row was not created.")
		return
	var scroller := character_select.get_node_or_null("SafeArea/Layout/CharacterScrollContainer")
	if not scroller is ScrollContainer:
		_fail("CharacterSelect should use a ScrollContainer.")
		return
	if scroller.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		_fail("CharacterSelect horizontal scrolling should be enabled.")
		return
	if scroller.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		_fail("CharacterSelect vertical scrolling should be disabled.")
		return
	if card_row.get_child_count() != 6:
		_fail("CharacterSelect should create five character cards and one Coming Soon card.")
		return
	if card_row.get_combined_minimum_size().x <= scroller.size.x:
		_fail("CharacterSelect card row should overflow horizontally.")
		return
	if not _drag_scrolls_character_row(character_select, scroller):
		_fail("CharacterSelect should support horizontal drag scrolling.")
		return
	await process_frame

	var player1_card := card_row.get_node_or_null("CharacterCard_player1")
	if player1_card == null:
		_fail("Missing player1 card.")
		return
	if not _card_has_text(player1_card, "SELECTED"):
		_fail("player1 card should show SELECTED.")
		return
	var player1_image := player1_card.find_child("CharacterImage", true, false)
	if not player1_image is TextureRect or player1_image.texture == null:
		_fail("player1 card should show a character image.")
		return

	for index in range(2, 6):
		var card := card_row.get_node_or_null("CharacterCard_player%s" % index)
		if card == null:
			_fail("Missing player%s card." % index)
			return
		if not _card_has_text(card, "LOCKED"):
			_fail("player%s card should show LOCKED." % index)
			return
		if card.find_child("LockedOverlay", true, false) == null:
			_fail("player%s card should have a locked overlay." % index)
			return

	var coming_soon_card := card_row.get_node_or_null("CharacterCard_ComingSoon")
	if coming_soon_card == null:
		_fail("Missing Coming Soon card.")
		return
	if not _card_has_text(coming_soon_card, "COMING SOON"):
		_fail("Coming Soon card should show COMING SOON.")
		return

	player1_card.emit_signal("pressed")
	if not _message_is(character_select, "Already selected"):
		_fail("player1 click should show Already selected.")
		return

	var player2_card := card_row.get_node_or_null("CharacterCard_player2")
	player2_card.emit_signal("pressed")
	if not _message_is(character_select, "Coming soon"):
		_fail("locked character click should show Coming soon.")
		return

	coming_soon_card.emit_signal("pressed")
	if not _message_is(character_select, "Coming soon"):
		_fail("Coming Soon card click should show Coming soon.")
		return

	var main_menu := MAIN_MENU_SCENE.instantiate()
	root.add_child(main_menu)
	await process_frame

	var character_button := _find_button_with_text(main_menu, "CHARACTER")
	if character_button == null:
		_fail("MainMenu is missing CHARACTER button.")
		return
	if character_button.disabled:
		_fail("MainMenu CHARACTER button should be enabled.")
		return
	if character_button.get_signal_connection_list("pressed").is_empty():
		_fail("MainMenu CHARACTER button should be connected.")
		return

	quit()

func _card_has_text(card: Node, expected_text: String) -> bool:
	for child in card.find_children("*", "Label", true, false):
		if child is Label and child.text == expected_text:
			return true
	return false

func _message_is(character_select: Node, expected_text: String) -> bool:
	var message_label := character_select.get_node_or_null("SafeArea/Layout/MessageLabel")
	return message_label is Label and message_label.text == expected_text

func _drag_scrolls_character_row(character_select: Node, scroller: ScrollContainer) -> bool:
	var start_position := scroller.get_global_rect().get_center()
	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	press_event.position = start_position
	character_select._input(press_event)

	var drag_event := InputEventMouseMotion.new()
	drag_event.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag_event.position = start_position + Vector2(-96.0, 0.0)
	drag_event.relative = Vector2(-96.0, 0.0)
	character_select._input(drag_event)

	var release_event := InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	release_event.position = drag_event.position
	character_select._input(release_event)

	return scroller.scroll_horizontal > 0

func _find_button_with_text(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var found := _find_button_with_text(child, text)
		if found:
			return found
	return null

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
