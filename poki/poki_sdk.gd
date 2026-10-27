# This autoload forwards game events after the Poki HTML shell initializes its JavaScript SDK.

extends Node

const SDK_NAME := "PokiSDK"

signal commercial_break_done(response: Variant)
signal commercial_break_failed(error: Variant)
signal rewarded_break_done(reward_granted: bool)
signal rewarded_break_failed(error: Variant)

var _sdk = null
var _retained_callbacks = [] #keeps callbacks alive, so that they are not garbage collected

var is_gameplay_started := false

func _ready():
	fetch_sdk()


func fetch_sdk():
	if !OS.has_feature("web"): return

	_sdk = JavaScriptBridge.get_interface(SDK_NAME)


func is_available() -> bool:
	return _sdk != null


func gameplay_start():
	if !is_available(): return
	if is_gameplay_started: return

	_sdk.gameplayStart()
	is_gameplay_started = true


func gameplay_stop():
	if !is_available(): return
	if !is_gameplay_started: return

	_sdk.gameplayStop()
	is_gameplay_started = false


func measure(category: String, what: String, action: String):
	if !is_available(): return

	_sdk.measure(category, what, action)


func get_url_param(key: String) -> Variant:
	if !is_available(): return null
	return _sdk.getURLParam(key)


func is_ad_blocked() -> bool:
	if !is_available(): return false

	return bool(_sdk.isAdBlocked())


func commercial_break(on_start: Callable = Callable()):
	if !is_available():
		commercial_break_done.emit(null)
		return

	gameplay_stop()

	var resolve = _javascript_callback(func(_args: Array): commercial_break_done.emit(null))

	var reject = _javascript_callback(func(args: Array):
		var error_msg = "Unknown Poki error"
		if not args.is_empty():
			error_msg = args[0]
		commercial_break_failed.emit(error_msg))

	var promise = get_comercial_break_promise(on_start)

	promise.then(resolve, reject)


func get_comercial_break_promise(on_start: Callable = Callable()):
	if !is_available(): return null

	if !on_start.is_valid(): return _sdk.commercialBreak()

	var start = _javascript_callback(func(_args: Array): on_start.call())
	return _sdk.commercialBreak(start)


func rewarded_break(on_start_or_params = null):
	if !is_available():
		rewarded_break_done.emit(false)
		return

	gameplay_stop()

	var resolve = _javascript_callback(func(args: Array):
		var reward_granted = false
		if not args.is_empty():
			reward_granted = bool(args[0])
		rewarded_break_done.emit(reward_granted))

	var reject = _javascript_callback(func(args: Array):
		var error_msg = "Unknown Poki error whilst rewarded break"
		if not args.is_empty():
			error_msg = args[0]
		rewarded_break_failed.emit(error_msg))

	var promise = get_rewarded_break_promise(on_start_or_params)

	promise.then(resolve, reject)


func get_rewarded_break_promise(on_start_or_params = null):
	if !is_available(): return null

	if on_start_or_params is Callable and on_start_or_params.is_valid():
		var start = _javascript_callback(func(_args: Array): on_start_or_params.call())
		return _sdk.rewardedBreak(start)

	if on_start_or_params is Dictionary:
		var params: Dictionary = on_start_or_params.duplicate()
		var on_start_callback = params.get("onStart")
		if on_start_callback is Callable and on_start_callback.is_valid():
			params["onStart"] = _javascript_callback(func(_args: Array): on_start_callback.call())
		return _sdk.rewardedBreak(params)

	return _sdk.rewardedBreak()


func _javascript_callback(callback: Callable):
	var javascript_callback = JavaScriptBridge.create_callback(callback)
	_retained_callbacks.append(javascript_callback)
	return javascript_callback
