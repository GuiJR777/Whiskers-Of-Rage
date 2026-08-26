# Combo System

## Regra central
Combos de WOR avançam com **hit-confirm** quando a sequência exigir conexão.

## Responsabilidade
`ComboComponent` decide qual GameplayAbility de ataque solicitar para o próximo passo. Ele não executa dano nem animação.

## ComboResource
Deve permitir, por step:
- ability/tag;
- input requerido;
- janela de input;
- requer hit confirmado;
- condições de chão/ar;
- branches opcionais.

## Fluxo
```text
Input → ComboComponent → próximo step → ASC.try_activate()
     ↖ Combat.Hit.Confirmed / ComboWindow events
```

## Eventos de animação
Janelas de combo devem chegar via AnimationBridge/GameplayEvent, não por tempos duplicados hardcoded em múltiplos scripts.
