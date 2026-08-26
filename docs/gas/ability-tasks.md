# Ability Tasks

AbilityTasks encapsulam operações assíncronas e canceláveis pertencentes ao lifecycle de uma GameplayAbility.

## Tasks disponíveis no M2
- WaitSeconds
- WaitGameplayEvent
- ApplyEffect

Essas três tasks cobrem sequência assíncrona, espera por evento semântico e aplicação
de regra de gameplay. Cada item no array da ability é um `AbilityTaskDefinition`
imutável que cria um `AbilityTask` runtime novo por ativação.

## Tasks de integração previstas
- WaitGameplayTag / WaitInput;
- PlayAnimation / WaitAnimationFinished;
- SelectTarget / FaceTarget;
- MoveToTarget / AttackLunge;
- ActivateHitbox / DeactivateHitbox;
- ExecuteCue.

Essas tasks serão adicionadas quando os adapters correspondentes existirem. O core
M2 não conhece AnimationTree, MovementComponent, HitboxManager ou conteúdo do WOR.

## Contrato
Toda task deve:
- ter owner ability;
- poder ser cancelada;
- liberar conexões de signals;
- nunca sobreviver ao fim da ability;
- retornar resultado explícito quando necessário.

`WaitGameplayEvent` desconecta seu signal tanto na conclusão quanto no cancelamento.
Ao encerrar uma ability, o `AbilitySpec` cancela qualquer task ainda ativa.

## Regra de integração
Tasks podem chamar adaptadores (`AnimationBridge`, `MovementComponent`, `HitboxManager`) fornecidos pelo contexto. O núcleo GAS não deve conhecer Ryu ou animações específicas.
