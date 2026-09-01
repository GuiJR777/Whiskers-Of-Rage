# Ferramentas de Editor do GAS

## Objetivo
Permitir criar conteúdo sem editar scripts do core.

## Workspace principal
Deve oferecer navegação para:
- Abilities
- Effects
- Attributes
- Tags
- Cues
- Debugger

Conteúdo específico de WOR (Jutsus, Técnicas, Equipamentos) pode ser fornecido por plugin/editor separado na camada do jogo reutilizando widgets do framework.

## Tag Editor
Requisitos:
- árvore hierárquica;
- adicionar/remover/renomear com validação;
- busca;
- autocomplete em campos de tag;
- detectar duplicatas e tags inválidas.

## Effect Editor
Deve editar:
- duration policy;
- duration/period;
- modifiers;
- tags;
- stacking;
- cue;
- custom calculation.

## Ability Editor
Primeira versão não é graph editor. É um editor de Resource estruturado, com:
- tags;
- costs;
- cooldown;
- policy;
- referências de tasks/configuração declarativa quando aplicável;
- validações.

## Runtime Debugger
Ao selecionar um ASC em execução mostrar:
- attributes atuais/base;
- tags;
- abilities e estado;
- cooldowns;
- active effects e tempo restante;
- stacks;
- últimos gameplay events;
- warnings de lifecycle.

## Contrato implementado no M3
- `GameplayTagCatalog` é a fonte central de tags para árvore, busca, validação e
  autocomplete; seu caminho é configurável em
  `wor_gameplay_framework/tags/catalog_path`;
- rename de uma tag registrada preserva o objeto `GameplayTag` e renomeia seus
  descendentes, mantendo referências existentes consistentes;
- o workspace principal `GAS`, ao lado de 2D, 3D, Script e Jogo, navega por Tags,
  Abilities, Effects, Attributes, Cues e Debugger;
- Abilities e Effects usam o Inspector estruturado nativo com seletores vindos do
  catálogo e um painel reativo de `validate()`;
- propriedades incompatíveis com a duration/stacking policy do effect são ocultadas;
- cada ASC expõe um snapshot somente leitura e serializável;
- o bridge de runtime envia snapshots apenas enquanto `EngineDebugger` está ativo;
- o debugger nunca altera attributes, tags, effects ou abilities.

O fluxo completo está em `docs/manuals/use-gas-editor-tools.md`.
