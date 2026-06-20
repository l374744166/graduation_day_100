extends Control

const STAT_LABELS := {
	"money": "金钱",
	"mood": "情绪",
	"skill": "能力",
	"relationship": "关系",
	"pressure": "压力",
	"self_identity": "自我认同"
}

const STAT_ORDER := ["money", "mood", "skill", "relationship", "pressure", "self_identity"]
const MOBILE_WIDTH := 760

var notice_text := ""
var computer_detail_label: RichTextLabel

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_show_main_menu()

func _on_viewport_size_changed() -> void:
	if get_child_count() > 0:
		var current := get_child(0)
		if current is Control:
			(current as Control).set_anchors_preset(Control.PRESET_FULL_RECT)

func _show_main_menu() -> void:
	_clear()
	var background := _make_background(Color(0.10, 0.12, 0.14))
	add_child(background)

	var margin := _make_margin(_screen_margin())
	background.add_child(margin)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 16 if _is_mobile_layout() else 22)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "毕业后的第100天"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 34 if _is_mobile_layout() else 52)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "7 天 Demo | 手机试玩版" if _is_mobile_layout() else "7 天 Demo | PC 单机叙事生活模拟"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17 if _is_mobile_layout() else 20)
	subtitle.add_theme_color_override("font_color", Color(0.74, 0.79, 0.83))
	layout.add_child(subtitle)

	layout.add_child(_spacer(Vector2(1, 18 if _is_mobile_layout() else 34)))

	var new_button := _make_button("新游戏")
	new_button.pressed.connect(_on_new_game_pressed)
	layout.add_child(new_button)

	var continue_button := _make_button("继续游戏")
	continue_button.disabled = not SaveManager.has_save()
	continue_button.pressed.connect(_on_continue_pressed)
	layout.add_child(continue_button)

	var quit_button := _make_button("退出游戏")
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	layout.add_child(quit_button)

func _on_new_game_pressed() -> void:
	GameState.reset()
	notice_text = ""
	_show_next_event_or_room()

func _on_continue_pressed() -> void:
	if SaveManager.load_game():
		notice_text = "已读取 user://save_001.json"
		if GameState.day > 7:
			_show_ending_report()
		else:
			_show_next_event_or_room()
	else:
		notice_text = "没有找到可读取的存档。"
		_show_main_menu()

func _show_next_event_or_room() -> void:
	var event := DayManager.get_next_event()
	if event.size() > 0:
		_show_event_dialogue(event)
	else:
		_show_room()

func _show_room() -> void:
	_clear()
	var background := _make_background(Color(0.13, 0.15, 0.16))
	add_child(background)
	background.add_child(_make_room_layout("room"))

