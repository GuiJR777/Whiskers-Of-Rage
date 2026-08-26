# Manual — Criar um Equipamento

## Conceito
Equipamentos concedem stats e, quando previsto, bonuses de set. Devem ser data-driven.

## Passos
1. Criar `EquipmentResource`.
2. Definir slot de equipamento.
3. Definir set, rarity/ID e conteúdo visual/UI necessário.
4. Criar/referenciar GameplayEffects Infinite para stats.
5. Configurar tags concedidas apenas quando semanticamente úteis.
6. Registrar efeitos de set no `EquipmentSetDefinition`.
7. Testar equip/unequip e troca de item.

## Regra de cleanup
Todo effect concedido pelo item precisa ter source/handle rastreável para remoção exata ao desequipar.
