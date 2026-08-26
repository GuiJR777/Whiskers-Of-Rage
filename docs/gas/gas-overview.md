# Gameplay Ability System — WOR

## Objetivo
Implementar um GAS inspirado na Unreal, reduzido ao necessário para single-player e idiomático para Godot.

## Módulos obrigatórios
1. `AbilitySystemComponent`
2. `GameplayAbility`
3. `GameplayEffect`
4. `GameplayAttribute` / `AttributeSet`
5. `GameplayTag` / `GameplayTagContainer`
6. `GameplayEvent`
7. `GameplayCue`
8. `AbilityTask`
9. `AbilityContext`
10. `GameplayExecutionCalculation`

## AbilitySystemComponent
Responsável por:
- abilities concedidas;
- ativação/cancelamento;
- tags atuais;
- attributes;
- active effects;
- cooldowns/custos;
- dispatch de gameplay events;
- lifecycle de cues associados a effects/abilities.

Não deve controlar diretamente AnimationTree, física ou IA.

## GameplayAbility
Representa uma ação executável. Deve declarar:
- tag principal;
- required tags;
- blocked tags;
- tags concedidas enquanto ativa;
- custo;
- cooldown;
- política de cancelamento;
- tasks/sequência de execução.

## GameplayEffect
Representa alteração de estado/atributo.
Tipos:
- Instant;
- Duration;
- Infinite;
- Periodic.

Suporta:
- modifiers;
- granted tags;
- stacking;
- duração/período;
- cues;
- calculation customizada.

## Attributes
Exemplos iniciais de WOR:
- Health / MaxHealth
- Stamina / MaxStamina
- Strength / AttackPower
- Defense
- Poise / MaxPoise
- MoveSpeed
- CriticalChance
- CriticalDamage
- resistências elementais quando necessárias

Chakra discreto pode ser exposto ao GAS por uma interface/custo customizado, sem obrigar o núcleo genérico a conhecer a regra de 3 slots de WOR.

## Tags
Hierárquicas. Exemplos:
```text
State.Grounded
State.Airborne
State.Attacking
State.Blocking
State.Parrying
State.Stunned
State.KnockedDown
State.Dead
Ability.Attack.Light
Ability.Attack.Heavy
Ability.Jutsu
Status.Burning
Combat.Hit.Confirmed
Combat.Parry.Success
```

## AbilityContext
Carrega dados transitórios:
- instigator;
- source ASC;
- target ASC;
- ability;
- world position;
- hit direction;
- hit result;
- metadata/tags;
- back attack;
- critical;
- source object.

## ExecutionCalculation
Usada para cálculos que excedem modifiers declarativos. Exemplo: dano físico considerando Strength, Defense, back attack e crítico.

## Contrato do core M1
- uma tag possuída satisfaz consultas exatas e consultas por ancestral (`State.Stunned.Heavy` corresponde a `State.Stunned`);
- `GameplayAttribute`, `GameplayAttributeSet`, `GameplayModifier` e `GameplayEffect` são definições imutáveis em `Resource`;
- valores base/atuais, contagem de tags, duração e stacks pertencem ao `AbilitySystemComponent` e a `ActiveGameplayEffect`;
- effects `Instant` alteram o valor base e não criam handle ativo;
- effects `Duration` e `Infinite` agregam modifiers enquanto ativos;
- effects `Periodic` aplicam modifiers ao valor base a cada período e expiram após a duração;
- modifiers persistentes são agregados na ordem add → multiply → override e depois limitados pelo atributo;
- stacking pode criar instâncias independentes, agregar por source ASC ou agregar por target ASC;
- remoção explícita usa o handle retornado por `apply_gameplay_effect()`.

A API e o fluxo de configuração estão descritos em `docs/manuals/use-gas-core.md`.

## Contrato de abilities M2
- `GameplayAbility` é uma definição imutável em `Resource`; cada concessão cria um `AbilitySpec` no ASC;
- um mesmo Resource pode ser concedido a vários ASCs sem compartilhar estado de ativação ou cooldown;
- `grant_ability()` retorna um handle usado para ativar, cancelar e revogar;
- required/blocked tags, custo e cooldown são validados antes de qualquer commit;
- custos são `GameplayEffect` Instant com modifiers ADD não positivos e são aplicados no owner ASC;
- cooldowns são `GameplayEffect` Duration e podem começar na ativação ou no encerramento;
- tags de ativação usam contagem de referências e são removidas em end, cancel e revoke;
- `cancel_abilities_with_tags` compara hierarquicamente a tag principal das abilities ativas;
- tasks são definitions em Resource e criam instâncias runtime canceláveis por ativação;
- tasks executam em sequência; conclusão da última task encerra a ability;
- `GameplayEvent` é despachado localmente pelo ASC e pode completar `WaitGameplayEvent`.

As tasks genéricas disponíveis no M2 são `WaitSeconds`, `WaitGameplayEvent` e
`ApplyEffect`. Tasks que dependem de animação, movimento, hitbox, targeting ou cues
entram junto dos adapters correspondentes em milestones posteriores.

## Não implementar
- prediction;
- network roles;
- replication;
- rollback;
- RPC.
