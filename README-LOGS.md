# Monitoramento de Logs no Kubernetes

Este documento contém comandos úteis para monitoramento de logs no ambiente Kubernetes.

## Comandos Básicos

### 1. Ver logs de um pod específico
```bash
kubectl logs -n <namespace> <nome-do-pod>
```

### 2. Ver logs de todos os pods com uma label específica
```bash
kubectl logs -n <namespace> -l app=<nome-da-aplicação>
```

### 3. Ver logs em tempo real (streaming)
```bash
kubectl logs -n <namespace> <nome-do-pod> -f
```

### 4. Limitar a quantidade de linhas exibidas
```bash
kubectl logs -n <namespace> <nome-do-pod> --tail=<número-de-linhas>
```

### 5. Ver logs de um período específico
```bash
kubectl logs -n <namespace> <nome-do-pod> --since=1h  # Logs da última hora
kubectl logs -n <namespace> <nome-do-pod> --since=15m # Logs dos últimos 15 minutos
kubectl logs -n <namespace> <nome-do-pod> --since-time="2023-03-01T10:00:00Z" # Logs desde uma data/hora específica
```

## Filtragem de Logs

### 1. Filtrar logs por palavra-chave
```bash
kubectl logs -n <namespace> <nome-do-pod> | grep "<palavra-chave>"
```

### 2. Filtrar logs de erro ou avisos
```bash
kubectl logs -n <namespace> <nome-do-pod> | grep -i "error\|warn\|exception"
```

### 3. Filtrar logs de requisições HTTP
```bash
kubectl logs -n <namespace> <nome-do-pod> | grep -i "http\|request\|response"
```

### 4. Monitoramento em tempo real com filtros
```bash
kubectl logs -n <namespace> <nome-do-pod> -f | grep "<palavra-chave>" --color
```

## Comandos Específicos para a API Gateway

### 1. Ver logs de todos os pods da API Gateway
```bash
kubectl logs -n whatsapp-chatbot -l app=api-gateway
```

### 2. Monitorar logs de webhook em tempo real
```bash
kubectl logs -n whatsapp-chatbot -l app=api-gateway -f | grep -i webhook --color
```

### 3. Verificar mensagens recebidas
```bash
kubectl logs -n whatsapp-chatbot -l app=api-gateway | grep -i "mensagem recebida"
```

### 4. Verificar erros na API Gateway
```bash
kubectl logs -n whatsapp-chatbot -l app=api-gateway | grep -i "error\|exception\|warn"
```

## Dicas Adicionais

1. Use `--all-containers=true` para ver logs de todos os contêineres em um pod
2. Combine comandos com `|` para filtrar e processar a saída
3. Use `--previous` para ver logs de uma instância anterior do contêiner (útil após reinicializações)
4. Para logs mais detalhados sobre eventos do Kubernetes, use `kubectl get events -n <namespace>` 