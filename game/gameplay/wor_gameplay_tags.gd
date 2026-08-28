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

const STATE_KNOCKED_DOWN: StringName = (
	&"State.KnockedDown"
)


# ============================================================================
# Abilities
# ============================================================================

const ABILITY_ATTACK_LIGHT_01: StringName = (
	&"Ability.Attack.Light.01"
)

const ABILITY_ATTACK_LIGHT_02: StringName = (
	&"Ability.Attack.Light.02"
)

const ABILITY_ATTACK_LIGHT_03: StringName = (
	&"Ability.Attack.Light.03"
)


# ============================================================================
# Gameplay Events - Animation
# ============================================================================

const EVENT_ANIMATION_ABILITY_FINISHED: StringName = (
	&"Event.Animation.AbilityFinished"
)


# ============================================================================
# Gameplay Events - Combat
# ============================================================================

const EVENT_COMBAT_HIT_CONFIRMED: StringName = (
	&"Event.Combat.Hit.Confirmed"
)

const EVENT_COMBAT_COMBO_WINDOW_OPEN: StringName = (
	&"Event.Combat.ComboWindow.Open"
)

const EVENT_COMBAT_COMBO_WINDOW_CLOSE: StringName = (
	&"Event.Combat.ComboWindow.Close"
)

const EVENT_COMBAT_HIT_RECEIVED: StringName = (
	&"Event.Combat.Hit.Received"
)