func _make_room_layout(active_view: String) -> Control:
	var mobile := _is_mobile_layout()
	var margin := _make_margin(12 if mobile else 28)
	var main: BoxContainer
	if mobile:
		var scroll := ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		margin.add_child(scroll)
		main = VBoxContainer.new()
		main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(main)
	else:
		main = HBoxContainer.new()
		margin.add_child(main)
	main.add_theme_constant_override("separation", 14 if mobile else 24)

	var sidebar := _make_panel(Color(0.18, 0.20, 0.21), Vector2(0 if mobile else 292, 0))
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL if mobile else Control.SIZE_SHRINK_BEGIN
	main.add_child(sidebar)

	var side_layout := VBoxContainer.new()
	side_layout.add_theme_constant_override("separation", 12)
	sidebar.add_child(side_layout)

	var header := Label.new()
	header.text = "第 %d 天  %s" % [GameState.day, GameState.get_time_slot_label()]
	header.add_theme_font_size_override("font_size", 22 if mobile else 25)
	side_layout.add_child(header)

	var place := Label.new()
	place.text = "当前位置：%s" % LocationManager.get_location_name(GameState.current_location)
	place.add_theme_color_override("font_color", Color(0.77, 0.82, 0.84))
	side_layout.add_child(place)

	side_layout.add_child(_separator())

	for stat in STAT_ORDER:
		side_layout.add_child(_make_status_row(STAT_LABELS[stat], int(GameState.get(stat)), stat == "money"))

	side_layout.add_child(_separator())
	var nav_grid := GridContainer.new()
	nav_grid.columns = 2 if mobile else 1
	nav_grid.add_theme_constant_override("h_separation", 8)
	nav_grid.add_theme_constant_override("v_separation", 8)
	side_layout.add_child(nav_grid)
	nav_grid.add_child(_make_nav_button("行动", active_view == "actions", _show_action_panel))
	nav_grid.add_child(_make_nav_button("出门", active_view == "locations", _show_location_select))
	nav_grid.add_child(_make_nav_button("电脑", active_view == "computer", _show_computer))
	nav_grid.add_child(_make_nav_button("休息", false, func() -> void: _perform_action_by_id("rest")))
	side_layout.add_child(_separator())
	var system_grid := GridContainer.new()
	system_grid.columns = 3 if mobile else 1
	system_grid.add_theme_constant_override("h_separation", 8)
	system_grid.add_theme_constant_override("v_separation", 8)
	side_layout.add_child(system_grid)
	system_grid.add_child(_make_nav_button("存档", false, _save_from_room))
	system_grid.add_child(_make_nav_button("读档", false, _load_from_room))
	system_grid.add_child(_make_nav_button("主菜单", false, _show_main_menu))

	var content := _make_panel(Color(0.20, 0.22, 0.22), Vector2(0, 0))
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(content)

	var content_layout := VBoxContainer.new()
	content_layout.add_theme_constant_override("separation", 14 if mobile else 18)
	content_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(content_layout)

	match active_view:
		"actions":
			_fill_action_panel(content_layout)
		"locations":
			_fill_location_select(content_layout)
		"computer":
			_fill_computer(content_layout)
		_:
			_fill_room_home(content_layout)

	return margin

func _fill_room_home(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "房间"
	title.add_theme_font_size_override("font_size", 28 if _is_mobile_layout() else 34)
	parent.add_child(title)

	var room_text := RichTextLabel.new()
	room_text.bbcode_enabled = true
	room_text.fit_content = true
	room_text.text = "[color=#d7e0e3]桌上放着电脑、纸杯和还没整理完的证件袋。窗外不是校园广播，而是城市里连续不断的车声。[/color]\n\n今天还有一个时段可以安排。你可以处理求职、出门换换空气，或者坐在电脑前假装自己很有计划。"
	room_text.custom_minimum_size = Vector2(0, 128)
	parent.add_child(room_text)

	var notice := Label.new()
	notice.text = notice_text
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_color_override("font_color", Color(0.98, 0.82, 0.52))
	parent.add_child(notice)

	parent.add_child(_spacer(Vector2(1, 8)))

	var hint := Label.new()
	hint.text = "日程：上午 / 下午 / 晚上。每次行动会推进一个时段，晚上结束后扣除 60 生活费。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.70, 0.76, 0.78))
	parent.add_child(hint)

func _show_action_panel() -> void:
	_clear()
	var background := _make_background(Color(0.13, 0.15, 0.16))
	add_child(background)
	background.add_child(_make_room_layout("actions"))

func _fill_action_panel(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "选择行动"
	title.add_theme_font_size_override("font_size", 27 if _is_mobile_layout() else 32)
	parent.add_child(title)

	var intro := Label.new()
	intro.text = "当前时段：%s。选择一个行动后，时间会向前推进。" % GameState.get_time_slot_label()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", Color(0.75, 0.80, 0.82))
	parent.add_child(intro)

	var grid := GridContainer.new()
	grid.columns = 1 if _is_mobile_layout() else 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)

	for action in ActionManager.get_actions_for_state():
		grid.add_child(_make_action_card(action))

func _make_action_card(action: Dictionary) -> Control:
	var panel := _make_panel(Color(0.25, 0.27, 0.27), Vector2(0, 158 if _is_mobile_layout() else 140))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var title := Label.new()
	title.text = action.get("name", "行动")
	title.add_theme_font_size_override("font_size", 21)
	layout.add_child(title)

	var desc := Label.new()
	desc.text = action.get("description", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.76, 0.81, 0.82))
	layout.add_child(desc)

	var effects := Label.new()
	effects.text = _format_effects(action.get("effects", {}))
	effects.add_theme_color_override("font_color", Color(0.99, 0.84, 0.55))
	layout.add_child(effects)

	var button := _make_button("执行")
	button.custom_minimum_size = Vector2(0 if _is_mobile_layout() else 110, 44 if _is_mobile_layout() else 36)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if _is_mobile_layout() else Control.SIZE_SHRINK_END
	button.pressed.connect(_perform_action.bind(action))
	layout.add_child(button)
	return panel

