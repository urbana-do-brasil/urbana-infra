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
- `GCP_REGION`: Região do Google Cloud onde estão o Artifact Registry e o cluster GKE
- `GKE_CLUSTER_NAME`: Nome do cluster GKE

## Como Executar o Deploy

1. Acesse a aba "Actions" no repositório GitHub
2. Selecione o workflow "Deploy da API Gateway para GKE"
3. Clique em "Run workflow"
4. Preencha os parâmetros:
   - **image_tag**: Tag da imagem a ser implantada (ex: v1.0.0, latest, sha-do-commit)
   - **environment**: Ambiente para deploy (dev, staging, prod)
5. Clique em "Run workflow"

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

env:
  GCP_REGION: ${{ secrets.GCP_REGION }}
  GCP_PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  GKE_CLUSTER_NAME: ${{ secrets.GKE_CLUSTER_NAME }}
  NAMESPACE: whatsapp_chatbot
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

## Integração com Outros Workflows

Este workflow de deploy pode ser integrado com outros workflows, como:

1. **Build e Push da Imagem**: Outro workflow pode construir e publicar a imagem no Artifact Registry, e então acionar este workflow de deploy.

2. **Testes Automatizados**: Você pode adicionar testes automatizados antes do deploy para garantir a qualidade do código.

## Solução de Problemas

Se o workflow falhar, verifique:

1. **Imagem não encontrada**: Certifique-se de que a imagem com a tag especificada existe no Artifact Registry.

2. **Permissões insuficientes**: Verifique se a conta de serviço tem as permissões necessárias.

3. **Erros no Kubernetes**: Verifique os logs do workflow para identificar erros nos manifestos Kubernetes.

Para obter mais informações, execute:

```bash
# Verificar logs dos pods
kubectl logs -l app=api-gateway -n whatsapp_chatbot

# Verificar eventos do Kubernetes
kubectl get events -n whatsapp_chatbot
``` 