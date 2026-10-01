extends SceneTree
## Scene-level checks: commands, forecasts, phase locking, and layout.
## -- --render-preview exports only this scene's framebuffer to /private/tmp.

var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	root.size = Vector2i(1280, 820)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_check(scene.battle.phase == "player", "Scene starts in player phase")
	_check(scene._move_button.disabled, "Move disabled without a unit")
	scene._on_cell_clicked(Vector2i(1, 2), MOUSE_BUTTON_LEFT)
	_check(scene.selected_id == "p1", "Cell selection reaches correct model unit")
	scene._set_mode("move")
	_check(not scene._board.reachable.is_empty(), "Move command populates reachable highlights")
	_check(scene._board.reachable.has(Vector2i(2, 2)), "Adjacent free tile highlighted")
	if "--render-preview" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var result: Error = root.get_texture().get_image().save_png("/private/tmp/fire-emblem-preview.png")
		_check(result == OK, "Game scene exports a preview")
	scene._on_cell_clicked(Vector2i(2, 2), MOUSE_BUTTON_LEFT)
	_check(scene.battle.get_unit("p1").moved, "Clicking highlighted tile performs movement")
	_check(not scene.battle.get_unit("p1").acted, "Movement preserves action")
	scene._restart()
	# Place a surviving opponent in range to exercise a complete command flow.
	scene.battle.get_unit("e1").pos = Vector2i(2, 2)
	scene._refresh()
	scene._on_cell_clicked(Vector2i(1, 2), MOUSE_BUTTON_LEFT)
	scene._on_cell_clicked(Vector2i(2, 2), MOUSE_BUTTON_LEFT)
	_check(scene.selected_id == "e1" and scene.pending_target.is_empty(), "Inspecting enemy never arms an attack")
	_check(scene._move_button.disabled and scene._attack_button.disabled, "Enemy inspector cannot issue player commands")
	scene._on_cell_clicked(Vector2i(1, 2), MOUSE_BUTTON_LEFT)
	scene._set_mode("attack")
	scene._on_cell_clicked(Vector2i(2, 2), MOUSE_BUTTON_LEFT)
	_check(scene.pending_target == "e1", "Attack mode opens the chosen forecast")
	_check(scene._confirm_button.visible, "Forecast exposes confirmation")
	_check(scene._counter_label.text.contains("survives"), "Counter forecast states survival condition")
	await process_frame
	await process_frame
	_check_visible_bounds(scene, Vector2(1280, 820))
	scene._confirm_attack()
	_check(scene.battle.get_unit("p1").acted, "Confirm resolves normal attack")
	_check(not scene._move_button.disabled, "Attack-first leaves Move available")
	_check(scene._attack_button.disabled, "A completed attack cannot be repeated")
	scene._on_cell_clicked(Vector2i(2, 2), MOUSE_BUTTON_LEFT)
	_check(scene.pending_target.is_empty(), "Click after spent attack cannot arm another strike")
	scene._on_cell_clicked(Vector2i(1, 2), MOUSE_BUTTON_LEFT)
	scene._set_mode("move")
	scene._on_cell_clicked(Vector2i(1, 3), MOUSE_BUTTON_LEFT)
	_check(scene.battle.get_unit("p1").moved, "Move-after-attack works through scene handlers")
	scene._end_phase()
	_check(scene.battle.phase == "enemy" and scene._end_button.disabled, "Enemy phase locks player controls")
	scene._enemy_timer.stop()
	scene._on_cell_clicked(Vector2i(1, 4), MOUSE_BUTTON_LEFT)
	_check(scene.selected_id.is_empty(), "Enemy phase ignores player selection")
	scene._restart()
	_check(scene.battle.phase == "player" and scene._enemy_timer.is_stopped(), "Restart safely cancels enemy pacing")
	_check(scene.battle.get_unit("p1").hp == 24, "Restart restores actual content")
	print("UI checks: %d passed, %d failed." % [checks - failures, failures])
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)

func _check_visible_bounds(node: Node, viewport_size: Vector2) -> void:
	if node is Button and node.is_visible_in_tree():
		var bounds: Rect2 = node.get_global_rect()
		_check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= viewport_size.x + 1 and bounds.end.y <= viewport_size.y + 1, "Visible button stays inside viewport: " + node.text)
	for child in node.get_children():
		_check_visible_bounds(child, viewport_size)
