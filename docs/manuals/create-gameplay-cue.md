# Manual — Criar um Gameplay Cue

## Uso
GameplayCue executa feedback, não regra de gameplay.

Pode disparar:
- VFX;
- SFX;
- hit stop;
- camera shake;
- rumble;
- decal/feedback visual.

## Passos
1. Criar Cue Resource/definition.
2. Definir tag `Cue.*`.
3. Configurar ações de apresentação.
4. Definir lifecycle instant/persistent.
5. Associar a ability/effect.

## Regra
Remover o Cue não deve mudar dano, custo ou condição de vitória.
