extends Control
class_name FactorySystemsHUD

const ALERT_COOLDOWN := 12.0

var _tech_backdrop: ColorRect
var _tech_panel: PanelContainer
var _tech_list: VBoxContainer
var _alerts: VBoxContainer
var _iron_line_panel: PanelContainer
var _iron_line_steps: Label
var _iron_line_status: Label
var _iron_line_limit: Label
var _research_line_panel: PanelContainer
var _research_line_steps: Label
var _research_line_status: Label
var _research_line_limit: Label
var _steel_line_panel: PanelContainer
var _steel_line_title: Label
var _steel_line_steps: Label
var _steel_line_status: Label
var _steel_line_limit: Label
var _highlighted_bottleneck: WorldBlock = null
var _iron_bottleneck: WorldBlock = null
var _iron_bottleneck_severe := false
var _research_bottleneck: WorldBlock = null
var _research_bottleneck_severe := false
var _steel_bottleneck: WorldBlock = null
var _steel_bottleneck_severe := false
var _poll_timer := 0.0
var _alert_cooldowns: Dictionary = {}


func _ready() -> void:
	add_to_group("factory_systems_hud")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_alerts()
	_build_iron_line_panel()
	_build_research_line_panel()
	_build_steel_line_panel()
	_build_tech_tree()
	MultiplayerManager.factory_alert_received.connect(_on_remote_factory_alert)
	MultiplayerManager.factory_progression_received.connect(_on_progression_sync)
	set_process(true)
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	for key: Variant in _alert_cooldowns.keys():
		_alert_cooldowns[key] = maxf(float(_alert_cooldowns[key]) - delta, 0.0)
	_poll_timer -= delta
	if _poll_timer <= 0.0:
		_poll_timer = 1.0
		_refresh_iron_line()
		_refresh_research_line()
		_refresh_steel_line()
		if not MultiplayerManager.is_client():
			TechnologyTree.refresh_unlocks()
			_poll_factory_faults()


func _unhandled_input(event: InputEvent) -> void:
	if GameChat.is_blocking_input() or get_tree().paused:
		return
	if event.is_action_pressed("technology_tree"):
		set_tech_visible(not _tech_panel.visible)
		get_viewport().set_input_as_handled()
	elif _tech_panel.visible and event.is_action_pressed("ui_cancel"):
		set_tech_visible(false)
		get_viewport().set_input_as_handled()


func set_tech_visible(open: bool) -> void:
	_tech_backdrop.visible = open
	_tech_panel.visible = open
	mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	if open:
		QuestManager.report_event("technology_tree_opened", "technology_tree", 1)
		_refresh_tech_cards()


func _on_progression_sync(_state: Dictionary) -> void:
	if _tech_panel.visible:
		call_deferred("_refresh_tech_cards")


func _build_alerts() -> void:
	_alerts = VBoxContainer.new()
	_alerts.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_alerts.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_alerts.offset_left = -390.0
	_alerts.offset_right = -18.0
	_alerts.offset_top = -110.0
	_alerts.offset_bottom = 110.0
	_alerts.alignment = BoxContainer.ALIGNMENT_CENTER
	_alerts.add_theme_constant_override("separation", 6)
	_alerts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_alerts)


func _build_iron_line_panel() -> void:
	_iron_line_panel = PanelContainer.new()
	_iron_line_panel.name = "IronLinePanel"
	_iron_line_panel.custom_minimum_size = Vector2(304, 136)
	_iron_line_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.075, 0.94)
	style.border_color = Color(0.78, 0.47, 0.20, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_iron_line_panel.add_theme_stylebox_override("panel", style)
	add_child(_iron_line_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_iron_line_panel.add_child(content)
	var title := Label.new()
	title.text = tr("IRON PRODUCTION LINE")
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.98, 0.72, 0.34))
	content.add_child(title)
	_iron_line_steps = Label.new()
	_iron_line_steps.add_theme_font_size_override("font_size", 11)
	_iron_line_steps.add_theme_color_override("font_color", Color(0.80, 0.79, 0.86))
	content.add_child(_iron_line_steps)
	_iron_line_status = Label.new()
	_iron_line_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_iron_line_status.add_theme_font_size_override("font_size", 12)
	content.add_child(_iron_line_status)
	_iron_line_limit = Label.new()
	_iron_line_limit.add_theme_font_size_override("font_size", 10)
	_iron_line_limit.add_theme_color_override("font_color", Color(0.66, 0.62, 0.72))
	content.add_child(_iron_line_limit)
	_iron_line_panel.visible = false