func _perform_action_by_id(action_id: String) -> void:
	var action := ActionManager.get_action_by_id(action_id)
	if action.size() > 0:
		_perform_action(action)

func _perform_action(action: Dictionary) -> void:
	var changes := GameState.apply_effects(action.get("effects", {}))
	var summary := DayManager.advance_after_action(action.get("name", "行动"), changes)
	if bool(summary.get("new_day_started", false)):
		_show_day_summary(summary)
	else:
		notice_text = "%s完成了。变化：%s" % [action.get("name", "行动"), _format_changes(changes)]
		_show_room()

func _show_location_select() -> void:
	_clear()
	var background := _make_background(Color(0.13, 0.15, 0.16))
	add_child(background)
	background.add_child(_make_room_layout("locations"))

func _fill_location_select(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "地点选择"
	title.add_theme_font_size_override("font_size", 27 if _is_mobile_layout() else 32)
	parent.add_child(title)

	var intro := Label.new()
	intro.text = "出门不会消耗时段。它改变你所处的场景，也为之后扩展地点事件留下入口。"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", Color(0.75, 0.80, 0.82))
	parent.add_child(intro)

	var grid := GridContainer.new()
	grid.columns = 1 if _is_mobile_layout() else 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	parent.add_child(grid)

	for location in LocationManager.get_locations():
		var panel := _make_panel(Color(0.25, 0.27, 0.27), Vector2(0, 118))
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var layout := VBoxContainer.new()
		layout.add_theme_constant_override("separation", 6)
		panel.add_child(layout)

		var name := Label.new()
		name.text = location.get("name", "")
		name.add_theme_font_size_override("font_size", 21)
		layout.add_child(name)

		var desc := Label.new()
		desc.text = location.get("description", "")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", Color(0.76, 0.81, 0.82))
		layout.add_child(desc)

		var button := _make_button("前往")
		button.custom_minimum_size = Vector2(0 if _is_mobile_layout() else 110, 44 if _is_mobile_layout() else 34)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if _is_mobile_layout() else Control.SIZE_SHRINK_END
		button.pressed.connect(_travel_to_location.bind(location.get("id", "dorm"), location.get("name", "")))
		layout.add_child(button)
		grid.add_child(panel)

func _show_computer() -> void:
	_clear()
	var background := _make_background(Color(0.13, 0.15, 0.16))
	add_child(background)
	background.add_child(_make_room_layout("computer"))

func _fill_computer(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "电脑"
	title.add_theme_font_size_override("font_size", 27 if _is_mobile_layout() else 32)
	parent.add_child(title)

	var layout: BoxContainer
	if _is_mobile_layout():
		layout = VBoxContainer.new()
	else:
		layout = HBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(layout)

	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(0 if _is_mobile_layout() else 230, 0)
	menu.add_theme_constant_override("separation", 10)
	layout.add_child(menu)

	var entries := [
		["招聘网站", "页面上不断刷新着岗位。每一个职位都像一扇门，也像一道题。"],
		["邮件", "收件箱里有广告、系统通知，以及几封你反复确认过的自动回复。"],
		["简历", "文件名从'最终版'一路变成'最终版真的最终版'。"],
		["学习课程", "课程列表很长，你把它当作重新找回节奏的方式。"],
		["兼职平台", "即时结算的岗位看起来辛苦，但至少能让余额动一下。"]
	]

	computer_detail_label = RichTextLabel.new()
	computer_detail_label.bbcode_enabled = true
	computer_detail_label.fit_content = _is_mobile_layout()
	computer_detail_label.custom_minimum_size = Vector2(0, 180 if _is_mobile_layout() else 0)
	computer_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	computer_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(computer_detail_label)

	for entry in entries:
		var button := _make_button(entry[0])
		button.pressed.connect(_set_computer_detail.bind(entry[0], entry[1]))
		menu.add_child(button)

	_set_computer_detail(entries[0][0], entries[0][1])

func _set_computer_detail(title: String, body: String) -> void:
	computer_detail_label.text = "[font_size=28]%s[/font_size]\n\n[color=#d7e0e3]%s[/color]\n\n[color=#f4cf83]第一版为静态入口，后续可以接入岗位列表、邮件事件、简历评分、课程进度和兼职任务。[/color]" % [title, body]

func _show_event_dialogue(event: Dictionary) -> void:
	_clear()
	var background := _make_background(Color(0.11, 0.12, 0.13))
	add_child(background)

	var margin := _make_margin(_screen_margin())
	background.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var panel := _make_panel(Color(0.20, 0.22, 0.23), Vector2(0, 0))
	scroll.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	panel.add_child(layout)

	var day_label := Label.new()
	day_label.text = "第 %d 天剧情" % GameState.day
	day_label.add_theme_color_override("font_color", Color(0.99, 0.84, 0.55))
	layout.add_child(day_label)

	var title := Label.new()
	title.text = event.get("title", "")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 29 if _is_mobile_layout() else 36)
	layout.add_child(title)

	var description := Label.new()
	description.text = event.get("description", "")
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 18 if _is_mobile_layout() else 20)
	description.add_theme_color_override("font_color", Color(0.83, 0.88, 0.90))
	layout.add_child(description)

	layout.add_child(_separator())

	for choice in event.get("choices", []):
		var choice_text := "%s\n%s" % [choice.get("text", ""), _format_effects(choice.get("effects", {}))] if _is_mobile_layout() else "%s    %s" % [choice.get("text", ""), _format_effects(choice.get("effects", {}))]
		var button := _make_button(choice_text)
		button.custom_minimum_size = Vector2(0, 64 if _is_mobile_layout() else 48)
		button.pressed.connect(_choose_event_option.bind(choice))
		layout.add_child(button)

