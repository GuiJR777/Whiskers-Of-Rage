# Manual — Criar uma Gameplay Ability

## Objetivo
Criar uma ação data-driven, concedê-la a um `AbilitySystemComponent` e executar seu
lifecycle com tags, custo, cooldown, tasks, cancelamento e eventos.

## Pré-requisitos
- núcleo GAS M1 configurado conforme `docs/manuals/use-gas-core.md`;
- atributos usados pelo custo registrados no owner ASC;
- effects que a ability aplicará já criados e validados.

## Estrutura dos Resources
```text
GameplayAbility
├── ability_tag: GameplayTag
├── activation_*_tags: GameplayTag[]
├── cost_effect: GameplayEffect (Instant, opcional)
├── cooldown_effect: GameplayEffect (Duration, opcional)
└── tasks: AbilityTaskDefinition[]
    ├── WaitSecondsAbilityTaskDefinition
    ├── WaitGameplayEventAbilityTaskDefinition
    └── ApplyEffectAbilityTaskDefinition
```

`GameplayAbility` e suas task definitions são configuração compartilhável. O ASC
cria um `AbilitySpec` e tasks runtime independentes para cada concessão/ativação.

## Configuração no editor
1. Crie um Resource `GameplayAbility`.
2. Defina uma `ability_tag` hierárquica, por exemplo `Ability.Attack.Light.01`.
3. Configure:
   - `activation_required_tags`: todas precisam existir no ASC;
   - `activation_blocked_tags`: qualquer uma impede ativação;
   - `activation_owned_tags`: permanecem somente enquanto a ability está ativa;
   - `cancel_abilities_with_tags`: abilities ativas cujas tags serão canceladas.
4. Para custo, atribua um `GameplayEffect` `INSTANT` composto apenas por modifiers
   `ADD` não positivos, por exemplo `Stamina ADD -20`.
5. Para cooldown, atribua um `GameplayEffect` `DURATION`. Tags como
   `Cooldown.Attack.Light` tornam o estado inspecionável.
6. Escolha `cooldown_commit_policy`:
   - `ON_ACTIVATION`: inicia antes das tasks;
   - `ON_END`: inicia ao terminar/cancelar, conforme `apply_cooldown_on_cancel`.
7. Adicione task definitions em `tasks`; elas executam na ordem do array.
8. Adicione a ability em `initial_abilities` do ASC ou conceda por código/loadout.

## Tasks do M2
- `WaitSeconds`: espera cancelável baseada no delta do ASC;
- `WaitGameplayEvent`: espera uma tag de evento exata ou hierárquica e limpa o signal;
- `ApplyEffect`: aplica um GameplayEffect no owner, source ou target do contexto.

Animação, hitboxes, movimento, targeting e cues dependem dos adapters de milestones
posteriores e não devem ser executados diretamente dentro do core.

## Conceder, ativar e remover
```gdscript
var handle := asc.grant_ability(light_attack)
var context := AbilityContext.create(asc, target_asc, character)

if asc.try_activate_ability(handle, context):
    print("Attack started")

asc.cancel_ability(handle)
asc.revoke_ability(handle)
```

Para conteúdo inicial data-driven, prefira `initial_abilities` em vez de hardcode no
`_ready()`. O handle pertence ao ASC e não deve ser salvo no Resource.

## GameplayEvents
```gdscript
var event := GameplayEvent.create(hit_confirmed_tag, context, {"damage": 25.0})
asc.send_gameplay_event(event)
```

`WaitGameplayEvent` considera hierarquia: `Combat.Hit.Confirmed` satisfaz uma espera
por `Combat.Hit`, salvo quando `exact_match` está habilitado.

## Como validar
- `can_activate_ability(handle)` retorna `&""` quando a ativação é permitida;
- falhas retornam IDs como `Ability.RequiredTagsMissing`,
  `Ability.BlockedTagsPresent`, `Ability.CostUnaffordable` e `Ability.CooldownActive`;
- confira signals `ability_activated`, `ability_ended`, `ability_cancelled` e
  `ability_activation_failed`;
- execute `res://scenes/debug/ability_m2_sandbox.tscn`;
- suíte headless:

```text
godot --headless --path . --script res://tests/abilities/run_ability_tests.gd
```

## Erros comuns e anti-patterns
- Não armazene cooldown, task ativa ou contexto no Resource da ability.
- Não altere atributos diretamente; custo e dano devem usar GameplayEffects.
- Não use effect Duration/Infinite como custo ou effect Instant como cooldown.
- Não descarte o handle se a ability precisará ser cancelada/revogada.
- Não mantenha signals conectados fora do lifecycle da task.
- Não controle AnimationTree, física ou IA diretamente no ASC.

## Pergunta de design
Antes de criar uma nova subclasse, verifique se o comportamento cabe em dados e nas
tasks existentes. Código novo deve representar comportamento realmente novo e genérico.
