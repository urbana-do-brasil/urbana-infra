# CI/CD com GitHub Actions

Este documento descreve como utilizar o GitHub Actions para realizar o deploy da aplicação API Gateway no cluster GKE.

## Visão Geral

O pipeline de CI/CD está configurado para:

1. Verificar se a imagem Docker especificada existe no Artifact Registry
2. Atualizar os manifestos Kubernetes com a imagem correta
3. Aplicar os manifestos no cluster GKE
4. Verificar o status do rollout
5. Exibir informações sobre o deployment

## Pré-requisitos

Para que o pipeline funcione corretamente, você precisa configurar os seguintes secrets no seu repositório GitHub:

- `GCP_SA_KEY`: Conteúdo JSON da chave de conta de serviço do Google Cloud com permissões para:
  - Artifact Registry (roles/artifactregistry.reader)
  - GKE (roles/container.developer)
- `GCP_PROJECT_ID`: ID do projeto no Google Cloud
- `GCP_REGION`: (Opcional) Região do Google Cloud onde estão o Artifact Registry e o cluster GKE
- `GKE_CLUSTER_NAME`: (Opcional) Nome do cluster GKE

### Permissões Necessárias para a Conta de Serviço

A conta de serviço usada pelo GitHub Actions (referenciada em `GCP_SA_KEY`) deve ter as seguintes permissões:

1. **Para acessar o GKE**:
   - `container.clusters.get`
   - `container.clusters.list`
   - `container.deployments.get`
   - `container.deployments.create`
   - `container.deployments.update`
   - `container.pods.get`
   - `container.pods.list`
   - `container.services.get`
   - `container.services.list`
   - `container.services.update`

2. **Para acessar o Artifact Registry**:
   - `artifactregistry.repositories.get`
   - `artifactregistry.repositories.list`
   - `artifactregistry.repositories.downloadArtifacts`

Você pode conceder essas permissões atribuindo os seguintes papéis (roles) à conta de serviço:
- `roles/container.developer`
- `roles/artifactregistry.reader`

Para conceder esses papéis, execute:

```bash
# Substitua [PROJECT_ID] pelo ID do seu projeto
# Substitua [SERVICE_ACCOUNT_EMAIL] pelo email da sua conta de serviço

gcloud projects add-iam-policy-binding [PROJECT_ID] \
  --member="serviceAccount:[SERVICE_ACCOUNT_EMAIL]" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding [PROJECT_ID] \
  --member="serviceAccount:[SERVICE_ACCOUNT_EMAIL]" \
  --role="roles/artifactregistry.reader"
```

## Como Executar o Deploy

1. Acesse a aba "Actions" no repositório GitHub
2. Selecione o workflow "Deploy da API Gateway para GKE"
3. Clique em "Run workflow"
4. Preencha os parâmetros:
   - **image_tag**: Tag da imagem a ser implantada (ex: v1.0.0, latest, sha-do-commit)
   - **environment**: Ambiente para deploy (dev, staging, prod)
   - **gcp_region**: (Opcional) Região do GCP (ex: us-central1)
   - **gke_cluster_name**: (Opcional) Nome do cluster GKE
5. Clique em "Run workflow"

> **Nota**: Se não forem fornecidos valores para `gcp_region` e `gke_cluster_name`, o workflow tentará usar os valores dos secrets correspondentes. Para `gcp_region`, se o secret também estiver vazio, será usado o valor padrão "us-central1".

## Estrutura do Workflow

```yaml
name: Deploy da API Gateway para GKE

on:
  workflow_dispatch:
    inputs:
      image_tag:
        description: 'Tag da imagem a ser implantada (ex: v1.0.0, latest, sha-do-commit)'
        required: true
        default: 'latest'
      environment:
        description: 'Ambiente para deploy (prod, staging, dev)'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - staging
          - prod
      gcp_region:
        description: 'Região do GCP (ex: us-central1)'
        required: false
        default: 'us-central1'
      gke_cluster_name:
        description: 'Nome do cluster GKE'
        required: false

env:
  GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  NAMESPACE: whatsapp-chatbot
  ARTIFACT_REGISTRY_REPO: api-gateway
  IMAGE_NAME: api-gateway

jobs:
  deploy:
    name: Deploy para ${{ github.event.inputs.environment }}
    runs-on: ubuntu-latest
    # ... restante do workflow
```

## Verificação da Imagem

O workflow verifica se a imagem especificada existe no Artifact Registry antes de prosseguir com o deploy:

