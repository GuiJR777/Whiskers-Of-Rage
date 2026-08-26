# Regras de Dependência

## Fluxo permitido
```text
game/WOR content
      ↓
addons/wor_gameplay_framework
      ↓
Godot Engine APIs
```

Nunca no sentido inverso.

## Framework não conhece
- Ryu;
- chakra do WOR enquanto mecânica específica;
- nomes de Artes Ninja;
- Técnica específica;
- equipamento específico;
- inimigos ou bosses específicos;
- regras narrativas.

## Comunicação
Preferências:
1. chamadas diretas a interfaces/componentes conhecidos;
2. signals locais;
3. GameplayEvents semânticos;
4. event bus global apenas para eventos verdadeiramente globais.

## Dados
Resources são preferidos para definições imutáveis/configuráveis:
- abilities;
- effects;
- cues;
- tags;
- combos;
- techniques;
- jutsus;
- equipment;
- behaviour tree assets quando aplicável.

Estado de runtime não deve ser gravado no Resource compartilhado. Use instâncias runtime (`ActiveEffect`, `AbilitySpec`, etc.).
