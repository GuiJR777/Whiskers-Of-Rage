# Visão Geral da Arquitetura

## Objetivo
Construir WOR sobre sistemas reutilizáveis, data-driven e inspecionáveis no editor, reduzindo lógica de gameplay espalhada por scripts de personagem.

## Camadas
```text
Input / AI Intent
      ↓
Gameplay Ability System
      ↓
Gameplay Tasks / Events / Effects
      ↓
Movement / Animation / Hit Detection / VFX / Audio
```

## Player
```text
RyuCharacter
├── CharacterBody3D
├── AbilitySystemComponent
├── HFSM (locomoção/estado físico)
├── MovementComponent
├── TargetingComponent
├── ComboComponent
├── TechniqueComponent
├── EquipmentComponent
├── JutsuComponent
├── AnimationBridge
├── HitboxManager
└── CueReceiver
```

## Enemy
```text
EnemyCharacter
├── CharacterBody3D
├── AbilitySystemComponent
├── BehaviourTreeRunner
├── Blackboard
├── HFSM (locomoção/estado físico)
├── Sensors
├── TargetingComponent
├── MovementComponent
├── AnimationBridge
├── HitboxManager
└── CueReceiver
```

## Responsabilidades
- **BT:** decide o que a IA quer tentar fazer.
- **GAS:** decide se pode fazer e executa a regra de gameplay.
- **HFSM:** representa estados físicos incompatíveis/locomotores.
- **AnimationBridge:** traduz eventos de ability para AnimationTree/AnimationPlayer.
- **Movement:** executa deslocamento físico solicitado por tasks/locomoção.
- **Targeting:** seleciona e pontua alvos.
- **Cue:** feedback audiovisual, sem regra de gameplay.

## Regra contra duplicação
Não criar `AttackState` para reproduzir toda a lógica de `AttackAbility`. A ability é a fonte da ação. A HFSM só deve bloquear/representar estados físicos que realmente necessitam máquina de estados.
