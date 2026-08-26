# Manual — Criar uma Técnica

## Conceito
Técnica é passiva equipada em um slot de trigger e reage a GameplayEvents.

## Passos
1. Criar `TechniqueResource`.
2. Selecionar trigger slot/event tag.
3. Definir Conditions compostas.
4. Definir Responses: aplicar effect, conceder tag temporária, cue ou outra reação suportada.
5. Definir cooldown interno/proc chance apenas se o design exigir.
6. Definir Arte Ninja e requisitos de desbloqueio.
7. Testar no `TechniqueComponent` sem alterar a ability que gera o evento.

## Exemplo
```text
Trigger: Combat.Parry.Success
Condition: self chakra < max
Response: Gain 1 Chakra Slot
```

## Anti-pattern
Não criar `SpecialParryTechnique.gd` para cada técnica se a composição de conditions/responses consegue representar o comportamento.
