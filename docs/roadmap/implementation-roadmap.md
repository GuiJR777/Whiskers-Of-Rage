# Roadmap de Implementação

## M0 — Bootstrap
- addon base;
- convenções;
- testes;
- debug sandbox.

**Estado:** implementado e validado em Godot 4.7.1. O addon, suíte headless e sandbox
mínimo estão disponíveis em `addons/wor_gameplay_framework/`, `tests/gas_core/` e
`scenes/debug/gas_core_sandbox.tscn`.

## M1 — GAS Core
- GameplayTag;
- TagContainer;
- Attributes;
- AttributeSet;
- GameplayEffect;
- ActiveEffect;
- AbilityContext;
- AbilitySystemComponent.

Critério: aplicar damage/buff/debuff entre dois ASCs sem dependência de WOR.

**Estado:** implementado e validado. O core cobre tags hierárquicas, atributos,
effects Instant/Duration/Infinite/Periodic, stacking, handles, cleanup e contexto
source/target sem dependências da camada `game/`.

## M2 — Abilities
- GameplayAbility;
- specs/grant/revoke;
- cost;
- cooldown;
- cancelamento;
- GameplayEvents;
- AbilityTasks.

Critério: ability de ataque dummy completa lifecycle e aplica effect.

**Estado:** implementado e validado em Godot 4.7.1. Inclui definitions/runtime de
abilities e tasks, AbilitySpec, grant/revoke, required/blocked/owned tags, custos,
cooldowns, cancelamento hierárquico, GameplayEvents e as tasks genéricas WaitSeconds,
WaitGameplayEvent e ApplyEffect. O critério está demonstrado em
`scenes/debug/ability_m2_sandbox.tscn`.

## M3 — Editor & Debugger
- tag editor;
- effect editor;
- ability inspector/editor;
- ASC runtime debugger;
- validações.

**Estado:** implementado e validado em Godot 4.7.1. Inclui catálogo central com
árvore/busca/CRUD e autocomplete, browsers de Resources, inspectors reativos para
abilities/effects, propriedades condicionais e snapshots runtime somente leitura de
attributes, tags, abilities, cooldowns, effects, eventos e warnings. O fluxo está
demonstrado em `scenes/debug/editor_tools_m3_sandbox.tscn`.

## M4 — Combat Integration
- Hitbox/Hurtbox;
- AnimationBridge;
- damage execution;
- poise/stun;
- block/parry;
- cues;
- combo integration.

## M5 — AI Framework
- Blackboard;
- Behaviour Tree;
- composites/decorators/tasks;
- sensors;
- ActivateAbility integration.

## M6 — WOR Gameplay
- Ryu integration;
- free-follow camera;
- soft targeting;
- Jutsu/Chakra;
- Techniques;
- Equipment;
- Throwable;
- enemy archetype.

## M7 — Boss-ready
- phases;
- advanced BT;
- boss abilities;
- debug tooling/telemetry suficiente para balanceamento.

## Regra de milestone
Não avançar porque 'o código existe'. Avançar quando o critério funcional está demonstrado em cena de teste e documentado.