func _choose_event_option(choice: Dictionary) -> void:
	var changes := GameState.apply_effects(choice.get("effects", {}))
	EventManager.mark_event_completed(GameState.day)
	notice_text = "剧情选择：%s。变化：%s" % [choice.get("text", ""), _format_changes(changes)]
	_show_room()

func _show_day_summary(summary: Dictionary) -> void:
	_clear()
	var background := _make_background(Color(0.12, 0.13, 0.14))
	add_child(background)
	var margin := _make_margin(_screen_margin())
	background.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var panel := _make_panel(Color(0.20, 0.22, 0.23), Vector2(0, 0))
	scroll.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "第 %d 天总结" % int(summary.get("previous_day", GameState.day))
	title.add_theme_font_size_override("font_size", 29 if _is_mobile_layout() else 36)
	layout.add_child(title)

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.text = "[color=#d7e0e3]今天最后一个行动：[/color]%s\n[color=#d7e0e3]行动变化：[/color]%s\n[color=#d7e0e3]生活费与日终变化：[/color]%s\n\n余额每晚扣除 60；如果余额低于 500，压力会额外上升。" % [
		summary.get("action_name", "行动"),
		_format_changes(summary.get("action_changes", {})),
		_format_changes(summary.get("daily_changes", {}))
	]
	layout.add_child(body)

	var button_text := "查看阶段性报告" if bool(summary.get("demo_finished", false)) else "进入下一天"
	var button := _make_button(button_text)
	button.pressed.connect(func() -> void:
		if bool(summary.get("demo_finished", false)):
			_show_ending_report()
		else:
			notice_text = ""
			_show_next_event_or_room()
	)
	layout.add_child(button)

