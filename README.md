# Infraestrutura para API do WhatsApp Business

Este projeto contém a infraestrutura necessária para implantar uma API que se integra com o webhook da API do WhatsApp Business em um cluster Kubernetes no Google Cloud Platform (GCP).

## Requisitos

- Conta no Google Cloud Platform
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/intro/install/)

## Estrutura do Projeto

```
.
├── Dockerfile                # Dockerfile para a aplicação Spring Boot
├── k8s/                      # Manifestos Kubernetes
│   ├── api-gateway-deployment.yaml
│   ├── api-gateway-service.yaml
│   ├── namespace.yaml
│   └── network-policy.yaml   # Política de rede para segurança
├── terraform/                # Configuração Terraform
│   ├── cluster/              # Configuração do cluster GKE
│   ├── crds/                 # Custom Resource Definitions (cert-manager)
│   └── manifests/            # Recursos Kubernetes gerenciados pelo Terraform
│       ├── main.tf           # Recursos principais (secrets, ingress, etc.)
│       ├── monitoring.tf     # Configuração de monitoramento (Prometheus, Grafana, Loki)
│       └── backup.tf         # Configuração de backup (Velero)
└── .github/                  # Configurações do GitHub
    └── workflows/            # Workflows do GitHub Actions
        └── deploy.yml        # Pipeline de deploy para GKE
```

## Passo a Passo para Implantação

### 1. Configuração do Ambiente

```bash
# Autenticar no Google Cloud
gcloud auth login

# Configurar o projeto
gcloud config set project SEU_PROJETO_GCP

# Habilitar as APIs necessárias
gcloud services enable container.googleapis.com compute.googleapis.com
```

### 2. Provisionar o Cluster Kubernetes

```bash
# Navegar para o diretório do cluster
cd terraform/cluster

# Inicializar o Terraform
terraform init

# Planejar a implantação
terraform plan -out=plan.out -var="project_id=SEU_PROJETO_GCP" -var="region=SUA_REGIAO"

# Aplicar a configuração
terraform apply plan.out
```

### 3. Configurar o kubectl para o cluster

```bash
gcloud container clusters get-credentials SEU_CLUSTER_NAME --region=SUA_REGIAO --project=SEU_PROJETO_GCP
```

### 4. Instalar o cert-manager e configurar o ClusterIssuer

```bash
# Navegar para o diretório de CRDs
cd ../crds

# Inicializar o Terraform
terraform init

# Planejar a implantação
terraform plan -out=plan.out \
  -var="email_for_lets_encrypt=seu-email@exemplo.com" \
  -var="project_id=SEU_PROJETO_GCP" \
  -var="region=SUA_REGIAO" \
  -var="cluster_name=SEU_CLUSTER_NAME"

# Aplicar a configuração
terraform apply plan.out
```

### 5. Gerenciamento da Imagem Docker

Existem várias opções para gerenciar a imagem Docker da aplicação:

#### Opção 1: Usar uma imagem existente no GCR/Artifact Registry

Se você já tem uma imagem Docker pronta no Google Container Registry (GCR) ou Artifact Registry:

```bash
# Verificar se a imagem existe
gcloud container images list-tags gcr.io/SEU_PROJETO_GCP/api-gateway

# Atualizar o manifesto de deployment para usar sua imagem existente
sed -i 's|IMAGE_URL|gcr.io/SEU_PROJETO_GCP/api-gateway:latest|g' k8s/api-gateway-deployment.yaml
```

#### Opção 2: Construir e publicar uma nova imagem

Se você precisa construir a imagem a partir do código-fonte:

```bash
# Construir a imagem Docker
docker build -t gcr.io/SEU_PROJETO_GCP/api-gateway:latest .

# Autenticar no Google Container Registry
gcloud auth configure-docker

# Publicar a imagem no GCR
docker push gcr.io/SEU_PROJETO_GCP/api-gateway:latest

# Atualizar o manifesto de deployment
sed -i 's|IMAGE_URL|gcr.io/SEU_PROJETO_GCP/api-gateway:latest|g' k8s/api-gateway-deployment.yaml
```

#### Opção 3: Automatizar com Cloud Build

Para uma abordagem mais automatizada:

```bash
# Criar um arquivo cloudbuild.yaml
cat > cloudbuild.yaml <<EOF
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', 'gcr.io/\$PROJECT_ID/api-gateway:latest', '.']
images:
- 'gcr.io/\$PROJECT_ID/api-gateway:latest'
EOF

# Executar o Cloud Build
gcloud builds submit --config=cloudbuild.yaml

# Atualizar o manifesto de deployment
sed -i 's|IMAGE_URL|gcr.io/\$PROJECT_ID/api-gateway:latest|g' k8s/api-gateway-deployment.yaml
```