func _build_research_line_panel() -> void:
	_research_line_panel = PanelContainer.new()
	_research_line_panel.name = "ResearchLinePanel"
	_research_line_panel.custom_minimum_size = Vector2(304, 146)
	_research_line_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.075, 0.94)
	style.border_color = Color(0.28, 0.78, 0.92, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_research_line_panel.add_theme_stylebox_override("panel", style)
	add_child(_research_line_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_research_line_panel.add_child(content)
	var title := Label.new()
	title.text = tr("STEAM RESEARCH LINE")
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.44, 0.88, 1.0))
	content.add_child(title)
	_research_line_steps = Label.new()
	_research_line_steps.add_theme_font_size_override("font_size", 11)
	_research_line_steps.add_theme_color_override("font_color", Color(0.80, 0.79, 0.86))
	content.add_child(_research_line_steps)
	_research_line_status = Label.new()
	_research_line_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_research_line_status.add_theme_font_size_override("font_size", 12)
	content.add_child(_research_line_status)
	_research_line_limit = Label.new()
	_research_line_limit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_research_line_limit.add_theme_font_size_override("font_size", 10)
	_research_line_limit.add_theme_color_override("font_color", Color(0.66, 0.62, 0.72))
	content.add_child(_research_line_limit)
	_research_line_panel.visible = false


