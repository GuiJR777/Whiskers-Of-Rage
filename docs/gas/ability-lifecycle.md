# Lifecycle de GameplayAbility

## Estados mínimos
```text
Granted → CanActivate → Activating → Active → Ending → Ended
                                    ↘ Cancelled
```

## Ativação
`try_activate()` deve:
1. localizar a ability concedida;
2. validar required/blocked tags;
3. validar custo;
4. validar cooldown;
5. construir/receber `AbilityContext`;
6. aplicar tags de ativação;
7. iniciar ability/tasks;
8. emitir eventos de lifecycle.

## Encerramento
Ao terminar ou cancelar:
- cancelar tasks pertencentes à ability;
- remover tags concedidas enquanto ativa;
- liberar locks internos;
- iniciar cooldown conforme política definida;
- emitir evento final;
- nunca deixar hitboxes/cues transitórios órfãos.

## Concorrência
A primeira versão deve suportar grupos simples de bloqueio/cancelamento por tags. Não criar scheduler complexo sem necessidade.

Exemplo:
`State.Attacking` pode bloquear outra ability ofensiva, enquanto uma ability de dodge pode declarar permissão de cancelar ataques específicos.