### 6. Implantar a Aplicação e Configurar o Ingress

```bash
# Navegar para o diretório de manifestos
cd ../manifests

# Inicializar o Terraform
terraform init

# Planejar a implantação
terraform plan -out=plan.out \
  -var="domain_name=seu-dominio.com" \
  -var="gemini_api_key=SUA_API_KEY" \
  -var="whatsapp_token=SEU_TOKEN_WHATSAPP" \
  -var="grafana_admin_password=SUA_SENHA_GRAFANA" \
  -var="project_id=SEU_PROJETO_GCP" \
  -var="region=SUA_REGIAO"

# Aplicar a configuração
terraform apply plan.out
```

### 7. Configurar o DNS

Após a implantação, você receberá o endereço IP do balanceador de carga. Configure seu domínio para apontar para este IP:

```bash
# Obter o IP do balanceador de carga
kubectl get ingress api-gateway-ingress -n whatsapp_chatbot -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Configure um registro A no seu provedor de DNS apontando seu domínio para este IP.

### 8. Configurar o Webhook do WhatsApp Business

1. Acesse o [Facebook Developer Portal](https://developers.facebook.com/)
2. Navegue até seu aplicativo WhatsApp Business
3. Vá para "Configurações" > "WhatsApp" > "Webhooks"
4. Configure o URL do webhook como `https://seu-dominio.com/webhook`
5. Configure o token de verificação (o mesmo usado na variável `whatsapp_token`)
6. Selecione os eventos que deseja receber (mensagens, status de entrega, etc.)
7. Clique em "Verificar e Salvar"

## CI/CD com GitHub Actions

Este projeto inclui uma pipeline de CI/CD usando GitHub Actions para automatizar o deploy da aplicação no cluster GKE.

### Configuração do GitHub Actions

1. Configure os seguintes secrets no seu repositório GitHub:
   - `GCP_SA_KEY`: Conteúdo JSON da chave de conta de serviço do Google Cloud
   - `GCP_PROJECT_ID`: ID do projeto no Google Cloud
   - `GCP_REGION`: Região do Google Cloud
   - `GKE_CLUSTER_NAME`: Nome do cluster GKE

2. Para executar o deploy:
   - Acesse a aba "Actions" no repositório GitHub
   - Selecione o workflow "Deploy da API Gateway para GKE"
   - Clique em "Run workflow"
   - Preencha a tag da imagem e o ambiente de destino
   - Clique em "Run workflow"

### Funcionamento da Pipeline

A pipeline de deploy:
1. Verifica se a imagem Docker especificada existe no Artifact Registry
2. Atualiza os manifestos Kubernetes com a imagem correta
3. Aplica os manifestos no cluster GKE
4. Verifica o status do rollout
5. Exibe informações sobre o deployment

Para mais detalhes, consulte o arquivo [.github/README-CICD.md](.github/README-CICD.md).

## Monitoramento e Logging

O projeto inclui:

- **Prometheus**: Para coleta de métricas
- **Grafana**: Para visualização de métricas
- **Loki**: Para coleta e consulta de logs

Acesse o Grafana em `https://seu-dominio.com/grafana` usando as credenciais configuradas.

## Backup e Recuperação

O projeto inclui o Velero para backup e recuperação de desastres:

```bash
# Verificar status dos backups
kubectl get backups -n velero

# Criar um backup manual
kubectl create -f - <<EOF
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: manual-backup
  namespace: velero
spec:
  includedNamespaces:
  - whatsapp_chatbot
  ttl: 240h
EOF

# Restaurar a partir de um backup
kubectl create -f - <<EOF
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: restore-from-backup
  namespace: velero
spec:
  backupName: manual-backup
EOF
```

## Segurança

- A comunicação é protegida por HTTPS usando certificados Let's Encrypt
- Secrets do Kubernetes são usados para armazenar informações sensíveis
- O Ingress é configurado para seguir as melhores práticas de segurança
- Network Policies restringem o tráfego de rede entre os pods

## Escalabilidade

- O deployment está configurado com múltiplas réplicas
- Configuração de recursos (CPU/memória) otimizada
- Afinidade de pods para distribuição em diferentes nós

## Solução de Problemas

### Verificar logs da aplicação

```bash
kubectl logs -f -l app=api-gateway -n whatsapp_chatbot
```

### Verificar status do certificado

```bash
kubectl get certificate -n whatsapp_chatbot
```

### Verificar status do Ingress

```bash
kubectl describe ingress api-gateway-ingress -n whatsapp_chatbot
```

### Verificar Network Policies

```bash
kubectl describe networkpolicy api-gateway-network-policy -n whatsapp_chatbot
``` 