func _build_steel_line_panel() -> void:
	_steel_line_panel = PanelContainer.new()
	_steel_line_panel.name = "SteelLinePanel"
	_steel_line_panel.custom_minimum_size = Vector2(304, 176)
	_steel_line_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.075, 0.94)
	style.border_color = Color(0.72, 0.76, 0.82, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 11
	style.content_margin_right = 11
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_steel_line_panel.add_theme_stylebox_override("panel", style)
	add_child(_steel_line_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_steel_line_panel.add_child(content)
	_steel_line_title = Label.new()
	_steel_line_title.text = tr("STEEL PRODUCTION LINE")
	_steel_line_title.add_theme_font_size_override("font_size", 14)
	_steel_line_title.add_theme_color_override("font_color", Color(0.84, 0.88, 0.96))
	content.add_child(_steel_line_title)
	_steel_line_steps = Label.new()
	_steel_line_steps.add_theme_font_size_override("font_size", 11)
	_steel_line_steps.add_theme_color_override("font_color", Color(0.80, 0.79, 0.86))
	content.add_child(_steel_line_steps)
	_steel_line_status = Label.new()
	_steel_line_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_steel_line_status.add_theme_font_size_override("font_size", 12)
	content.add_child(_steel_line_status)
	_steel_line_limit = Label.new()
	_steel_line_limit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_steel_line_limit.add_theme_font_size_override("font_size", 10)
	_steel_line_limit.add_theme_color_override("font_color", Color(0.66, 0.62, 0.72))
	content.add_child(_steel_line_limit)
	_steel_line_panel.visible = false


func _refresh_iron_line() -> void:
	var quest_state := QuestManager.get_quest_state("steam_iron_line")
	var should_track := quest_state == "available" or quest_state == "in_progress"
	_iron_line_panel.visible = false
	if not should_track:
		_set_bottleneck_highlight(null, false)
		return

	var snapshot := ProductionChainAnalyzer.iron_line_snapshot(get_tree())
	_iron_line_steps.text = "%s %s   %s %s   %s %s   %s %s" % [
		_step_icon(bool(snapshot.get("crusher_ready", false))), tr("Crusher"),
		_step_icon(bool(snapshot.get("furnace_ready", false))), tr("Furnace"),
		_step_icon(bool(snapshot.get("storage_ready", false))), tr("Storage"),
		_step_icon(bool(snapshot.get("connected", false))), tr("Connected"),
	]
	var reason := str(snapshot.get("reason", ""))
	_iron_line_status.text = tr(reason)
	var severe := reason in [
		"Logistics disconnected", "Conveyor jam", "Inserter output blocked",
		"Crusher output blocked", "Furnace output blocked",
	]
	if reason in ["Iron line is running", "Iron line is ready"]:
		_iron_line_status.modulate = Color(0.42, 1.0, 0.56)
	elif severe:
		_iron_line_status.modulate = Color(1.0, 0.28, 0.20)
	else:
		_iron_line_status.modulate = Color(1.0, 0.72, 0.30)
	_iron_line_limit.text = tr("Bottleneck: %s — %.0f ingots/min") % [
		tr(str(snapshot.get("bottleneck", "Steam Crusher limits throughput"))),
		float(snapshot.get("capacity_per_minute", 0.0)),
	] if bool(snapshot.get("connected", false)) else tr("Connect machines with at least two inserters.")
	_set_bottleneck_highlight(snapshot.get("bottleneck_block") as WorldBlock, severe)

	if bool(snapshot.get("connected", false)) \
			and QuestManager.is_objective_done("steam_iron_line", 0) \
			and QuestManager.is_objective_done("steam_iron_line", 1) \
			and QuestManager.is_objective_done("steam_iron_line", 2):
		QuestManager.report_event("factory_line_online", "iron", 1)


func _refresh_research_line() -> void:
	var quest_state := QuestManager.get_quest_state("steam_research_batch")
	var should_track := quest_state == "available" or quest_state == "in_progress"
	_research_line_panel.visible = false
	if not should_track:
		_set_bottleneck_highlight(null, false, "research")
		return

	var snapshot := ProductionChainAnalyzer.research_line_snapshot(get_tree())
	_research_line_steps.text = "%s %s   %s %s   %s %s   %s %s" % [
		_step_icon(bool(snapshot.get("core_assembler_ready", false))), tr("Core"),
		_step_icon(bool(snapshot.get("pack_assembler_ready", false))), tr("Pack"),
		_step_icon(bool(snapshot.get("storage_ready", false))), tr("Storage"),
		_step_icon(bool(snapshot.get("connected", false))), tr("Connected"),
	]
	var reason := str(snapshot.get("reason", ""))
	_research_line_status.text = tr(reason)
	var severe := reason in [
		"Research logistics disconnected", "Research conveyor jam", "Research inserter output blocked",
		"Core assembler output blocked", "Pack assembler output blocked",
	]
	if reason in ["Research line is running", "Research line is ready"]:
		_research_line_status.modulate = Color(0.42, 1.0, 0.56)
	elif severe:
		_research_line_status.modulate = Color(1.0, 0.28, 0.20)
	else:
		_research_line_status.modulate = Color(1.0, 0.72, 0.30)
	_research_line_limit.text = tr("Bottleneck: %s — %.1f packs/min") % [
		tr(str(snapshot.get("bottleneck", "Steam Assemblers limit throughput"))),
		float(snapshot.get("capacity_per_minute", 0.0)),
	] if bool(snapshot.get("connected", false)) else tr("Connect both assemblers to an output chest with inserters.")
	_set_bottleneck_highlight(snapshot.get("bottleneck_block") as WorldBlock, severe, "research")

	if bool(snapshot.get("connected", false)):
		var production_ready := true
		for objective_index in 5:
			if not QuestManager.is_objective_done("steam_research_batch", objective_index):
				production_ready = false
				break
		if production_ready:
			QuestManager.report_event("factory_line_online", "steam_research", 1)


func _refresh_steel_line() -> void:
	var steel_quest_state := QuestManager.get_quest_state("steam_steel_line")
	var recovery_quest_state := QuestManager.get_quest_state("steam_creosote_loop")
	var steel_active := steel_quest_state == "available" or steel_quest_state == "in_progress"
	var recovery_focus := recovery_quest_state == "available" or recovery_quest_state == "in_progress"
	var should_track := steel_active or recovery_focus
	_steel_line_panel.visible = false
	if not should_track:
		_set_bottleneck_highlight(null, false, "steel")
		return

	var snapshot := ProductionChainAnalyzer.steel_line_snapshot(get_tree())
	if bool(snapshot.get("creosote_recovery", false)):
		QuestManager.report_event("factory_line_online", "creosote", 1)

	if recovery_focus:
		_steel_line_title.text = tr("CREOSOTE RECOVERY LOOP")
		_steel_line_steps.text = "%s %s   %s %s\n%s %s   %s %s" % [
			_step_icon(bool(snapshot.get("coke_oven_ready", false))), tr("Coke Oven"),
			_step_icon(bool(snapshot.get("creosote_buffer_ready", false))), tr("Tank"),
			_step_icon(bool(snapshot.get("creosote_boiler_ready", false))), tr("Boiler"),
			_step_icon(bool(snapshot.get("creosote_recovery", false))), tr("Connected"),
		]
		var recovery_reason := "Build a Coke Oven"
		if bool(snapshot.get("coke_oven_ready", false)):
			recovery_reason = "Connect a Fluid Tank"
		if bool(snapshot.get("creosote_buffer_ready", false)):
			recovery_reason = "Connect a Steam Boiler"
		if bool(snapshot.get("creosote_recovery", false)):
			recovery_reason = "Creosote recovery is online"
		_steel_line_status.text = tr(recovery_reason)
		_steel_line_status.modulate = Color(0.42, 1.0, 0.56) \
			if bool(snapshot.get("creosote_recovery", false)) else Color(1.0, 0.72, 0.30)
		_steel_line_limit.text = tr("1 L creosote = 2 seconds of boiler burn time.")
		var recovery_block := snapshot.get("creosote_block") as WorldBlock
		if bool(snapshot.get("creosote_recovery", false)):
			recovery_block = null
		_set_bottleneck_highlight(
			recovery_block,
			false,
			"steel"
		)
		return

	_steel_line_title.text = tr("STEEL PRODUCTION LINE")
	_steel_line_steps.text = "%s %s   %s %s   %s %s\n%s %s   %s %s   %s %s" % [
		_step_icon(bool(snapshot.get("coke_oven_ready", false))), tr("Coke"),
		_step_icon(bool(snapshot.get("blast_furnace_ready", false))), tr("Blast"),
		_step_icon(bool(snapshot.get("press_ready", false))), tr("Press"),
		_step_icon(bool(snapshot.get("storage_ready", false))), tr("Storage"),
		_step_icon(bool(snapshot.get("connected", false))), tr("Connected"),
		_step_icon(bool(snapshot.get("creosote_recovery", false))), tr("Recovery"),
	]
	var reason := str(snapshot.get("reason", ""))
	_steel_line_status.text = tr(reason)
	var severe := reason in [
		"Steel logistics disconnected", "Steel conveyor jam", "Steel inserter output blocked",
		"Coke oven output blocked", "Drain creosote from coke oven",
		"Blast furnace output blocked", "Steel press output blocked",
	]
	if reason in ["Steel line is running", "Steel line is ready"]:
		_steel_line_status.modulate = Color(0.42, 1.0, 0.56)
	elif severe:
		_steel_line_status.modulate = Color(1.0, 0.28, 0.20)
	else:
		_steel_line_status.modulate = Color(1.0, 0.72, 0.30)
	var throughput_text := tr("Bottleneck: %s — %.1f plates/min") % [
		tr(str(snapshot.get("bottleneck", "Coke Oven limits steel throughput"))),
		float(snapshot.get("capacity_per_minute", 0.0)),
	] if bool(snapshot.get("connected", false)) else tr("Connect the coke oven, blast furnace, press, and chest with at least three inserters.")
	var recovery_text := tr("Creosote recovery: online") if bool(snapshot.get("creosote_recovery", false)) \
		else tr("Creosote recovery: connect tank and boiler")
	_steel_line_limit.text = throughput_text + "\n" + recovery_text
	_set_bottleneck_highlight(snapshot.get("bottleneck_block") as WorldBlock, severe, "steel")

	if bool(snapshot.get("connected", false)):
		var production_ready := true
		for objective_index in 4:
			if not QuestManager.is_objective_done("steam_steel_line", objective_index):
				production_ready = false
				break
		if production_ready:
			QuestManager.report_event("factory_line_online", "steel", 1)


func _step_icon(ready: bool) -> String:
	return "✓" if ready else "○"


func _set_bottleneck_highlight(block: WorldBlock, severe: bool, source: String = "iron") -> void:
	if source == "steel":
		_steel_bottleneck = block
		_steel_bottleneck_severe = severe
	elif source == "research":
		_research_bottleneck = block
		_research_bottleneck_severe = severe
	else:
		_iron_bottleneck = block
		_iron_bottleneck_severe = severe
	var selected_block: WorldBlock = null
	var selected_severe := false
	if _steel_line_panel != null and _steel_line_panel.visible \
			and _steel_bottleneck != null and is_instance_valid(_steel_bottleneck):
		selected_block = _steel_bottleneck
		selected_severe = _steel_bottleneck_severe
	elif _research_line_panel != null and _research_line_panel.visible \
			and _research_bottleneck != null and is_instance_valid(_research_bottleneck):
		selected_block = _research_bottleneck
		selected_severe = _research_bottleneck_severe
	elif _iron_line_panel != null and _iron_line_panel.visible \
			and _iron_bottleneck != null and is_instance_valid(_iron_bottleneck):
		selected_block = _iron_bottleneck
		selected_severe = _iron_bottleneck_severe
	if _highlighted_bottleneck != null and is_instance_valid(_highlighted_bottleneck) \
			and _highlighted_bottleneck != selected_block:
		_highlighted_bottleneck.set_factory_highlight(false)
	_highlighted_bottleneck = selected_block
	if _highlighted_bottleneck != null and is_instance_valid(_highlighted_bottleneck):
		_highlighted_bottleneck.set_factory_highlight(
			true,
			Color(1.0, 0.25, 0.16) if selected_severe else Color(1.0, 0.70, 0.20)
		)


func _build_tech_tree() -> void:
	_tech_backdrop = ColorRect.new()
	_tech_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tech_backdrop.color = Color(0, 0, 0, 0.72)
	_tech_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_tech_backdrop.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			set_tech_visible(false)
	)
	add_child(_tech_backdrop)
	_tech_panel = PanelContainer.new()
	_tech_panel.set_anchors_preset(Control.PRESET_CENTER)
	_tech_panel.offset_left = -440.0
	_tech_panel.offset_top = -310.0
	_tech_panel.offset_right = 440.0
	_tech_panel.offset_bottom = 310.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.045, 0.075, 0.99)
	style.border_color = Color(0.38, 0.72, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.set_content_margin_all(18)
	_tech_panel.add_theme_stylebox_override("panel", style)
	add_child(_tech_panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	_tech_panel.add_child(root)
	var title_row := HBoxContainer.new()
	var title := Label.new()
	title.text = tr("TECHNOLOGY TREE") + "  [N]"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title_row.add_child(title)
	var close := Button.new()
	close.text = "X"
	close.pressed.connect(set_tech_visible.bind(false))
	title_row.add_child(close)
	root.add_child(title_row)
	var intro := Label.new()
	intro.text = tr("Build production lines, defeat bosses, and consume research packs to unlock each era.")
	intro.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))
	root.add_child(intro)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_tech_list = VBoxContainer.new()
	_tech_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tech_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_tech_list)
	set_tech_visible(false)


