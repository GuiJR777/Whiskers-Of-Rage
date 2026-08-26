# Manual — Criar um Status Effect

## Conceito
Status é normalmente um GameplayEffect Duration/Periodic com tags.

## Passos
1. Criar GameplayEffect.
2. Selecionar duration policy.
3. Definir duração/período.
4. Definir modifiers ou execution.
5. Conceder tag `Status.*`.
6. Definir stacking.
7. Associar cue persistente se necessário.
8. Testar reaplicação, refresh, stack e remoção.

## Exemplo Burning
```text
Duration: 5s
Period: 1s
Granted Tag: Status.Burning
Modifier: Health damage periódico
Max Stacks: conforme balanceamento
Cue: Cue.Status.Burning
```
