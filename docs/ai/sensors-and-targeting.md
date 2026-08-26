# Sensors e Targeting

## Sensors de IA
Sensores coletam dados; não decidem ação.
Possíveis sensores:
- visão;
- distância;
- dano recebido;
- alvo mais próximo;
- ângulo relativo;
- ameaça.

Atualizam Blackboard com frequência apropriada. Evitar scans caros a cada frame quando timers/áreas físicas bastam.

## Targeting de combate do player
O free-flow de WOR usa soft targeting.

Score inicial sugerido considera:
- direção do input;
- distância;
- posição na câmera;
- linha de visão;
- target stickiness;
- prioridade do inimigo.

A formulação exata é balanceamento de jogo e deve ficar configurável.

## Separação
Targeting retorna candidatos/resultado. GameplayAbility decide se usa o alvo e AbilityTask executa rotação/lunge quando necessário.
