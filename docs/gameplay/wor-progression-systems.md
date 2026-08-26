# Jutsus, Técnicas e Equipamentos

Este documento é específico de WOR e não deve contaminar o núcleo genérico do GAS.

## Jutsus
Jutsus são habilidades ativas executadas através de GameplayAbilities.

Ryu possui inicialmente **3 slots discretos de Chakra**.
- Jutsu manual do Slot 1: custo 1 slot.
- Jutsu manual do Slot 2: custo 1 slot.
- Jutsu combinado: derivado dos elementos/Artes dos dois Jutsus equipados; custo 3 slots.

O combined Jutsu não deve ser tratado como terceira escolha independente. Um `JutsuCombinationDatabase` resolve o par de elementos/Artes para o Jutsu combinado disponível, respeitando requisitos de progressão/maestria definidos pelo GDD.

## Técnicas
Técnicas são passivas equipáveis em slots de trigger, inspiradas no modelo de Absolum.

Exemplos de trigger slots:
- Light Attack
- Heavy Attack
- Finisher
- Block
- Parry
- Dash
- Jump
- Landing
- Throw
- Throwable Use

Uma técnica escuta GameplayEvents e, quando condições são satisfeitas, aplica effects, concede tags, executa cues ou solicita ações permitidas.

Técnicas não devem virar dezenas de subclasses. Preferir `TechniqueResource` data-driven + Conditions/Responses compostas.

## Equipamentos
Equipamentos alteram stats principalmente por GameplayEffects de duração Infinite enquanto equipados.

Equipar:
`EquipmentComponent → apply_effect(spec/source=equipment)`

Desequipar:
remove os effects concedidos por aquela instância.

Set bonuses também devem ser representados por effects/abilities concedidos quando limiares do conjunto são atingidos.