func _refresh_tech_cards() -> void:
	for child: Node in _tech_list.get_children():
		child.queue_free()
	for index in TechnologyTree.STAGES.size():
		var stage: Dictionary = TechnologyTree.STAGES[index]
		var unlocks := PackedStringArray(stage.get("machines", []))
		unlocks.append_array(PackedStringArray(stage.get("components", [])))
		var unlocked := TechnologyTree.is_stage_unlocked(str(stage["id"]))
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.14, 0.12, 0.96) if unlocked else Color(0.10, 0.085, 0.13, 0.94)
		style.border_color = Color(0.30, 0.92, 0.50) if unlocked else Color(0.30, 0.28, 0.38)
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", style)
		_tech_list.add_child(card)
		var row := HBoxContainer.new()
		card.add_child(row)
		var badge := Label.new()
		badge.text = "✓" if unlocked else "%d" % (index + 1)
		badge.custom_minimum_size = Vector2(42, 42)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 20)
		badge.add_theme_color_override("font_color", Color(0.38, 1.0, 0.58) if unlocked else Color(0.60, 0.58, 0.68))
		row.add_child(badge)
		var description := RichTextLabel.new()
		description.fit_content = true
		description.bbcode_enabled = true
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.text = "[font_size=17][b]%s[/b][/font_size]  %s\n%s\n[color=#8eb5d9]%s[/color]\n[color=#a7a2b3]%s[/color]" % [tr(str(stage["title"])), tr("UNLOCKED") if unlocked else tr("LOCKED"), tr(str(stage["description"])), TechnologyTree.requirement_text(stage), ", ".join(unlocks)]
		row.add_child(description)
		if not unlocked and str(stage.get("id", "")) != "foundation":
			var stage_id := str(stage["id"])
			var analyze := Button.new()
			analyze.custom_minimum_size.x = 180.0
			if not TechnologyTree.is_stage_world_condition_met(stage):
				analyze.text = tr("Requirements not met")
				analyze.disabled = true
			else:
				analyze.text = "%s\n%s" % [tr("Analyze"), InventoryCost.describe(ResearchSystem.requirements(stage_id))]
				analyze.disabled = not ResearchSystem.can_analyze(stage_id)
			analyze.pressed.connect(_on_analyze_pressed.bind(stage_id))
			row.add_child(analyze)


