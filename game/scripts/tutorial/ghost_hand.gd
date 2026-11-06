class_name GhostHand
extends Control
## The ghost of a thumb or a whole hand that shows a gesture (ONBOARDING §2.2, D-77). It is a
## matte paper cut-out: a flat bone fill (90%) with a 2 dp ink edge, drawn in the real thumb zone
## so the pad sits where the finger goes. No blur halo, no glow, no colour accent, no particles,
## no text. The light fill reads on the dark leather of the roll (the D-76 shadow could not pass
## 1.3:1 there); the ink edge separates it from the light lock body and the cream dial. Both
## channels are pure lightness, so it holds in grayscale. mouse_filter is IGNORE so it never
## swallows the player's touches.
##
## dp == canvas units in this project: dp_scale.gd keeps the 412x915 base with stretch
## canvas_items, so 1 unit is 1 dp in both orientations, and from_dp/to_dp are plain
## coordinates of the parent control.
##
## With the system "Reduce Motion" on the scene shows only the start and end pose
## (ONBOARDING §11): it simply never calls play_gesture.
##
## G23 silhouettes (res://assets/ui/ghost/, ghost_silhouettes.json): set_silhouette(name)
## swaps the oval for the alpha shape of a thumb / hand cut from the G23 photos (white +
## alpha, edge pre-blurred 12 dp, see art/tools/ghost_silhouettes.py). The shader cuts that
## alpha at 0.5 (the photo's contour) and dilates it by EDGE_DP for the ink edge. Its hotspot
## (the thumb pad) sits on the gesture position. A missing file keeps the oval.
## set_release_silhouette(name) shows that shape while the ghost withdraws and fades
## (H4: the tool hand lets go as an open hand).

## Eased 0..1 travel of the current repeat (0 while fading in at the start pose,
## 1 during the hold); the scene can answer it, e.g. rotate the tension wrench.
signal gesture_progress(t: float)
## All repeats are done and the ghost has faded out.
signal gesture_finished

const FADE_S := 0.150
## Fade in at the start pose / fade out at the end (§2.2: fade 150 ms).
## D-77: paper cut-out instead of a cast shadow. Bone (darker than the H3 chalk 0.96/0.95/0.90, so
## the hand never reads as a chalk mark) and near-black ink; lightness L* ~84 vs ~7.
const FILL_COLOR := Color(0.85, 0.81, 0.73)
const FILL_OPACITY := 0.90
const EDGE_COLOR := Color(0.09, 0.075, 0.065)
const EDGE_OPACITY := 1.0
const EDGE_DP := 2.0
## Ink edge width, outside the contour (DESIGN: dividing lines >= 2 dp).
const SOFT_DP := 12.0
## Margin around the fallback oval (the G23 photos carry their own 12 dp pre-blurred alpha).
const THUMB_DP := Vector2(22.0, 56.0)
## Fallback silhouette: a rounded oval ~22x56 dp (no texture set).
const RELEASE_S := 0.250
## Release (open hand) withdraw + fade (animations 100–250 ms).
const RELEASE_DP := 24.0
## How far the open hand withdraws towards the gesture's start.
const SILHOUETTE_DIR := "res://assets/ui/ghost/"
const SILHOUETTE_META := "res://assets/ui/ghost/ghost_silhouettes.json"

## Alpha silhouette of a thumb/hand (its own soft edge); null draws the fallback
## thumb oval.
var texture: Texture2D = null:
	set(value):
		texture = value
		# A texture is an alpha silhouette: the cut-out shader turns it into fill + ink edge.
		# Without one, _draw_oval draws the fallback thumb with the same two colours.
		material = _cutout_mat if value != null else null
		_update_edge_px()
		_update_shadow_size()

## Point of the texture (0..1) that sits on the gesture position (the thumb pad).
var texture_anchor := Vector2(0.5, 0.5):
	set(value):
		texture_anchor = value
		queue_redraw()

## Mirror the silhouette itself (a right-hand photo used for the left side).
var texture_flip := false:
	set(value):
		texture_flip = value
		queue_redraw()

## Name of the current G23 silhouette (&"" = none, the oval).
var silhouette := &""
## Name of the release silhouette (&"" = none: the gesture shape just fades).
var release_silhouette := &""

