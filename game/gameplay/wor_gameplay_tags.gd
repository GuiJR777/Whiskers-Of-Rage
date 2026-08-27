class_name WORGameplayTags
extends RefCounted


# ============================================================================
# Locomotion
# ============================================================================

const STATE_GROUNDED: StringName = &"State.Grounded"
const STATE_IDLE: StringName = &"State.Idle"
const STATE_MOVING: StringName = &"State.Moving"

const STATE_AIRBORNE: StringName = &"State.Airborne"
const STATE_JUMPING: StringName = &"State.Jumping"
const STATE_FALLING: StringName = &"State.Falling"


# ============================================================================
# Combat States
# ============================================================================

const STATE_ATTACKING: StringName = &"State.Attacking"


# ============================================================================
# Abilities
# ============================================================================

const ABILITY_ATTACK_LIGHT_01: StringName = (
	&"Ability.Attack.Light.01"
)


# ============================================================================
# Gameplay Events
# ============================================================================

const EVENT_ANIMATION_ABILITY_FINISHED: StringName = (
	&"Event.Animation.AbilityFinished"
)
