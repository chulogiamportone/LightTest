extends Control

@export_range(3, 6) var max_slots := 6
var items: Array[PackedScene] = []
var slots: Array[TextureRect] = []
var selected_index: int = 0

@onready var slots_container: HBoxContainer = $Slots

# Tu textura de fondo para cada slot
const INVENTARIO_SLOT_CINTURON: Texture2D = preload("uid://duuho7agm364t")

func _ready():
	for child in slots_container.get_children():
		slots.append(child)
		child.texture = INVENTARIO_SLOT_CINTURON
	items.resize(max_slots)
	items.fill(null)

func add_item(item_scene: PackedScene) -> bool:
	for i in range(max_slots):
		if items[i] == null:
			items[i] = item_scene
			var insta=await  item_scene.instantiate()
			insta._set_text("uid://c8cerim73wckc")
			slots[i].texture = insta.get_texture()
			return true
	return false  # inventario lleno

func remove_item(slot_index: int) -> PackedScene:
	if slot_index >= 0 and slot_index < max_slots and items[slot_index] != null:
		var itm := items[slot_index]
		items[slot_index] = null
		var icon: TextureRect = slots[slot_index]
		icon.texture = null
		return itm
	return null

func get_selected_item() -> PackedScene:
	return items[selected_index]

func consume_selected_item() -> PackedScene:
	return remove_item(selected_index)

# Cambiar selección con números y rueda
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: _set_selected(0)
			KEY_2: _set_selected(1)
			KEY_3: _set_selected(2)
			KEY_4: _set_selected(3)
			KEY_5: _set_selected(4)
			KEY_6: _set_selected(5)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle(1)

func _cycle(dir: int):
	selected_index = (selected_index + dir) % max_slots
	if selected_index < 0:
		selected_index = max_slots - 1
	_refresh_selection_visual()

func _set_selected(i: int):
	if i >= 0 and i < max_slots:
		selected_index = i
		_refresh_selection_visual()

func _refresh_selection_visual():
	# Resalta el slot activo. Fondo (slot) queda igual;
	# resaltamos el contenedor con self_modulate u opcionalmente agregá un Panel/borde.
	for i in range(slots.size()):
		if i == selected_index:
			slots[i].self_modulate = Color(1.2, 1.2, 1.2, 1) # brillo
		else:
			slots[i].self_modulate = Color(1, 1, 1, 1)
