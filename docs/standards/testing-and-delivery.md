# Testes e Entrega

## Objetivo
O framework precisa ser confiável antes de virar base de conteúdo.

## Testar no mínimo
- tag matching hierárquico;
- required/blocked tags;
- attribute modifiers;
- instant/duration/periodic/infinite effects;
- stacking;
- ability costs/cooldowns;
- cancelamento e cleanup de tasks;
- events;
- BT traversal e abort/cancel;
- ActivateAbility BT task;
- remoção correta de equipment effects;
- chakra cost no módulo WOR.

## Cenas de integração
Manter uma pequena arena de teste com:
- dummy source;
- dummy target;
- health display/debug;
- ataque simples;
- effect periódico;
- stun;
- enemy BT mínimo.

## Entrega do Codex
Em toda PR/tarefa, informar:
1. o que foi implementado;
2. arquitetura afetada;
3. arquivos principais;
4. testes executados e resultado;
5. como validar manualmente;
6. docs atualizadas;
7. pendências/riscos.
