# Manual — Criar um Ataque

## Modelo
Ataque é uma `GameplayAbility` configurada com dados, tasks e effects.

## Passos
1. Criar `GameplayAbility` de ataque.
2. Definir tag, ex. `Ability.Attack.Light.01`.
3. Definir required/blocked tags.
4. Definir tags concedidas durante execução, normalmente `State.Attacking`.
5. Definir animação.
6. Definir janela de hit via evento de animação/task.
7. Associar GameplayEffects de dano/poise/status.
8. Configurar targeting/lunge se necessário.
9. Configurar combo window/evento.
10. Associar GameplayCue de impacto.

## Fluxo esperado
```text
Activate
→ FaceTarget (opcional)
→ PlayAnimation
→ Wait HitFrame
→ ActivateHitbox
→ HitConfirmed
→ Apply Effects
→ Cue
→ Wait Animation End
→ EndAbility
```

## Estado no M2
O sandbox `res://scenes/debug/ability_m2_sandbox.tscn` demonstra o recorte já
implementado: custo → wait cancelável → ApplyEffect no target → end → cooldown.

As etapas de animação, hit frame, hitbox e cue entram com os adapters de combate no
M4. Até lá, o sandbox usa uma espera determinística para representar o frame do golpe.

## Nunca fazer
- `target.health -= damage` na ability;
- ligar hitbox permanentemente;
- duplicar cooldown no input;
- controlar regra de dano no AnimationPlayer.
