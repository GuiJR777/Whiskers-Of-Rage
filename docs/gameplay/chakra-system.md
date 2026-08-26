# Chakra System

## Regra atual
Ryu inicia com 3 slots de Chakra. O recurso é discreto (`int`), não barra contínua.

## Custos
- Jutsu manual: 1 slot.
- Jutsu combinado: 3 slots.

## Integração GAS
O core pode definir uma interface genérica de `AbilityCost` ou custom cost. WOR implementa `ChakraSlotCost`.

Evitar adicionar `current_chakra_slots` diretamente ao ASC genérico apenas por necessidade de WOR.

## Eventos esperados
- `Resource.Chakra.Changed`
- `Resource.Chakra.Spent`
- `Resource.Chakra.Gained`
- `Resource.Chakra.Empty`
- `Resource.Chakra.Full`

Técnicas podem reagir a esses eventos.