func _on_analyze_pressed(stage_id: String) -> void:
	if ResearchSystem.analyze(stage_id):
		_refresh_tech_cards()


func _poll_factory_faults() -> void:
	for node: Node in get_tree().get_nodes_in_group("factory_machine"):
		var machine := node as MachineContainer
		if machine == null or machine.simulation_sleeping:
			continue
		if machine is ConveyorContainer and (machine as ConveyorContainer).jammed:
			_emit_alert(machine, "Conveyor jam", Color(1.0, 0.34, 0.18))
			continue
		if not _has_work_waiting(machine):
			continue
		var reason := _fault_reason(machine)
		if not reason.is_empty():
			_emit_alert(machine, reason, Color(1.0, 0.58, 0.20) if reason != "Output blocked" else Color(1.0, 0.28, 0.18))


func _has_work_waiting(machine: MachineContainer) -> bool:
	for slot: MachineSlot in machine.slots:
		if slot.role in [MachineSlot.Role.INPUT, MachineSlot.Role.FUEL] and not slot.is_empty():
			return true
	return false


func _fault_reason(machine: MachineContainer) -> String:
	if machine is PoweredMachineContainer:
		var powered := machine as PoweredMachineContainer
		if powered.requires_power and powered.power_stored <= 0.0:
			return "No Power"
	if machine is SteamMachineContainer and not (machine as SteamMachineContainer).has_steam():
		return "No Steam"
	for slot: MachineSlot in machine.slots:
		if slot.role != MachineSlot.Role.OUTPUT or slot.is_empty():
			continue
		var capacity := slot.max_stack_override if slot.max_stack_override > 0 else int(slot.item.get("max_stack", 64))
		if int(slot.item.get("count", 0)) >= capacity:
			return "Output blocked"
	return ""


