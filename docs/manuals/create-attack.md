# Manual — Criar um Ataque

## Modelo
Ataque é uma `GameplayAbility` configurada com dados, tasks e effects.


## Passos revisados
Claro. Para adicionar mais um ataque ao combo atual:

* Criar `Ability.Attack.Light.03` no catálogo de tags e no `WORGameplayTags`.
* Criar `light_attack_03.tres` com dano/poise próprios.
* Criar `light_attack_03_ability.tres`:

  * tag `Ability.Attack.Light.03`
  * `Required`: `State.Grounded`, `State.Attacking`
  * `Blocked`: vazio
  * `Owned`: `State.Attacking`
  * `Cancel Abilities With Tags`: `Ability.Attack.Light.02`
  * task `WaitGameplayEvent(Event.Animation.AbilityFinished)`
* Adicionar essa Ability no `Initial Abilities` do ASC do Ryu.
* Criar a animação `light_attack_03`.
* Na StateMachine `Action` do `AnimationTree`, criar uma transição do novo estado
  para `End` com `Advance Mode = Auto` e `Switch Mode = At End`. Essa transição
  encerra o playback do estado e dispara `action_finished`; sem ela, a ability que
  aguarda `Event.Animation.AbilityFinished` permanece ativa.
* Criar `light_attack_03_animation_binding.tres` apontando para:

  * `Ability.Attack.Light.03`
  * animação `light_attack_03`
  * hitbox `Katana`
  * `light_attack_03.tres`
* Adicionar esse binding no array `Bindings` do `AnimationCombatBridge`.
* No `light_combo.tres`, adicionar um terceiro `ComboStep` com `Ability.Attack.Light.03`.
* Na animação do `light_attack_02`, adicionar:

  * `open_combo_window()`
  * `close_combo_window()`
* No `light_attack_03`, configurar normalmente:

  * `open_hitbox()`
  * animação de posição/tamanho da hitbox
  * `close_hitbox()`
  * sem Combo Window se for o último golpe.

Regra mental simples:

```text
Novo golpe =
Tag
+ AttackDefinition
+ GameplayAbility
+ Animation
+ AnimationBinding
+ ASC Initial Ability
+ ComboStep
+ ComboWindow no golpe anterior
```

Para um `Attack04`, é exatamente o mesmo processo.


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
