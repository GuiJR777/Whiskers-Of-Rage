# Manual — Criar um Boss

## Arquitetura
Boss = EnemyCharacter + GAS + BT + BossPhaseComponent.

## Passos
1. Criar attributes e resistências.
2. Criar abilities do boss.
3. Criar Behaviour Tree base.
4. Criar fases e critérios de transição.
5. Em mudanças de fase, conceder/remover abilities ou mudar subtree/blackboard flags.
6. Configurar telegraphs e cues.
7. Configurar poise/immunities via tags/effects, não branches especiais espalhados.
8. Testar transições em thresholds e durante stun/ability ativa.

## Regra
Fase decide disponibilidade/estratégia; a ability continua responsável pela execução concreta.
