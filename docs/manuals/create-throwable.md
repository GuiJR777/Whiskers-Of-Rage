# Manual — Criar um Arremessável

## Conceito
Arremessável é uma ação de gameplay que pode criar projétil/área e aplicar effects.

## Passos
1. Criar `ThrowableResource`.
2. Definir ability de uso.
3. Definir projectile/scene ou método de spawn.
4. Definir velocity/range/lifetime.
5. Associar GameplayEffects aplicados ao impacto/área.
6. Associar GameplayCue de lançamento e impacto.
7. Emitir `Combat.Throwable.Use` para Técnicas.
8. Configurar quantidade/consumo no sistema de inventário da run.

## Regra
Projétil detecta impacto e transmite contexto; dano/status continuam passando pelo ASC.
