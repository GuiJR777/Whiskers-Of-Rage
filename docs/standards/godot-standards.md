# Padrões Godot 4.7+

## Linguagem
GDScript fortemente tipado por padrão.

## Nodes vs Resources
Use Node para comportamento/estado ligado à SceneTree.
Use Resource para definições data-driven e compartilháveis.
Use RefCounted para objetos runtime leves que não precisam de Node lifecycle.

## Signals
- declarar tipos quando suportado;
- conectar/desconectar com lifecycle claro;
- evitar signal spaghetti;
- preferir signal local ao bus global.

## Editor
Ferramentas customizadas devem usar `EditorPlugin`, inspectors/plugins próprios quando isso realmente melhora o fluxo.

## Performance
- evitar alocações contínuas em `_process`;
- evitar `get_nodes_in_group()` e scans globais em hot paths;
- sensores e targeting devem usar Physics queries/Areas/timers com parcimônia;
- perfis antes de micro-otimizar.

## Resources runtime
Nunca mutar um Resource compartilhado para armazenar cooldown, stacks ou valor atual. Criar runtime specs/instances.

## Erros
APIs públicas devem falhar de forma legível. Preferir assertions para invariantes de desenvolvimento e erros/warnings claros para configuração inválida de editor.
