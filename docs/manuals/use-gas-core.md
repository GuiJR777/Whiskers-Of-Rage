# Manual — Usar o núcleo GAS

## Objetivo
Configurar um personagem com `AbilitySystemComponent` (ASC) e aplicar damage,
buffs ou debuffs entre dois ASCs sem modificar o núcleo do addon.

## Pré-requisitos
- Godot 4.7+;
- plugin `WOR Gameplay Framework` habilitado;
- uma cena com um Node que represente o ator do gameplay.

## Estrutura mínima
```text
CharacterBody3D (ou outro Node do ator)
└── AbilitySystemComponent
```

O ASC é um Node. `GameplayTag`, `GameplayAttribute`, `GameplayAttributeSet`,
`GameplayModifier` e `GameplayEffect` são Resources reutilizáveis. Valores atuais,
stacks e duração vivem somente no ASC e em `ActiveGameplayEffect`.

## Configurar atributos no editor
1. Crie um Resource `GameplayAttribute` para cada atributo, por exemplo `Health`.
2. Defina `attribute_name`, `default_value`, `minimum_value` e `maximum_value`.
3. Crie um Resource `GameplayAttributeSet` e adicione os atributos em `attributes`.
4. Adicione um Node com o script `AbilitySystemComponent` ao ator.
5. Adicione o set em `initial_attribute_sets` do ASC.
6. Opcionalmente, adicione Resources `GameplayTag` em `initial_tags`.

Um mesmo `GameplayAttributeSet` pode inicializar vários atores: o Resource guarda
somente configuração e cada ASC cria seus próprios valores de runtime.

## Criar e aplicar um efeito
1. Crie um `GameplayModifier`, selecione o atributo e a operação:
   - `ADD`: soma `magnitude`;
   - `MULTIPLY`: usa `magnitude` como fator (`1.2` representa +20%);
   - `OVERRIDE`: substitui o valor agregado.
2. Crie um `GameplayEffect`, preencha um `effect_id` único e escolha a policy:
   - `INSTANT`: altera o valor base imediatamente e não cria handle ativo;
   - `DURATION`: mantém modifiers/tags durante `duration`;
   - `INFINITE`: permanece até a remoção explícita;
   - `PERIODIC`: aplica seus modifiers ao valor base a cada `period` durante `duration`.
3. Adicione modifiers e, quando necessário, `granted_tags`.
4. Aplique no ASC alvo:

```gdscript
var context := AbilityContext.create(source_asc, target_asc, attacker)
var handle := target_asc.apply_gameplay_effect(damage_effect, context)
```

Effects ativos retornam um handle positivo. Effects `INSTANT` retornam
`AbilitySystemComponent.INVALID_EFFECT_HANDLE` porque não possuem estado para remover.

## Stacking e remoção
`stacking_policy = NONE` cria uma instância ativa por aplicação.
`AGGREGATE_BY_SOURCE` agrega aplicações da mesma definição e do mesmo source ASC.
`AGGREGATE_BY_TARGET` agrega a mesma definição no alvo, independentemente da origem.

Configure `maximum_stacks` e `refresh_duration_on_reapplication`. Para equipamentos
ou outras fontes removíveis, guarde o handle retornado e remova exatamente essa fonte:

```gdscript
var equipment_handle := asc.apply_gameplay_effect(equipment_effect, context)
# Ao desequipar:
asc.remove_active_effect(equipment_handle)
```

Modifiers persistentes são agregados na ordem: soma, multiplicação e override.
O valor final sempre respeita os limites do `GameplayAttribute`.

## Exemplo concreto
Abra `res://scenes/debug/gas_core_sandbox.tscn`. A cena cria dois ASCs com 100 de
Health e aplica um damage instantâneo de 20 do source no target. A saída esperada é:

```text
GAS_SANDBOX: source Health=100.0, target Health=80.0
```

## Como validar
Execute a cena do sandbox uma vez e confira a linha acima e a ausência de erros.
Para a suíte focada em modo headless:

```text
godot --headless --path . --script res://tests/gas_core/run_gas_core_tests.gd
```

A saída esperada termina em `GAS_CORE_TESTS: PASS`.

## Erros comuns e anti-patterns
- Não altere `default_value` de um Resource para representar dano em runtime.
- Não use tags sem hierarquia semântica ou strings espalhadas pelo gameplay.
- Não aplique modifier a um atributo que não está registrado no ASC alvo; ele será ignorado com warning.
- Não descarte handles de effects `INFINITE` que precisarão ser removidos.
- Não use `MULTIPLY` com `20` para representar 20%; use `1.2`.
- Não coloque regras específicas de Ryu, Chakra, Jutsus ou equipamentos do WOR dentro do addon.

