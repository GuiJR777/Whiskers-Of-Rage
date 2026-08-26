# Arquitetura de Combate

## Pipeline de hit
```text
GameplayAbility
 → AbilityTask ActivateHitbox
 → Hitbox detecta Hurtbox
 → cria/expande AbilityContext
 → target AbilitySystemComponent
 → aplica GameplayEffect(s)
 → GameplayEvent HitConfirmed
 → GameplayCue
```

## Hitbox
Responsável apenas por detecção e dados de contato. Não reduz Health diretamente.

## Hurtbox
Identifica receptor/ASC e informações locais relevantes, como região atingida quando necessário.

## Dano
Dano é um GameplayEffect/ExecutionCalculation, nunca uma chamada `health -= x` dentro da Hitbox.

## Poise e reações
- dano de Health e dano de Poise podem ser efeitos separados;
- quebrar Poise pode gerar `Combat.PoiseBroken`;
- Stun/Knockdown são effects/tags;
- movimento físico de knockback/launch é executado por componente de movimento/reaction, solicitado por evento/contexto.

## Defesa e Parry
Block e Parry são abilities/estados GAS.
Hit resolution consulta tags relevantes e emite:
- `Combat.Block.Success`
- `Combat.Parry.Success`
- `Combat.Hit.Confirmed`

## Back attack
Calculado a partir de orientação source/target no contexto e usado por ExecutionCalculation. Deve ser configurável.
