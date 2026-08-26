# Manual — Criar uma Behaviour Tree

## Passos
1. Definir quais dados a IA realmente precisa no Blackboard.
2. Configurar Sensors que alimentam esses dados.
3. Criar branches de alta prioridade primeiro: dead/disabled, emergência, combate, reposicionamento.
4. Usar Conditions/Decorators para seleção tática.
5. Usar `ActivateAbility` para ações de gameplay.
6. Usar tasks de movimento para locomoção.
7. Evitar conditions duplicadas que já são responsabilidade de `GameplayAbility.can_activate()`.
8. Testar com debugger mostrando node atual e Blackboard.

## Princípio
BT escolhe **intenção**, não implementa mecânica.
