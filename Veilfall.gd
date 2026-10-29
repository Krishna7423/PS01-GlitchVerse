extends Node2D

const SPEED = 280.0
const JUMP_FORCE = -430.0
const GRAVITY = 1000.0

var player: CharacterBody2D
var world: Node2D
var hud: Label
var level = 0
var health = 3
var game_over = true
var invincible = false
var attack_cooldown = 0.0
var enemies: Array[CharacterBody2D] = []

var level_names = [
    "1 - FORGOTTEN GATE",
    "2 - SUNKEN RUINS",
    "3 - VEIL BRIDGE",
    "4 - THE LAST GUARDIAN"
]

func _ready():
    start_game()

func clear_all():
    for child in get_children():
        child.call_deferred("free")

    player = null
    enemies.clear()
    hud = null
    world = null

func add_label(text_value, pos, font_size, color):
    var label = Label.new()
    label.text = text_value
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    add_child(label)
    return label

func show_title():
    clear_all()
    game_over = true

    var bg = ColorRect.new()
    bg.color = Color("#11101c")
    bg.size = Vector2(1152, 648)
    add_child(bg)

    add_label("VEILFALL", Vector2(380, 150), 64, Color("#d8c4ff"))
    add_label("FOUR REALMS. ONE LAST CHANCE.", Vector2(370, 235), 22, Color.WHITE)

    var button = Button.new()
    button.text = "ENTER THE VEIL"
    button.position = Vector2(460, 320)
    button.size = Vector2(220, 60)
    add_child(button)
    button.pressed.connect(start_game)

    add_label("MOVE: A/D OR ARROWS   JUMP: SPACE   ATTACK: J",
        Vector2(300, 430), 18, Color("#bcb5d0"))

func start_game():
    level = 0
    health = 3
    build_level()

func build_level():
    clear_all()
    game_over = false
    invincible = false
    attack_cooldown = 0.0

    world = Node2D.new()
    add_child(world)
  
    var bg = ColorRect.new()
    bg.color = [
        Color("#100b20"),
        Color("#101a29"),
        Color("#291326"),
        Color("#180b24")
    ][level]
    bg.size = Vector2(1152, 648)
    world.add_child(bg)
    add_background_art()
    hud = Label.new()
    hud.position = Vector2(24, 18)
    hud.add_theme_font_size_override("font_size", 22)
    hud.add_theme_color_override("font_color", Color.WHITE)
    world.add_child(hud)

    make_platform(Vector2(576, 620), Vector2(1152, 56))
    make_platform(Vector2(220, 490), Vector2(180, 22))
    make_platform(Vector2(480, 400), Vector2(180, 22))
    make_platform(Vector2(750, 490), Vector2(180, 22))

    if level >= 1:
        make_hazard(Vector2(350, 585))
        make_hazard(Vector2(600, 585))

    if level >= 2:
        make_platform(Vector2(930, 360), Vector2(150, 22))
        make_hazard(Vector2(510, 585))
        make_hazard(Vector2(820, 585))

    if level >= 3:
        make_hazard(Vector2(700, 585))

    if level == 3:
        make_enemy(Vector2(800, 560), true)
    else:
        make_enemy(Vector2(600, 570), false)

    make_player(Vector2(70, 560))
    make_exit(Vector2(1090, 540))
    update_hud()


func make_platform(pos, size):
    var body = StaticBody2D.new()
    body.position = pos
    world.add_child(body)

    var shape = CollisionShape2D.new()
    var rect = RectangleShape2D.new()
    rect.size = size
    shape.shape = rect
    body.add_child(shape)

    var visual = ColorRect.new()
    visual.color = Color("#655777")
    visual.size = size
    visual.position = -size / 2
    body.add_child(visual)

func make_player(pos):
    player = CharacterBody2D.new()
    player.position = pos
    world.add_child(player)

    var shape = CollisionShape2D.new()
    var rect = RectangleShape2D.new()
    rect.size = Vector2(28, 40)
    shape.shape = rect
    player.add_child(shape)

    var visual = ColorRect.new()
    visual.color = Color("#e5d7ff")
    visual.size = Vector2(28, 40)
    visual.position = Vector2(-14, -20)
    player.add_child(visual)

func make_hazard(pos):
    var area = Area2D.new()
    area.position = pos
    world.add_child(area)

    var shape = CollisionShape2D.new()
    var rect = RectangleShape2D.new()
    rect.size = Vector2(54, 24)
    shape.shape = rect
    area.add_child(shape)

    var visual = ColorRect.new()
    visual.color = Color("#ff4567")
    visual.size = Vector2(54, 24)
    visual.position = Vector2(-27, -12)
    area.add_child(visual)

    area.body_entered.connect(hit_hazard)

func make_enemy(pos, boss):
    var enemy = CharacterBody2D.new()
    enemy.position = pos
    enemy.set_meta("boss", boss)
    enemy.set_meta("origin", pos.x)
    enemy.set_meta("direction", -1.0)
    world.add_child(enemy)

    var size = Vector2(46, 48) if boss else Vector2(30, 34)

    var shape = CollisionShape2D.new()
    var rect = RectangleShape2D.new()
    rect.size = size
    shape.shape = rect
    enemy.add_child(shape)

    var visual = ColorRect.new()
    visual.color = Color("#ff405b") if boss else Color("#b46b83")
    visual.size = size
    visual.position = -size / 2
    enemy.add_child(visual)

    enemies.append(enemy)