func _show_ending_report() -> void:
	_clear()
	var report := EndingManager.generate_report()
	var background := _make_background(Color(0.10, 0.12, 0.14))
	add_child(background)
	var margin := _make_margin(_screen_margin())
	background.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var panel := _make_panel(Color(0.20, 0.22, 0.23), Vector2(0, 0))
	scroll.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	panel.add_child(layout)

	var label := Label.new()
	label.text = "阶段性人生报告"
	label.add_theme_color_override("font_color", Color(0.99, 0.84, 0.55))
	layout.add_child(label)

	var title := Label.new()
	title.text = report.get("title", "")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 30 if _is_mobile_layout() else 38)
	layout.add_child(title)

	var keyword := Label.new()
	keyword.text = report.get("keyword", "")
	keyword.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	keyword.add_theme_font_size_override("font_size", 19 if _is_mobile_layout() else 22)
	keyword.add_theme_color_override("font_color", Color(0.83, 0.88, 0.90))
	layout.add_child(keyword)

	layout.add_child(_separator())
	for stat in STAT_ORDER:
		layout.add_child(_make_status_row(STAT_LABELS[stat], int(GameState.get(stat)), stat == "money"))

	var menu_button := _make_button("返回主菜单")
	menu_button.pressed.connect(_show_main_menu)
	layout.add_child(menu_button)

func _save_from_room() -> void:
	notice_text = "已保存到 user://save_001.json" if SaveManager.save_game() else "保存失败。"
	_show_room()

func _load_from_room() -> void:
	if SaveManager.load_game():
		notice_text = "已读取 user://save_001.json"
		if GameState.day > 7:
			_show_ending_report()
		else:
			_show_next_event_or_room()
	else:
		notice_text = "没有找到可读取的存档。"
		_show_room()

func _travel_to_location(location_id: String, location_name: String) -> void:
	LocationManager.travel_to(location_id)
	notice_text = "你来到了：%s" % location_name
	_show_room()

func _format_effects(effects: Dictionary) -> String:
	var parts: Array[String] = []
	for key in effects.keys():
		parts.append("%s %s" % [STAT_LABELS.get(key, key), _signed_int(int(effects[key]))])
	return " / ".join(parts)

func _format_changes(changes: Dictionary) -> String:
	if changes.is_empty():
		return "无"
	return _format_effects(changes)

func _signed_int(value: int) -> String:
	if value > 0:
		return "+%d" % value
	return str(value)

func _is_mobile_layout() -> bool:
	var size := get_viewport_rect().size
	return OS.has_feature("mobile") or size.x <= MOBILE_WIDTH

func _screen_margin() -> int:
	return 12 if _is_mobile_layout() else 72

func _make_status_row(label_text: String, value: int, is_money: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(82 if _is_mobile_layout() else 96, 0)
	label.add_theme_color_override("font_color", Color(0.77, 0.82, 0.84))
	row.add_child(label)
	var value_label := Label.new()
	value_label.text = "%d 元" % value if is_money else str(value)
	value_label.add_theme_font_size_override("font_size", 18)
	row.add_child(value_label)
	return row

func _make_nav_button(text: String, active: bool, callback: Callable) -> Button:
	var button := _make_button(text)
	button.pressed.connect(callback)
	if active:
		button.add_theme_color_override("font_color", Color(0.10, 0.12, 0.14))
		button.add_theme_stylebox_override("normal", _style(Color(0.95, 0.78, 0.38), 6))
	return button

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0 if _is_mobile_layout() else 240, 50 if _is_mobile_layout() else 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if _is_mobile_layout() else Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17 if _is_mobile_layout() else 18)
	button.add_theme_stylebox_override("normal", _style(Color(0.31, 0.34, 0.35), 6))
	button.add_theme_stylebox_override("hover", _style(Color(0.39, 0.43, 0.44), 6))
	button.add_theme_stylebox_override("pressed", _style(Color(0.23, 0.25, 0.26), 6))
	button.add_theme_stylebox_override("disabled", _style(Color(0.20, 0.21, 0.22), 6))
	return button

func _make_panel(color: Color, min_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(color, 8, 14 if _is_mobile_layout() else 20))
	return panel

func _make_margin(value: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_bottom", value)
	return margin

func _make_background(color: Color) -> ColorRect:
	var background := ColorRect.new()
	background.color = color
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	return background

func _separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	return separator

func _spacer(size: Vector2) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = size
	return spacer

func _style(color: Color, radius: int, padding: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