func _emit_alert(machine: MachineContainer, reason: String, color: Color) -> void:
	var block := machine.get_parent() as WorldBlock
	var anchor := block.grid_pos if block != null else Vector2i.ZERO
	var key := "%s:%s" % [anchor, reason]
	if float(_alert_cooldowns.get(key, 0.0)) > 0.0:
		return
	_alert_cooldowns[key] = ALERT_COOLDOWN
	var machine_name := block.block_id.replace("_", " ").capitalize() if block != null else "Machine"
	_show_alert(machine_name, reason, color)
	if MultiplayerManager.is_active() and MultiplayerManager.is_server():
		MultiplayerManager.broadcast_factory_alert({"anchor": anchor, "machine": machine_name, "reason": reason})


func _on_remote_factory_alert(alert: Dictionary) -> void:
	if not MultiplayerManager.is_client():
		return
	var reason := str(alert.get("reason", ""))
	var anchor: Variant = alert.get("anchor", Vector2i.ZERO)
	var key := "%s:%s" % [anchor, reason]
	if float(_alert_cooldowns.get(key, 0.0)) > 0.0:
		return
	_alert_cooldowns[key] = ALERT_COOLDOWN
	var color := Color(1.0, 0.28, 0.18) if reason in ["Output blocked", "Conveyor jam"] else Color(1.0, 0.58, 0.20)
	_show_alert(str(alert.get("machine", "Machine")), reason, color)


func _show_alert(machine_name: String, reason: String, color: Color) -> void:
	var severity := "danger" if reason in ["Output blocked", "Conveyor jam"] else "warning"
	NotificationCenter.push("factory", machine_name, tr(reason), severity)
	var label := Label.new()
	label.text = "⚠  %s — %s" % [machine_name, tr(reason)]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(360, 34)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	_alerts.add_child(label)
	while _alerts.get_child_count() > 4:
		var oldest := _alerts.get_child(0)
		_alerts.remove_child(oldest)
		oldest.queue_free()
	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)
