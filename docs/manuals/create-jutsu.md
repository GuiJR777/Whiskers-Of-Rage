# Manual — Criar um Jutsu

## Conceito
Jutsu é conteúdo específico de WOR e executa uma GameplayAbility.

## Passos
1. Criar `JutsuResource`.
2. Definir Arte/elemento.
3. Referenciar `GameplayAbility` do Jutsu.
4. Definir custo em slots de Chakra.
5. Configurar icon/ID/localização.
6. Definir tags/effects/cues usados pela ability.
7. Se for Jutsu base, registrar no pool adequado.
8. Se for combinado, registrar o par no `JutsuCombinationDatabase` e requisitos de maestria.

## Custos atuais
- manual: 1 Chakra slot;
- combinado: 3 Chakra slots.

## Regra importante
O Jutsu combinado é resolvido pelo par dos dois Jutsus/Artes equipados; não é um terceiro loadout independente.
