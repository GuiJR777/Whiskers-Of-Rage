# Manual — Usar as ferramentas de editor do GAS

## Objetivo
Criar e validar Tags, GameplayAbilities e GameplayEffects sem editar scripts do core,
além de inspecionar o estado de `AbilitySystemComponent` durante a execução.

## Pré-requisitos
- Godot 4.7+;
- plugin `WOR Gameplay Framework` habilitado;
- `AbilitySystemComponent` configurado conforme `use-gas-core.md`;
- catálogo indicado em `Project Settings > WOR Gameplay Framework > Tags > Catalog Path`.

O projeto inclui `res://gameplay_tags.tres` como catálogo inicial.

## Workspace GAS
O plugin adiciona a aba principal `GAS`, ao lado de 2D, 3D, Script e Jogo, com as áreas:
- **Tags:** árvore hierárquica, busca, criação, remoção e rename de subárvore;
- **Abilities:** lista e criação de Resources `GameplayAbility`;
- **Effects:** lista e criação de Resources `GameplayEffect`;
- **Attributes:** lista e criação de Resources de atributo;
- **Cues:** navegação reservada ao contrato do M4;
- **Debugger:** snapshots dos ASCs de uma cena em execução.

Na lista de Resources, dê duplo clique em um item para abri-lo no Inspector.

## Criar e usar tags
1. Abra `GAS > Tags`.
2. Digite uma tag hierárquica, por exemplo `State.Stunned.Heavy`.
3. Clique em **Adicionar**.
4. Use a busca para filtrar a árvore.
5. Para renomear, selecione uma tag registrada, altere o campo e clique em
   **Renomear**. Os descendentes e os Resources que referenciam os mesmos objetos de
   tag acompanham o rename.
6. Para remover somente a entrada selecionada do catálogo, clique em **Remover**.

Campos `GameplayTag` e arrays de `GameplayTag` nos Resources validados exibem seletores
alimentados pelo catálogo. Isso evita strings mágicas e tags duplicadas criadas inline.

## Criar abilities e effects
1. Abra a aba **Abilities** ou **Effects** e clique em **Novo Resource**.
2. Salve o `.tres` fora do diretório do addon, na pasta de conteúdo do projeto.
3. Configure o Resource no Inspector. O painel superior atualiza a validação conforme
   as propriedades mudam.
4. Em `GameplayEffect`, campos incompatíveis com a policy ficam ocultos. Por exemplo,
   `period` aparece somente em effects `PERIODIC`.
5. Corrija todos os itens do painel de validação antes de conceder/aplicar o Resource.

As regras específicas de custo, cooldown e policies continuam documentadas em
`create-gameplay-ability.md` e `create-gameplay-effect.md`.

## Runtime Debugger
1. Execute uma cena em modo debug pelo editor.
2. Abra a aba principal `GAS` e selecione `Debugger`.
3. Escolha um ASC pelo caminho da SceneTree.
4. Inspecione base/current attributes, tags e contagens, abilities e estados,
   cooldowns, active effects, duração, stacks, últimos GameplayEvents e warnings de
   lifecycle.
5. Pare a cena para limpar os snapshots.

O autoload `WORGasRuntimeDebug` existe somente como ponte de tooling. Ele coleta
snapshots quatro vezes por segundo apenas quando `EngineDebugger` está ativo; não
modifica gameplay e não é necessário em builds release.

## Exemplo concreto
Execute `res://scenes/debug/editor_tools_m3_sandbox.tscn`. No debugger aparecem:
- `SourceASC` com Stamina, uma ability ativa e um evento recente;
- `TargetASC` com Health, `Status.Burning` e um effect periódico com tempo restante.

A saída inicial esperada contém:

```text
EDITOR_TOOLS_M3_SANDBOX: source_abilities=1, source_events=1, target_effects=1, target_tags=1
```

## Como validar
- crie e renomeie uma tag e confirme a árvore/busca;
- abra uma ability inválida e confirme os erros no topo do Inspector;
- execute o sandbox e confira os dois ASCs no Runtime Debugger;
- teste focado, quando necessário:

```text
godot --headless --path . --script res://tests/editor_tools/run_editor_tools_tests.gd
```

## Erros comuns e anti-patterns
- Não crie tags soltas inline quando a tag pertence ao catálogo do projeto.
- Remover uma tag do catálogo não apaga referências já salvas; corrija consumidores
  antes da remoção definitiva.
- Não salve abilities/effects de conteúdo dentro de `addons/`.
- Não use o debugger como fonte de estado ou regra de gameplay; snapshots são
  somente leitura.
- Não adicione lógica específica de WOR ao workspace genérico.