func make_exit(pos):
    var area = Area2D.new()
    area.position = pos
    world.add_child(area)

    var shape = CollisionShape2D.new()
    var rect = RectangleShape2D.new()
    rect.size = Vector2(36, 100)
    shape.shape = rect
    area.add_child(shape)

    var visual = ColorRect.new()
    visual.color = Color("#d8c4ff")
    visual.size = Vector2(12, 80)
    visual.position = Vector2(-6, -40)
    area.add_child(visual)

    area.body_entered.connect(reach_exit)

func _physics_process(delta):
    if game_over or player == null:
        return

    if not player.is_on_floor():
        player.velocity.y += GRAVITY * delta

    var direction = Input.get_axis("ui_left", "ui_right")
    player.velocity.x = direction * SPEED

    if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
        player.velocity.y = JUMP_FORCE

    player.move_and_slide()

    if player.position.y > 700:
        lose_health()

    attack_cooldown -= delta

    for enemy in enemies.duplicate():
        if not is_instance_valid(enemy):
            enemies.erase(enemy)
            continue

        var origin = enemy.get_meta("origin")
        var dir = enemy.get_meta("direction")
        var boss = enemy.get_meta("boss")
        var range_limit = 110.0 if boss else 80.0
        var enemy_speed = 75.0 if boss else 45.0

        enemy.position.x += dir * enemy_speed * delta

        if abs(enemy.position.x - origin) > range_limit:
            enemy.set_meta("direction", -dir)

        if player.global_position.distance_to(enemy.global_position) < 35:
            lose_health()

        if Input.is_key_pressed(KEY_J) and attack_cooldown <= 0:
            if player.global_position.distance_to(enemy.global_position) < 100:
                enemy.queue_free()
                enemies.erase(enemy)
                attack_cooldown = 0.4

    update_hud()

func hit_hazard(body):
    if body == player:
        lose_health()

func lose_health():
    if invincible or game_over:
        return

    health -= 1

    if health <= 0:
        show_game_over()
    else:
        invincible = true
        player.position = Vector2(70, 560)
        player.velocity = Vector2.ZERO
        await get_tree().create_timer(1.0).timeout
        invincible = false

    update_hud()


func show_game_over():
    clear_all()
    game_over = true

    var bg = ColorRect.new()
    bg.color = Color("#11010c")
    bg.size = Vector2(1152, 648)
    add_child(bg)

    add_label("YOU FELL", Vector2(400, 170), 64, Color("#d85c7f"))
    add_label("THE VEIL CLAIMS ANOTHER SOUL", Vector2(300, 270), 26, Color.WHITE)
    add_label("PRESS R TO RETRY", Vector2(420, 390), 28, Color.WHITE)

func reach_exit(body):
    if body != player or game_over:
        return

    if level < 3:
        level += 1
        build_level()
    else:
        show_victory()

func update_hud():
    if is_instance_valid(hud):
        hud.text = level_names[level] + "     HEALTH: " + str(health) + "     J: ATTACK"

func show_victory():
    clear_all()
    game_over = true

    var bg = ColorRect.new()
    bg.color = Color("#11101c")
    bg.size = Vector2(1152, 648)
    add_child(bg)

    add_label("VEILFALL", Vector2(380, 150), 64, Color("#d8c4ff"))
    add_label("THE VEIL IS BROKEN", Vector2(390, 260), 32, Color.WHITE)
    add_label("YOU SURVIVED ALL FOUR REALMS", Vector2(350, 330), 24, Color("#bcb5d0"))

    var button = Button.new()
    button.text = "PLAY AGAIN"
    button.position = Vector2(460, 410)
    button.size = Vector2(220, 55)
    add_child(button)
    button.pressed.connect(start_game)

func _unhandled_key_input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R and game_over:
            start_game()
func add_background_art():
    var far_mountains = Polygon2D.new()
    far_mountains.polygon = PackedVector2Array([
        Vector2(0, 440),
        Vector2(120, 340),
        Vector2(230, 410),
        Vector2(370, 290),
        Vector2(510, 420),
        Vector2(680, 320),
        Vector2(820, 400),
        Vector2(970, 300),
        Vector2(1152, 430),
        Vector2(1152, 648),
        Vector2(0, 648)
    ])
    far_mountains.color = Color("#29213f")
    world.add_child(far_mountains)

    var near_mountains = Polygon2D.new()
    near_mountains.polygon = PackedVector2Array([
        Vector2(0, 520),
        Vector2(160, 430),
        Vector2(300, 500),
        Vector2(460, 390),
        Vector2(620, 510),
        Vector2(800, 430),
        Vector2(980, 510),
        Vector2(1152, 420),
        Vector2(1152, 648),
        Vector2(0, 648)
    ])
    near_mountains.color = Color("#191426")
    world.add_child(near_mountains)
    for i in range(9):
        var crystal = Polygon2D.new()
        var x = 70 + i * 125
        var y = 300 + (i % 3) * 65

        crystal.polygon = PackedVector2Array([
            Vector2(0, -12),
            Vector2(7, 0),
            Vector2(0, 15),
            Vector2(-7, 0)
        ])

        crystal.position = Vector2(x, y)
        crystal.color = Color("#a855f7")
        world.add_child(crystal)