```yaml
- name: Verificar se a imagem existe no Artifact Registry
  id: check_image
  run: |
    IMAGE_PATH="${{ env.GCP_REGION }}-docker.pkg.dev/${{ env.GCP_PROJECT_ID }}/${{ env.ARTIFACT_REGISTRY_REPO }}/${{ env.IMAGE_NAME }}:${{ github.event.inputs.image_tag }}"
    
    if gcloud artifacts docker images describe $IMAGE_PATH > /dev/null 2>&1; then
      echo "A imagem $IMAGE_PATH existe no Artifact Registry."
      echo "image_exists=true" >> $GITHUB_OUTPUT
    else
      echo "ERRO: A imagem $IMAGE_PATH não existe no Artifact Registry."
      echo "image_exists=false" >> $GITHUB_OUTPUT
      exit 1
    fi
```

## Definição de Variáveis de Ambiente

O workflow inclui uma etapa para definir corretamente as variáveis de região e nome do cluster:

```yaml
- name: Definir variáveis de região e cluster
  id: set_vars
  run: |
    # Definir a região do GCP
    GCP_REGION="${{ github.event.inputs.gcp_region }}"
    if [ -z "$GCP_REGION" ]; then
      GCP_REGION="${{ secrets.GCP_REGION }}"
      if [ -z "$GCP_REGION" ]; then
        GCP_REGION="us-central1"  # Valor padrão
      fi
    fi
    echo "GCP_REGION=$GCP_REGION" >> $GITHUB_ENV
    
    # Definir o nome do cluster GKE
    GKE_CLUSTER_NAME="${{ github.event.inputs.gke_cluster_name }}"
    if [ -z "$GKE_CLUSTER_NAME" ]; then
      GKE_CLUSTER_NAME="${{ secrets.GKE_CLUSTER_NAME }}"
      if [ -z "$GKE_CLUSTER_NAME" ]; then
        echo "ERRO: Nome do cluster GKE não fornecido. Forneça via input ou secret GKE_CLUSTER_NAME."
        exit 1
      fi
    fi
    echo "GKE_CLUSTER_NAME=$GKE_CLUSTER_NAME" >> $GITHUB_ENV
```

## Integração com Outros Workflows

Este workflow de deploy pode ser integrado com outros workflows, como:

1. **Build e Push da Imagem**: Outro workflow pode construir e publicar a imagem no Artifact Registry, e então acionar este workflow de deploy.

2. **Testes Automatizados**: Você pode adicionar testes automatizados antes do deploy para garantir a qualidade do código.

## Configuração de Acesso ao Artifact Registry

Para que o cluster GKE possa baixar imagens do Artifact Registry, é necessário configurar as permissões adequadas. O workflow inclui uma etapa para isso:

```yaml
- name: Configurar acesso do GKE ao Artifact Registry
  run: |
    # Criar um secret do tipo docker-registry para autenticação no Artifact Registry
    ACCESS_TOKEN=$(gcloud auth print-access-token)
    kubectl create secret docker-registry gcr-json-key \
      --namespace=${{ env.NAMESPACE }} \
      --docker-server=${{ env.GCP_REGION }}-docker.pkg.dev \
      --docker-username=oauth2accesstoken \
      --docker-password="$ACCESS_TOKEN" \
      --docker-email=not-needed@example.com \
      -o yaml --dry-run=client | kubectl apply -f -
    
    # Adicionar o secret à conta de serviço default
    kubectl patch serviceaccount default \
      -n ${{ env.NAMESPACE }} \
      -p '{"imagePullSecrets": [{"name": "gcr-json-key"}]}' \
      --type=merge
```

Além disso, o deployment deve ser configurado para usar este secret:

```yaml
spec:
  imagePullSecrets:
  - name: gcr-json-key
  containers:
  - name: api-gateway
    # ...
```

### Configuração Manual

Se você precisar configurar o acesso manualmente, siga estes passos:

1. **Obtenha um token de acesso**:
   ```bash
   ACCESS_TOKEN=$(gcloud auth print-access-token)
   ```

2. **Crie um secret com o token de acesso**:
   ```bash
   kubectl create secret docker-registry gcr-json-key \
     --namespace=whatsapp-chatbot \
     --docker-server=us-central1-docker.pkg.dev \
     --docker-username=oauth2accesstoken \
     --docker-password="$ACCESS_TOKEN" \
     --docker-email=not-needed@example.com
   ```

3. **Adicione o secret à conta de serviço**:
   ```bash
   kubectl patch serviceaccount default \
     -n whatsapp-chatbot \
     -p '{"imagePullSecrets": [{"name": "gcr-json-key"}]}'
   ```

4. **Verifique se o secret foi criado corretamente**:
   ```bash
   kubectl get secret gcr-json-key -n whatsapp-chatbot
   ```

> **Nota**: O token de acesso gerado por `gcloud auth print-access-token` tem validade limitada (geralmente 1 hora). Para ambientes de produção, considere implementar uma solução mais permanente, como o Workload Identity Federation.

## Solução de Problemas

### Problemas Comuns de Deployment

Se o workflow falhar, verifique os seguintes problemas comuns:

1. **Imagem não encontrada**: Certifique-se de que a imagem com a tag especificada existe no Artifact Registry.

