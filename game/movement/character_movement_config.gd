class_name CharacterMovementConfig
extends Resource


@export_category("Ground Movement")

@export_range(0.0, 30.0, 0.1)
var move_speed: float = 6.0

@export_range(0.0, 100.0, 0.1)
var acceleration: float = 30.0

@export_range(0.0, 100.0, 0.1)
var deceleration: float = 40.0

@export_range(0.0, 30.0, 0.1)
var rotation_speed: float = 12.0


@export_category("Gravity")

@export_range(0.0, 5.0, 0.1)
var gravity_scale: float = 1.0
