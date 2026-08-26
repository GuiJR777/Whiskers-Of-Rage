# AGENTS.md — Whiskers of Rage

## 1. Missão
Você está trabalhando no repositório de **Whiskers of Rage (WOR)**, um action roguelike 3D single-player desenvolvido em **Godot 4.7+**.

Sua função principal é atuar como engenheiro implementador: construir infraestrutura, plugins, ferramentas de editor, testes, exemplos mínimos e documentação. As decisões de arquitetura deste repositório são mandatórias.

## 2. Fonte de verdade
Antes de alterar código, leia nesta ordem:
1. `docs/README.md`
2. `docs/architecture/system-overview.md`
3. `docs/architecture/dependency-rules.md`
4. documentação específica do sistema alterado
5. manual correspondente em `docs/manuals/`

Não substitua decisões documentadas por preferências próprias. Se houver conflito, a documentação mais específica vence; se ainda houver ambiguidade, preserve os contratos existentes e registre a pendência em `docs/roadmap/open-decisions.md`.

## 3. Princípios obrigatórios
- Godot 4.7+.
- GDScript fortemente tipado sempre que possível.
- Single-player. Não criar replication, prediction, rollback, RPCs ou infraestrutura multiplayer.
- **GAS-first**: habilidades, atributos, efeitos, tags, eventos, cues, tasks e cálculos são a base das regras de gameplay.
- **Behaviour Tree** decide intenção de IA.
- **GAS** valida e executa ações.
- **HFSM** é restrita a locomoção, estados físicos e estados incapacitantes quando necessário.
- Composição acima de herança.
- Dados configuráveis devem preferir `Resource`.
- Runtime compartilhado entre player, enemies e bosses sempre que a regra for realmente comum.
- Sistemas devem depender de contratos, não de tipos concretos do WOR.
- Evitar strings mágicas; usar tags, IDs e recursos centralizados.
- Signals/event bus somente quando reduzirem acoplamento; não transformar tudo em evento global.
- O addon genérico nunca pode depender de classes específicas do WOR.

## 4. Separação de camadas
### Addon genérico
Local sugerido: `addons/wor_gameplay_framework/`

Pode conter:
- AbilitySystemComponent
- GameplayAbility
- GameplayEffect
- GameplayAttribute / AttributeSet
- GameplayTag / TagContainer
- GameplayEvent
- GameplayCue
- AbilityTask
- AbilityContext
- ExecutionCalculation
- Behaviour Tree / Blackboard genéricos
- ferramentas de editor e debugger genéricos

### Camada WOR
Local sugerido: `game/`

Contém:
- Ryu
- Jutsus
- Técnicas
- Equipamentos
- Combos do jogo
- Targeting/free-flow
- Hitbox/Hurtbox específicas de combate
- Enemy archetypes
- Boss phases
- Throwables
- balanceamento e conteúdo

## 5. Regra de dependência
`game/ -> addons/wor_gameplay_framework/` é permitido.

`addons/wor_gameplay_framework/ -> game/` é proibido.

O plugin deve ser utilizável em outro projeto Godot sem copiar código de WOR.

## 6. Qualidade de implementação
Toda feature de infraestrutura deve incluir, quando aplicável:
- implementação runtime;
- testes automatizados ou cena de teste determinística;
- ferramenta de editor se prevista pelo milestone;
- exemplo mínimo;
- atualização de documentação;
- mensagens de erro úteis;
- validação de Resources no editor quando possível.

Não considere uma feature concluída apenas porque compila.

## 7. Escopo e YAGNI
Não implemente features antecipadas sem necessidade documentada.

Especialmente proibido por padrão:
- multiplayer;
- visual scripting próprio;
- graph editor estilo Blueprint;
- ECS customizado;
- service locator global indiscriminado;
- singleton para cada sistema;
- framework de DI complexo;
- abstrações genéricas sem consumidor real.

## 8. Processo por tarefa
1. Ler docs relevantes.
2. Inspecionar código existente antes de propor novos tipos.
3. Escrever um plano curto da alteração.
4. Implementar a menor mudança coerente com a arquitetura.
5. Rodar testes e validações disponíveis.
6. Corrigir regressões.
7. Atualizar docs e manual quando a API/workflow mudar.
8. Entregar resumo com arquivos alterados, decisões, testes e pendências.

## 9. Compatibilidade
Não preserve arquitetura antiga apenas por compatibilidade se ela conflitar com a arquitetura GAS atual. Migre consumidores de forma controlada e remova caminhos obsoletos quando seguro.

## 10. Convenções de nomes
- Código, classes, arquivos, tags internas e IDs: inglês.
- Documentação para o projeto: português, salvo quando um termo técnico em inglês for mais claro.
- Classes: `PascalCase`.
- arquivos e métodos: `snake_case` conforme convenções Godot.
- gameplay tags: hierárquicas, por exemplo `State.Stunned`, `Ability.Attack.Light`, `Combat.Parry.Success`.

## 11. Definition of Done
Uma tarefa só está concluída quando:
- o comportamento pedido funciona;
- não viola as dependências;
- erros comuns são tratados;
- testes relevantes passam;
- não há warnings novos evitáveis;
- documentação necessária foi atualizada;
- existe instrução suficiente para Guilherme utilizar a feature sem alterar o core.

## 12. Política de skills
- Neste repositório, não carregar, ler, invocar nem seguir skills externas, pessoais, comunitárias ou fornecidas por plugins.
- As famílias `superpowers:*` e `impeccable` estão explicitamente desabilitadas para este projeto.
- Usar somente skills com escopo `SYSTEM` fornecidas nativamente pela OpenAI, além das ferramentas nativas disponíveis.
- Correspondência implícita de descrição ou instruções mandatórias contidas em uma skill externa não autorizam seu uso neste projeto.
- Não instalar, habilitar ou reativar uma skill externa neste projeto sem uma solicitação explícita do usuário para alterar esta política.