## Canvas units per texture pixel (textures are authored in px, the scene is in dp).
var texture_scale := 1.0:
	set(value):
		texture_scale = maxf(value, 0.01)
		_update_edge_px()
		_update_shadow_size()

## Left-handed "swap thumbs" option (HUD §9): the ghost is mirrored across the
## parent control's centre, so it plays in the other thumb zone.
var mirror := false:
	set(value):
		mirror = value
		_apply_layout()

## Current centre of the ghost, in parent coordinates (already mirrored).
var ghost_center := Vector2.ZERO

enum _Phase { IDLE, FADE_IN, MOVE, HOLD, FADE_OUT, RELEASE }

## Paper cut-out of a G23 alpha silhouette: fill inside the 0.5 contour, ink in a ring EDGE_DP
## outside it (12 taps on the ring + 12 at half radius, so thin parts never lose their edge).
const _CUTOUT_SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform vec4 fill_color : source_color = vec4(0.85, 0.81, 0.73, 0.9);
uniform vec4 edge_color : source_color = vec4(0.09, 0.075, 0.065, 1.0);
uniform float edge_px = 4.0;  // EDGE_DP in texture pixels
varying vec4 tint;
void vertex() {
	tint = COLOR;  // draw modulate: carries the fade
}
void fragment() {
	float a0 = texture(TEXTURE, UV).a;
	float w = clamp(fwidth(a0), 0.002, 0.25);
	float fill = smoothstep(0.5 - w, 0.5 + w, a0);
	float outer = fill;
	for (int i = 0; i < 12; i++) {
		float ang = 6.2831853 * float(i) / 12.0;
		vec2 d = vec2(cos(ang), sin(ang)) * TEXTURE_PIXEL_SIZE * edge_px;
		outer = max(outer, smoothstep(0.5 - w, 0.5 + w, texture(TEXTURE, UV + d).a));
		outer = max(outer, smoothstep(0.5 - w, 0.5 + w, texture(TEXTURE, UV + d * 0.5).a));
	}
	vec4 c = mix(edge_color, fill_color, fill);
	COLOR = vec4(c.rgb, c.a * outer * tint.a);
}
"""

var _phase := _Phase.IDLE
var _t := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _duration := 0.0
var _repeats := 1
var _hold_s := 0.0
var _repeat := 0
var _alpha := 0.0
var _shadow_size := Vector2.ZERO
var _cutout_mat: ShaderMaterial
var _release := {}  # {texture, anchor, scale, flip} while the release shape shows
var _gesture_shape := {}  # the gesture shape, restored after a release

static var _meta_cache := {}


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE  # never intercept the player's touches
	set_process(false)  # REVIEW-V02: idle ghost must not redraw every frame (play_gesture turns it on)
	var shader := Shader.new()
	shader.code = _CUTOUT_SHADER
	_cutout_mat = ShaderMaterial.new()
	_cutout_mat.shader = shader
	_cutout_mat.set_shader_parameter(&"fill_color", Color(FILL_COLOR, FILL_OPACITY))
	_cutout_mat.set_shader_parameter(&"edge_color", Color(EDGE_COLOR, EDGE_OPACITY))
	_update_shadow_size()


## Show the ghost at from_dp, fade in (150 ms), travel from_dp -> to_dp over
## duration_s with ease-in-out (speeds up, then slows down: the tempo is part of the
## lesson, §2.2), hold at to_dp for hold_s ("place and hold" uses 1.5 s), repeat
## `repeats` times, then fade out and emit gesture_finished. During the travel
## gesture_progress(t) reports the eased 0..1 position so the scene can answer.
## Between repeats the ghost jumps back to the start pose.
func play_gesture(from_dp: Vector2, to_dp: Vector2, duration_s: float,
		repeats := 2, hold_s := 0.0) -> void:
	_restore_gesture_shape()  # a new gesture during a release starts in its own shape
	_from = from_dp
	_to = to_dp
	_duration = maxf(duration_s, 0.0)
	_repeats = maxi(repeats, 1)
	_hold_s = maxf(hold_s, 0.0)
	_repeat = 0
	_t = 0.0
	_alpha = 0.0
	_phase = _Phase.FADE_IN
	ghost_center = _screen_pos(_from)
	set_process(true)
	_apply_layout()


## Silhouette data: {texture, anchor, scale} or {} when the file / entry is missing.
static func load_silhouette(name: StringName) -> Dictionary:
	if name == &"":
		return {}
	if _meta_cache.is_empty():
		if not FileAccess.file_exists(SILHOUETTE_META):
			return {}
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(SILHOUETTE_META))
		if typeof(j) != TYPE_DICTIONARY:
			return {}
		_meta_cache = j
	var e: Dictionary = _meta_cache.get("textures", {}).get(String(name), {})
	var path := SILHOUETTE_DIR + String(name) + ".png"
	if e.is_empty() or not ResourceLoader.exists(path):
		return {}
	var tex := load(path) as Texture2D
	if tex == null:
		return {}
	var hs: Array = e.get("hotspot", [0.5, 0.5])
	# the texture may be imported at another size than authored: keep its size in dp
	var dp_w := float(e.get("size_px", [tex.get_width()])[0]) / float(e.get("px_per_dp", 1.0))
	return {"texture": tex, "anchor": Vector2(float(hs[0]), float(hs[1])), "scale": dp_w / float(tex.get_width())}


## Use the G23 silhouette `name` (flip_h mirrors the photo, e.g. a right hand on the
## left side). Returns false and falls back to the oval when it cannot be loaded.
func set_silhouette(name: StringName, flip_h := false) -> bool:
	var d := load_silhouette(name)
	silhouette = name if not d.is_empty() else &""
	texture_flip = flip_h and not d.is_empty()
	texture_anchor = d.get("anchor", Vector2(0.5, 0.5))
	texture_scale = d.get("scale", 1.0)
	texture = d.get("texture", null)
	_gesture_shape = {}
	return not d.is_empty()


## Shape shown while the ghost lets go at the end (&"" = none). False if missing.
func set_release_silhouette(name: StringName, flip_h := false) -> bool:
	var d := load_silhouette(name)
	release_silhouette = name if not d.is_empty() else &""
	if not d.is_empty():
		d["flip"] = flip_h
	_release = d
	return not d.is_empty()


## Peak opacity of the fill (D-77: the same paper cut-out for the oval and every silhouette).
func fill_opacity() -> float:
	return FILL_OPACITY


func is_playing() -> bool:
	return _phase != _Phase.IDLE


func _process(delta: float) -> void:
	match _phase:
		_Phase.FADE_IN:
			_t += delta
			_alpha = clampf(_t / FADE_S, 0.0, 1.0)
			if _t >= FADE_S:
				_alpha = 1.0
				_phase = _Phase.MOVE
				_t = 0.0
				ghost_center = _screen_pos(_from)
				gesture_progress.emit(0.0)
		_Phase.MOVE:
			_t += delta
			var u := 1.0 if _duration <= 0.0 else clampf(_t / _duration, 0.0, 1.0)
			var eased := _ease_in_out(u)
			ghost_center = _screen_pos(_from.lerp(_to, eased))
			gesture_progress.emit(eased)
			if u >= 1.0:
				ghost_center = _screen_pos(_to)
				if _hold_s > 0.0:
					_phase = _Phase.HOLD
					_t = 0.0
				else:
					_next_repeat()
		_Phase.HOLD:
			_t += delta
			ghost_center = _screen_pos(_to)
			gesture_progress.emit(1.0)
			if _t >= _hold_s:
				_next_repeat()
		_Phase.RELEASE:
			# the hand opens and withdraws a little towards the start, fading out
			_t += delta
			var u := clampf(_t / RELEASE_S, 0.0, 1.0)
			var back := (_from - _to).normalized() if _from != _to else Vector2(0.0, 1.0)
			ghost_center = _screen_pos(_to + back * RELEASE_DP * u)
			_alpha = 1.0 - u
			if _t >= RELEASE_S:
				_phase = _Phase.IDLE
				_alpha = 0.0
				set_process(false)
				_restore_gesture_shape()
				gesture_finished.emit()
		_Phase.FADE_OUT:
			_t += delta
			_alpha = clampf(1.0 - _t / FADE_S, 0.0, 1.0)
			if _t >= FADE_S:
				_phase = _Phase.IDLE
				_alpha = 0.0
				set_process(false)
				gesture_finished.emit()
	_apply_layout()


func _next_repeat() -> void:
	_repeat += 1
	if _repeat >= _repeats:
		_phase = _Phase.RELEASE if not _release.is_empty() else _Phase.FADE_OUT
		_t = 0.0
		if _phase == _Phase.RELEASE:
			_swap_to_release()
	else:
		_phase = _Phase.MOVE
		_t = 0.0
		ghost_center = _screen_pos(_from)
		gesture_progress.emit(0.0)


func _swap_to_release() -> void:
	_gesture_shape = {"texture": texture, "anchor": texture_anchor, "scale": texture_scale, "flip": texture_flip}
	texture_anchor = _release["anchor"]
	texture_scale = _release["scale"]
	texture_flip = _release["flip"]
	texture = _release["texture"]


func _restore_gesture_shape() -> void:
	if _gesture_shape.is_empty():
		return
	var g := _gesture_shape
	texture_anchor = g["anchor"]
	texture_scale = g["scale"]
	texture_flip = g["flip"]
	texture = g["texture"]
	_gesture_shape = {}


## Cubic ease-in-out: the ghost accelerates, then slows down.
static func _ease_in_out(u: float) -> float:
	if u <= 0.0:
		return 0.0
	if u >= 1.0:
		return 1.0
	if u < 0.5:
		return 4.0 * u * u * u
	return 1.0 - pow(-2.0 * u + 2.0, 3.0) * 0.5


## Mirror for left-handed players flips the x axis across the parent's centre.
func _screen_pos(p: Vector2) -> Vector2:
	if not mirror:
		return p
	return Vector2(_mirror_width() - p.x, p.y)


func _mirror_width() -> float:
	var parent := get_parent_control()
	if parent != null:
		return parent.size.x
	var vp := get_viewport()
	if vp != null:
		return vp.get_visible_rect().size.x
	return 0.0


## The control rect: silhouette + half the soft margin on each side (the ink edge fits in it).
func _update_shadow_size() -> void:
	var margin := Vector2(SOFT_DP, SOFT_DP) * 0.5
	if texture != null:
		_shadow_size = texture.get_size() * texture_scale + margin * 2.0
	else:
		_shadow_size = THUMB_DP + margin * 2.0
	size = _shadow_size
	_apply_layout()


## EDGE_DP in texture pixels (textures are authored at px_per_dp, the scene is in dp).
func _update_edge_px() -> void:
	if _cutout_mat != null:
		_cutout_mat.set_shader_parameter(&"edge_px", EDGE_DP / texture_scale)


func _apply_layout() -> void:
	position = ghost_center - _shadow_size * 0.5
	queue_redraw()


func _draw() -> void:
	if _phase == _Phase.IDLE or _shadow_size == Vector2.ZERO:
		return
	# the modulate only carries the fade; colours come from FILL_* / EDGE_*
	var fade := Color(1.0, 1.0, 1.0, _alpha)
	# Draw in ghost-centred coordinates so `mirror` can flip the silhouette.
	# The texture's hotspot sits on the ghost centre; flipping keeps it there.
	var flip := mirror != (texture_flip and texture != null)
	draw_set_transform(_shadow_size * 0.5, 0.0,
		Vector2(-1.0, 1.0) if flip else Vector2.ONE)
	if texture != null:
		var ts: Vector2 = texture.get_size() * texture_scale
		draw_texture_rect(texture, Rect2(-ts * texture_anchor, ts), false, fade)
	else:
		_draw_oval()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Fallback thumb (no texture): a bone oval THUMB_DP with the EDGE_DP ink ring outside it.
func _draw_oval() -> void:
	var r := THUMB_DP * 0.5
	var fill := PackedVector2Array()
	var ring := PackedVector2Array()
	for k in 33:
		var a := TAU * k / 32.0
		var u := Vector2(cos(a), sin(a))
		if k < 32:
			fill.append(u * r)
		ring.append(u * (r + Vector2.ONE * EDGE_DP * 0.5))
	draw_colored_polygon(fill, Color(FILL_COLOR, FILL_OPACITY * _alpha))
	draw_polyline(ring, Color(EDGE_COLOR, EDGE_OPACITY * _alpha), EDGE_DP, true)
