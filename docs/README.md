# Documentação Técnica — Whiskers of Rage

Esta pasta é a fonte de verdade técnica para implementação do projeto e para agentes de código.

## Ordem de leitura
1. `architecture/system-overview.md`
2. `architecture/dependency-rules.md`
3. `gas/gas-overview.md`
4. `ai/behaviour-tree.md`
5. `combat/combat-architecture.md`
6. `gameplay/wor-progression-systems.md`
7. `standards/godot-standards.md`
8. `roadmap/implementation-roadmap.md`

## Direção atual
WOR é um **action roguelike 3D single-player com câmera livre** em Godot 4.7+.

A arquitetura é **GAS-first**. O Gameplay Ability System inspirado no GAS da Unreal é a infraestrutura central de regras de gameplay. Behaviour Trees controlam decisão de IA. HFSMs são usadas apenas onde estados físicos/locomotores se beneficiam delas.

## Regra fundamental
O framework deve crescer a partir de necessidades reais de WOR, mas permanecer genérico no núcleo. Conteúdo específico do jogo não entra no addon.

## Manuais
A pasta `manuals/` explica como usar o sistema sem modificar o core. Se uma feature exige editar arquivos internos do framework para criar conteúdo comum, a API ou o tooling provavelmente estão incompletos.

Para o bootstrap do GAS, comece por `manuals/use-gas-core.md` e depois consulte
`manuals/create-gameplay-effect.md`.

Para actions do M2, consulte `manuals/create-gameplay-ability.md` e
`manuals/create-attack.md`.

Para authoring e debug do M3, consulte `manuals/use-gas-editor-tools.md`.
