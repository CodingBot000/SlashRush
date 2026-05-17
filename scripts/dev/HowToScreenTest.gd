extends SceneTree

const HOW_TO_SCREEN_SCENE := preload("res://scenes/ui/HowToScreen.tscn")
const MAIN_MENU_SCENE := preload("res://scenes/game/MainMenu.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var how_to_screen := HOW_TO_SCREEN_SCENE.instantiate()
	root.add_child(how_to_screen)
	await process_frame

	var card_row := how_to_screen.get_node_or_null("SafeArea/Layout/CardScroll/CardRow")
	if card_row == null:
		_fail("How To card row was not created.")
		return
	var scroller := how_to_screen.get_node_or_null("SafeArea/Layout/CardScroll")
	if not scroller is ScrollContainer:
		_fail("How To screen should use a ScrollContainer.")
		return
	if scroller.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		_fail("How To horizontal scrolling should be enabled.")
		return
	if scroller.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		_fail("How To vertical scrolling should be disabled.")
		return
	if not _drag_scrolls_card_row(how_to_screen, scroller):
		_fail("How To screen should support horizontal drag scrolling.")
		return
	if card_row.get_child_count() != 5:
		_fail("How To screen should create exactly 5 cards.")
		return

	var expected_tags := [
		"enemy_basic / bomb",
		"enemy_fast",
		"enemy_armor",
		"coin / fever_orb / heal",
		"combo / fever"
	]
	for expected_tag in expected_tags:
		if not _card_row_has_tag(card_row, expected_tag):
			_fail("Missing How To target mapping: %s" % expected_tag)
			return

	var back_button := how_to_screen.get_node_or_null("SafeArea/Layout/Header/BackButton")
	if not back_button is Button:
		_fail("How To screen is missing Header BackButton.")
		return
	if back_button.text != "< BACK":
		_fail("How To BackButton should match CharacterSelect BackButton text.")
		return
	if how_to_screen.find_child("StartButton", true, false) != null:
		_fail("How To screen should not create StartButton.")
		return

	var main_menu := MAIN_MENU_SCENE.instantiate()
	root.add_child(main_menu)
	await process_frame

	var how_to_button := _find_button_with_text(main_menu, "HOW TO")
	if how_to_button == null:
		_fail("MainMenu is missing HOW TO button.")
		return
	if how_to_button.disabled:
		_fail("MainMenu HOW TO button should be enabled.")
		return

	quit()

func _card_row_has_tag(card_row: Node, expected_tag: String) -> bool:
	for card in card_row.get_children():
		var tag_label := card.find_child("TargetTags", true, false)
		if tag_label is Label and expected_tag in tag_label.text:
			return true
	return false

func _drag_scrolls_card_row(how_to_screen: Node, scroller: ScrollContainer) -> bool:
	var start_position := scroller.get_global_rect().get_center()
	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	press_event.position = start_position
	how_to_screen._input(press_event)

	var drag_event := InputEventMouseMotion.new()
	drag_event.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag_event.position = start_position + Vector2(-96.0, 0.0)
	drag_event.relative = Vector2(-96.0, 0.0)
	how_to_screen._input(drag_event)

	var release_event := InputEventMouseButton.new()
	release_event.button_index = MOUSE_BUTTON_LEFT
	release_event.pressed = false
	release_event.position = drag_event.position
	how_to_screen._input(release_event)

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
