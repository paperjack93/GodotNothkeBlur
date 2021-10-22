extends MeshInstance
export(bool) var debug : bool = false;
export(int) var copies_per_unit_distance : int = 3;
export(int) var min_copies : int = 5;
export(float) var max_distance : float = 5;
export(float) var position_multiplier : float = 5;
export(float) var rotation_multiplier : float = 1;

var _blurpool : Array = [];
var _lastblurs : Array = [];
var _last_transform : Transform;

func _ready():
	_last_transform = global_transform;

func _process(_delta):
	_generate_blur();

func _generate_blur():
	var delta_pos : Vector3 = global_transform.origin - _last_transform.origin;
	var delta_rot : Quat = Quat(global_transform.basis) - Quat(_last_transform.basis);
	
	for blur in _lastblurs: remove_child(blur);
	_lastblurs.clear();
	
	var distance : float =  \
		(delta_pos.length() * position_multiplier) \
		+ (rad2deg(delta_rot.length()) * rotation_multiplier);
	distance = clamp(distance, 0, max_distance);

	var minstep : float = 1.0/float(copies_per_unit_distance);

	if(distance > minstep*min_copies):
		var color : Color = get_active_material(0).albedo_color;
		var steps_count : int = distance/minstep; #Auto flooring from int conversion
		steps_count = max(1, steps_count); #Prevents slow speed flickering
		var step : float = 1.0/float(steps_count);
		_set_alpha(self, color, step);
		
		for i in range(steps_count):
			var blur : MeshInstance = _get_blur(i);
			_lastblurs.append(blur);

						
		for i in range(len(_lastblurs)):
			add_child(_lastblurs[i]);
			var n : float = step * i;
			_set_alpha(_lastblurs[i], color, _ping_pong(n+step, 0.5));
			_set_transform(_lastblurs[i], n);
	else:
		_set_alpha(self, get_active_material(0).albedo_color, 1);
		
	_last_transform = global_transform;

func _get_blur(i):
	if(i < len(_blurpool)): return _blurpool[i];
	else:
		var newblur : MeshInstance = duplicate(0);
		newblur.set_surface_material(0, newblur.get_active_material(0).duplicate());
		newblur.set_as_toplevel(true);
		_blurpool.append(newblur);
		return newblur;

func _set_alpha(blur, color, amount):
	var mat : Material = blur.get_active_material(0);
	if(debug && blur != self):
		mat.albedo_color = Color.red;
	else:
		mat.albedo_color = color;
	mat.albedo_color.a = amount;
	blur.set_surface_material(0, mat);

func _set_transform(blur, amount):
	blur.global_transform.origin = _last_transform.origin.linear_interpolate(global_transform.origin, amount);
	blur.global_transform.basis = _last_transform.basis.slerp(global_transform.basis, amount);

func _ping_pong(a,b):
	if(a > b):
		return a-b;
	else:
		return a;
