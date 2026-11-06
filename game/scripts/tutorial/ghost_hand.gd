class_name GhostHand
extends Control
## Shadow of a thumb or a whole hand cast on the scene by the workshop lamp
## (ONBOARDING §2.2). It is a shadow, not a glow: black, 35% opacity, soft ~12 dp
## edge, no outline, no colour, no particles, no text. mouse_filter is IGNORE so it
## never swallows the player's touches.
##
## dp == canvas units in this project: dp_scale.gd keeps the 412x915 base with stretch
## canvas_items, so 1 unit is 1 dp in both orientations, and from_dp/to_dp are plain
## coordinates of the parent control.
##
## With the system "Reduce Motion" on the scene shows only the start and end pose
## (ONBOARDING §11): it simply never calls play_gesture.

## Eased 0..1 travel of the current repeat (0 while fading in at the start pose,
## 1 during the hold); the scene can answer it, e.g. rotate the tension wrench.
signal gesture_progress(t: float)
## All repeats are done and the shadow has faded out.
signal gesture_finished

const FADE_S := 0.150
## Fade in at the start pose / fade out at the end (§2.2: fade 150 ms).
const SHADOW_OPACITY := 0.35
const SOFT_DP := 12.0
## Soft edge width (§2.2); the shader fades the silhouette over half of it in, half out.
const THUMB_DP := Vector2(22.0, 56.0)
## Fallback silhouette: a rounded oval ~22x56 dp (no texture set).

## Alpha silhouette of a thumb/hand (its own soft edge); null draws the fallback
## thumb oval.
var texture: Texture2D = null:
	set(value):
		texture = value
		# A texture is an alpha silhouette with its own soft edge: draw it directly
		# (tinted black). Without one, the built-in oval shader draws the thumb.
		material = null if value != null else _oval_mat
		_update_shadow_size()

## Canvas units per texture pixel (textures are authored in px, the scene is in dp).
var texture_scale := 1.0:
	set(value):
		texture_scale = maxf(value, 0.01)
		_update_shadow_size()

## Left-handed "swap thumbs" option (HUD §9): the ghost is mirrored across the
## parent control's centre, so it plays in the other thumb zone.
var mirror := false:
	set(value):
		mirror = value
		_apply_layout()

## Current centre of the shadow, in parent coordinates (already mirrored).
var ghost_center := Vector2.ZERO

enum _Phase { IDLE, FADE_IN, MOVE, HOLD, FADE_OUT }

const _OVAL_SHADER := """
shader_type canvas_item;
render_mode unshaded;
// Soft-edged shadow oval. UV spans the drawn rect, rect_dp is its size in dp,
// so the mask is resolution independent (1 unit = 1 dp).
uniform vec2 radii_dp = vec2(11.0, 28.0);
uniform vec2 rect_dp = vec2(34.0, 68.0);
uniform float soft_dp = 12.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) * rect_dp;
	float d = (length(p / radii_dp) - 1.0) * min(radii_dp.x, radii_dp.y);
	float mask = 1.0 - smoothstep(-soft_dp * 0.5, soft_dp * 0.5, d);
	COLOR = vec4(0.0, 0.0, 0.0, mask * COLOR.a);
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
var _oval_mat: ShaderMaterial


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE  # never intercept the player's touches
	set_process(false)  # REVIEW-V02: idle ghost must not redraw every frame (play_gesture turns it on)
	var shader := Shader.new()
	shader.code = _OVAL_SHADER
	_oval_mat = ShaderMaterial.new()
	_oval_mat.shader = shader
	material = _oval_mat
	_update_shadow_size()


## Show the shadow at from_dp, fade in (150 ms), travel from_dp -> to_dp over
## duration_s with ease-in-out (speeds up, then slows down: the tempo is part of the
## lesson, §2.2), hold at to_dp for hold_s ("place and hold" uses 1.5 s), repeat
## `repeats` times, then fade out and emit gesture_finished. During the travel
## gesture_progress(t) reports the eased 0..1 position so the scene can answer.
## Between repeats the shadow jumps back to the start pose.
func play_gesture(from_dp: Vector2, to_dp: Vector2, duration_s: float,
		repeats := 2, hold_s := 0.0) -> void:
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
		_phase = _Phase.FADE_OUT
		_t = 0.0
	else:
		_phase = _Phase.MOVE
		_t = 0.0
		ghost_center = _screen_pos(_from)
		gesture_progress.emit(0.0)


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


## The control rect is the shadow rect: silhouette + half the soft edge on each side.
func _update_shadow_size() -> void:
	var margin := Vector2(SOFT_DP, SOFT_DP) * 0.5
	if texture != null:
		_shadow_size = texture.get_size() * texture_scale + margin * 2.0
	else:
		_shadow_size = THUMB_DP + margin * 2.0
	size = _shadow_size
	_apply_layout()


func _apply_layout() -> void:
	position = ghost_center - _shadow_size * 0.5
	queue_redraw()


func _draw() -> void:
	if _phase == _Phase.IDLE or _shadow_size == Vector2.ZERO:
		return
	var color := Color(0.0, 0.0, 0.0, SHADOW_OPACITY * _alpha)
	# Draw in ghost-centred coordinates so `mirror` can flip the silhouette.
	draw_set_transform(_shadow_size * 0.5, 0.0,
		Vector2(-1.0, 1.0) if mirror else Vector2.ONE)
	if texture != null:
		var ts: Vector2 = texture.get_size() * texture_scale
		draw_texture_rect(texture, Rect2(-ts * 0.5, ts), false, color)
	else:
		_oval_mat.set_shader_parameter("radii_dp", THUMB_DP * 0.5)
		_oval_mat.set_shader_parameter("rect_dp", _shadow_size)
		_oval_mat.set_shader_parameter("soft_dp", SOFT_DP)
		draw_rect(Rect2(-_shadow_size * 0.5, _shadow_size), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
