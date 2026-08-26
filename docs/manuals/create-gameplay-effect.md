# Manual — Criar um Gameplay Effect

## Objetivo
Criar uma definição data-driven que altere atributos ou conceda tags a um ASC.

## Pré-requisitos
- núcleo GAS configurado conforme `docs/manuals/use-gas-core.md`;
- `GameplayAttribute` registrado no ASC alvo para cada modifier.

## Passos
1. Crie um Resource `GameplayEffect` e defina um `effect_id` hierárquico e estável.
2. Escolha `duration_policy`: `INSTANT`, `DURATION`, `INFINITE` ou `PERIODIC`.
3. Para `DURATION`/`PERIODIC`, configure `duration`; para `PERIODIC`, configure também `period`.
4. Crie Resources `GameplayModifier`, selecionando atributo, operação e magnitude.
5. Adicione tags semânticas em `granted_tags` quando o estado precisar ser consultado.
6. Configure `stacking_policy`, `maximum_stacks` e refresh somente se aplicações repetidas agregarem.
7. Aplique com `AbilitySystemComponent.apply_gameplay_effect(effect, context)`.
8. Guarde o handle de effects ativos quando houver remoção explícita.

## Estrutura dos Resources
```text
GameplayEffect
├── modifiers: GameplayModifier[]
│   └── attribute: GameplayAttribute
└── granted_tags: GameplayTag[]
```

## Exemplos
- dano: `INSTANT` + modifier `Health ADD -20`;
- stun: `DURATION` + `State.Stunned`;
- equipamento: `INFINITE`, removido pelo handle da aplicação;
- poison: `PERIODIC` + modifier `Health ADD -5`;
- stamina cost: `INSTANT` aplicado no source ASC.

## Como validar
Confirme o valor com `get_attribute_value()`, as tags com `has_tag()` e, para efeitos
ativos, verifique se o handle deixa de resolver após expiração/remoção.

## Erros comuns
- Modifier aponta para atributo ausente no alvo: ele é ignorado e gera warning.
- `DURATION` ou `PERIODIC` com duração zero: o Resource é rejeitado.
- `MULTIPLY` usa fator, não porcentagem inteira.
- Tags em effects `INSTANT` não persistem; use `DURATION` ou `INFINITE`.
- Estado de runtime nunca deve ser gravado no Resource compartilhado.
