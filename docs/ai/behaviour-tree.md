# Behaviour Tree + Blackboard

## Papel
Behaviour Tree é o cérebro de decisão de inimigos e bosses. Ele não implementa ataques, dano ou cooldown.

## Fluxo
```text
Sensors → Blackboard → Behaviour Tree → Intent → GAS Ability
```

## Blackboard
Tipos mínimos esperados:
- target;
- last known target position;
- distance to target;
- line of sight;
- self health ratio;
- target health ratio;
- current phase;
- tactical flags;
- timestamps/cooldowns de decisão quando necessário.

## Nodes mínimos
### Composites
- Sequence
- Selector
- Reactive Selector, apenas se necessário

### Decorators
- Inverter
- Cooldown
- Blackboard condition
- GameplayTag condition

### Tasks
- Wait
- MoveTo
- FaceTarget
- Strafe
- SetBlackboard
- FindTarget
- ActivateAbility
- StopMovement

## ActivateAbility Task
A BT task solicita uma ability ao ASC. O GAS continua responsável por `can_activate`, custos e cooldowns.

A task deve distinguir:
- falha porque não pode ativar;
- ability iniciada;
- ability concluída;
- ability cancelada.

## Escalonamento
- inimigo comum: árvore pequena e legível;
- elite: mais escolhas e reações;
- boss: BT + componente de fases; fases podem conceder/remover abilities e alterar pesos/branches.

## Anti-pattern
Não codificar `deal_damage()` ou `play_attack_animation()` dentro de BT tasks de ataque. A BT solicita uma GameplayAbility.
