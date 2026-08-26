# Manual — Criar um Inimigo

## Pré-requisitos
Personagem base funcionando, GAS e BT disponíveis.

## Passos
1. Duplicar/instanciar a base de `EnemyCharacter`.
2. Criar `AttributeSet` próprio.
3. Criar um `AbilityLoadout` com ataques e defesa necessários.
4. Criar Blackboard schema/data.
5. Criar Behaviour Tree.
6. Configurar Sensors e Targeting.
7. Associar AnimationBridge e animações.
8. Ajustar parâmetros táticos: ranges, strafe, retreat, agressividade.

## Regra
A BT nunca aplica dano diretamente. Ela usa `ActivateAbility`.

## Exemplo de árvore
```text
Selector
├── Sequence [target valid, in attack range]
│   └── ActivateAbility Ability.Attack.Light
└── MoveTo target
```

## Checklist de validação
- perde alvo corretamente;
- não ataca enquanto `State.Stunned`;
- respeita cooldown da ability;
- não precisa de condição duplicada em BT e Ability para regras de gameplay;
- death encerra BT/movimento de forma segura.