2. **Permissões insuficientes**: Verifique se a conta de serviço tem as permissões necessárias.

3. **Erros no Kubernetes**: Verifique os logs do workflow para identificar erros nos manifestos Kubernetes.

4. **Variáveis de ambiente vazias**: Certifique-se de que as variáveis `GCP_REGION` e `GKE_CLUSTER_NAME` estão definidas corretamente.

5. **Problemas de acesso ao Artifact Registry**: Se você encontrar erros como `ImagePullBackOff` ou `403 Forbidden` ao tentar baixar imagens, isso indica problemas de permissão:
   - Verifique se a conta de serviço do GKE tem permissão para acessar o Artifact Registry
   - Confirme se o secret `gcr-json-key` foi criado corretamente no namespace
   - Verifique se o deployment está configurado para usar o secret através de `imagePullSecrets`
   - Certifique-se de que o repositório no Artifact Registry não tem restrições de acesso que bloqueiam o cluster GKE

6. **Timeout no rollout**: Se o deployment não completar dentro do tempo limite, pode haver problemas com:
   - **Health checks**: Os probes de liveness, readiness ou startup podem estar falhando
   - **Recursos insuficientes**: O cluster pode não ter CPU ou memória suficientes
   - **Secrets ausentes**: Verifique se os secrets necessários existem no namespace
   - **Problemas na aplicação**: A aplicação pode estar falhando ao inicializar

7. **Falhas no Startup Probe**: Se você vir erros como `Startup probe failed: context deadline exceeded`, isso indica que a aplicação está demorando mais do que o esperado para inicializar:
   - Aumente o `initialDelaySeconds` para dar mais tempo antes de começar a verificar
   - Aumente o `failureThreshold` para permitir mais tentativas antes de considerar o pod como falho
   - Aumente o `periodSeconds` para verificar com menos frequência
   - Aumente o `timeoutSeconds` para dar mais tempo para cada verificação responder

   Exemplo de configuração mais tolerante para aplicações Spring Boot:
   ```yaml
   startupProbe:
     failureThreshold: 30
     httpGet:
       path: /actuator/health
       port: 8080
     initialDelaySeconds: 90
     periodSeconds: 20
     successThreshold: 1
     timeoutSeconds: 5
   ```

   Isso dá à aplicação aproximadamente 10 minutos (90s + 30 * 20s) para inicializar completamente.

### Diagnóstico Automático

O workflow inclui uma etapa de diagnóstico automático que é executada quando o rollout falha. Esta etapa coleta informações detalhadas sobre o estado do deployment, incluindo:

- Status dos pods
- Descrição detalhada dos pods
- Eventos do namespace
- Logs dos pods
- Status do deployment
- Secrets e ConfigMaps disponíveis
- Serviços e Ingress
- Utilização de recursos do cluster

Estas informações são exibidas nos logs do workflow e podem ajudar a identificar a causa do problema.

### Verificação Manual

Para verificar manualmente o status do deployment após a execução do workflow, você pode executar os seguintes comandos:

```bash
# Verificar status dos pods
kubectl get pods -l app=api-gateway -n whatsapp-chatbot

# Verificar detalhes de um pod específico
kubectl describe pod [NOME_DO_POD] -n whatsapp-chatbot

# Verificar logs de um pod
kubectl logs [NOME_DO_POD] -n whatsapp-chatbot

# Verificar eventos do namespace
kubectl get events -n whatsapp-chatbot --sort-by='.lastTimestamp'

# Verificar status do deployment
kubectl describe deployment api-gateway -n whatsapp-chatbot

# Verificar se os secrets existem
kubectl get secrets -n whatsapp-chatbot
```

### Ajustes nos Health Checks

Se os pods estiverem falhando devido a problemas com os health checks, você pode ajustar os parâmetros no arquivo `k8s/api-gateway-deployment.yaml`:

```yaml
livenessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 120  # Aumentar se a aplicação demorar para inicializar
  periodSeconds: 20
  timeoutSeconds: 10
  failureThreshold: 5

readinessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 15
  timeoutSeconds: 10
  failureThreshold: 5
```

### Verificação de Recursos

Para verificar se o cluster tem recursos suficientes:

```bash
# Verificar utilização de recursos dos nós
kubectl top nodes

# Verificar utilização de recursos dos pods
kubectl top pods -n whatsapp-chatbot
```

### Comportamento em Ambientes de Produção vs. Não-Produção

O workflow está configurado para tratar falhas de deployment de forma diferente dependendo do ambiente:

- Em ambientes de **produção**, o workflow falhará se o deployment não for concluído com sucesso
- Em ambientes de **não-produção** (dev, staging), o workflow continuará mesmo se houver problemas no deployment

Isso permite que você veja os resultados do diagnóstico em ambientes de desenvolvimento sem interromper o workflow. 