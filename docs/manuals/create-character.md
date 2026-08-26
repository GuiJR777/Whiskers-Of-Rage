# Manual — Criar um Personagem

## Objetivo
Criar um personagem jogável, NPC combatente ou base compartilhada sem alterar o core.

## Estrutura mínima
```text
CharacterBody3D
├── AbilitySystemComponent
├── MovementComponent
├── AnimationBridge
├── HitboxManager
├── HurtboxRoot
├── TargetingComponent (quando aplicável)
└── HFSM (quando necessária para locomoção/estado físico)
```

## Passos
1. Criar a cena do personagem.
2. Adicionar `AbilitySystemComponent`.
3. Atribuir `AttributeSet` inicial.
4. Conceder abilities iniciais via loadout/resource, nunca hardcoded no `_ready()` se puder ser data-driven.
5. Configurar tags iniciais, por exemplo `State.Grounded`.
6. Adicionar AnimationBridge e mapear eventos de animação.
7. Configurar hurtboxes.
8. Configurar MovementComponent.
9. Para player, conectar Input → intenção/Combo/ASC.
10. Para enemy, conectar BT → ASC.

## Validação
- attributes aparecem no debugger;
- tags iniciais corretas;
- ability dummy ativa;
- damage effect pode ser recebido;
- death/stun não exigem código específico do personagem.
