# FCG (FIAP Cloud Games) - Infraestrutura e Orquestração

Este repositório contém as configurações e manifestos de infraestrutura necessários para orquestrar e executar os microsserviços do projeto **FCG (FIAP Cloud Games)**.

O projeto é composto por 5 microsserviços desenvolvidos em **.NET 10**:
1. **Users**: Gerenciamento de usuários e autenticação JWT.
2. **Catalog**: Catálogo de jogos, cache com Redis e início do fluxo de compra.
3. **Payments**: Worker de background para processamento de pagamentos das compras.
4. **CatalogWorkerService**: Worker de background para processamento de respostas de pagamentos e persistência de bibliotecas de jogos.
5. **Notifications**: Worker de background para envio de notificações e e-mails transacionais (SMTP).

---

## 🛠️ Tecnologias Utilizadas

- **.NET 10** como runtime principal das APIs e background workers.
- **RabbitMQ** como message broker para comunicação assíncrona orientada a eventos (utilizando **MassTransit**).
- **PostgreSQL** como banco de dados relacional (instância compartilhada com múltiplos databases isolados).
- **Redis** para caching distribuído de consultas de catálogo.
- **MongoDB** como banco de dados NoSQL para armazenamento de reviews do catálogo.
- **Kong** como API Gateway para roteamento, autenticação e controle de tráfego dos microsserviços.
- **Konga** como interface gráfica de gerenciamento do Kong.
- **Prometheus** para coleta e armazenamento de métricas.
- **Grafana** para visualização de métricas, logs e traces em dashboards.
- **Tempo** para rastreamento distribuído (traces) via OpenTelemetry (OTLP).
- **Loki** para agregação e consulta de logs.
- **Promtail** como agente coletor de logs para o Loki.
- **Docker Compose** para orquestração local rápida em ambiente de desenvolvimento.
- **Kubernetes** para deploy de infraestrutura compartilhada localmente (Kind, Minikube ou Docker Desktop).

---

## 📋 Pré-requisitos

Para rodar a infraestrutura localmente, você precisará ter instalado:
1. [Docker](https://www.docker.com/products/docker-desktop/) (incluindo Docker Compose).
2. [Kubectl](https://kubernetes.io/docs/tasks/tools/) (caso opte pelo deploy em Kubernetes).
3. Um cluster local Kubernetes como [Kind](https://kind.sigs.k8s.io/) ou [Minikube](https://minikube.sigs.k8s.io/) (opcional).

---

## 🐳 Executando com Docker Compose

O arquivo `docker-compose.yml` na raiz sobe os cinco microsserviços juntamente com os serviços de infraestrutura (PostgreSQL, RabbitMQ e Redis) totalmente integrados e com healthchecks.

### Passos para Iniciar
1. Execute o comando na raiz do repositório:
   ```bash
   docker compose up -d
   ```
2. Os bancos de dados (`users`, `notifications`, `catalog`, `payments`) serão criados e migrados automaticamente pelos próprios microsserviços (.NET migrations) em sua inicialização.

### Endereços Locais Importantes:
* **RabbitMQ Management UI**: [http://localhost:15672](http://localhost:15672) (Usuário: `fcg_user` | Senha: `fcg_password`)
* **PostgreSQL**: `localhost:5432` (Usuário: `fcg_user` | Senha: `fcg_password`)
* **Redis**: `localhost:6379`
* **MongoDB**: `localhost:27017` (Usuário: `fcg_user` | Senha: `fcg_password` | Database: `fcg_catalog`)
* **Users API**: [http://localhost:8081](http://localhost:8081)
* **Catalog API**: [http://localhost:8082](http://localhost:8082)
* **Prometheus**: [http://localhost:9090](http://localhost:9090)
* **Grafana**: [http://localhost:3000](http://localhost:3000) (Usuário: `admin` | Senha: `admin`)
* **Tempo**: `localhost:4317` (OTLP gRPC) | `localhost:3200` (Query)
* **Loki**: [http://localhost:3100](http://localhost:3100)
* **Promtail**: [http://localhost:9080](http://localhost:9080)
* **Kong (Proxy)**: [http://localhost:8000](http://localhost:8000)
* **Kong (Admin API)**: [http://localhost:8001](http://localhost:8001)
* **Konga**: [http://localhost:1337](http://localhost:1337)
* **Kong Database (PostgreSQL)**: `localhost:5433` (Usuário: `kong` | Senha: `kong` | Database: `kong`)
* *Nota: Os workers `CatalogWorkerService`, `Payments` e `Notifications` rodam como background workers e não expõem portas HTTP.*

---

## ☸️ Deploy no Kubernetes (k8s)

Os manifestos contidos na pasta `/k8s` sobem os serviços compartilhados de infraestrutura (PostgreSQL, RabbitMQ, Redis, MongoDB, Prometheus, Tempo, Loki, Promtail, Grafana, Kong e Konga) no namespace ativo (por padrão, `default`). A comunicação interna é realizada de forma transparente utilizando a resolução de nomes de serviço do Kubernetes (`rabbitmq:5672`, `postgres:5432`, `redis:6379`, `mongo:27017`, etc.).

### Subir a Infraestrutura

Para realizar o deploy completo da infraestrutura, execute o script `deploy.sh` na raiz do repositório:

```bash
./deploy.sh
```

O script `deploy.sh` aplica e aguarda cada serviço ficar disponível na seguinte ordem:

1. **RabbitMQ** — aplica os manifestos e aguarda o rollout.
2. **PostgreSQL** — aplica os manifestos e aguarda o rollout.
3. **Redis** — aplica os manifestos e aguarda o rollout.
4. **MongoDB** — aplica os manifestos e aguarda o rollout.
5. **Prometheus** — aplica `configmap.yaml` e `deployment.yaml` e aguarda o rollout.
6. **Tempo** — aplica os manifestos e aguarda o rollout.
7. **Logs (Loki + Promtail)** — aplica os manifestos da pasta `/k8s/logs`.
8. **Grafana** — aplica via Kustomize (`kubectl apply -k`) e aguarda o rollout.
9. **Kong / Konga** — aplica via Kustomize, executa as migrations, restaura o backup de configuração e sobe o Kong e o Konga.

Cada etapa utiliza `kubectl rollout status` com timeout para garantir que o serviço esteja realmente disponível antes de prosseguir para o próximo.

### Derrubar a Infraestrutura

Para descer e remover toda a infraestrutura, execute o script `down.sh` na raiz do repositório:

```bash
./down.sh
```

O script `down.sh` remove os recursos na ordem inversa e realiza a limpeza completa:

1. Remove **RabbitMQ**, **PostgreSQL**, **Redis**, **MongoDB**, **Tempo**, **Logs**, **Prometheus** e **Grafana**.
2. Remove o stack **Kong / Konga** via Kustomize.
3. Remove os jobs temporários (`kong-restore`, `kong-migrations`, `konga-prepare`).
4. Remove o **PVC** do PostgreSQL do Kong (`kong-postgres-pvc`).
5. Exibe um resumo dos recursos restantes no cluster.

---

## 📊 Observabilidade

O projeto conta com um stack completo de observabilidade (métricas, logs e traces) integrado à infraestrutura:

| Componente | Função | Endereço (Docker) |
| :--- | :--- | :--- |
| **Prometheus** | Coleta e armazenamento de métricas | [http://localhost:9090](http://localhost:9090) |
| **Grafana** | Dashboards e visualização de métricas, logs e traces | [http://localhost:3000](http://localhost:3000) |
| **Tempo** | Rastreamento distribuído (traces) via OpenTelemetry (OTLP) | `localhost:4317` (gRPC) / `localhost:3200` (Query) |
| **Loki** | Agregação e consulta de logs | [http://localhost:3100](http://localhost:3100) |
| **Promtail** | Agente coletor de logs que envia para o Loki | [http://localhost:9080](http://localhost:9080) |

### Fluxo de Observabilidade

- **Métricas**: Os serviços expõem métricas que são coletadas pelo **Prometheus** e visualizadas no **Grafana**.
- **Logs**: O **Promtail** coleta os logs dos containers e os envia para o **Loki**, que podem ser consultados no **Grafana**.
- **Traces**: Os microsserviços .NET enviam traces via OpenTelemetry (OTLP) para o **Tempo**, que também são visualizados no **Grafana**.

O **Grafana** já vem provisionado com os datasources de Prometheus, Loki e Tempo, além de dashboards pré-configurados.

---

## 🚪 API Gateway (Kong / Konga)

O projeto utiliza o **Kong** como API Gateway para roteamento, autenticação e controle de tráfego dos microsserviços, gerenciado através do **Konga**.

| Componente | Função | Endereço (Docker) |
| :--- | :--- | :--- |
| **Kong** | API Gateway (proxy, rate-limiting, autenticação) | Proxy: [http://localhost:8000](http://localhost:8000) / Admin API: [http://localhost:8001](http://localhost:8001) |
| **Konga** | Interface gráfica para gerenciamento do Kong | [http://localhost:1337](http://localhost:1337) |
| **Kong Database** | PostgreSQL dedicado ao Kong | `localhost:5433` (Usuário: `kong` | Senha: `kong` | Database: `kong`) |

### Configuração Inicial do Konga

Ao acessar o **Konga** pela primeira vez em [http://localhost:1337](http://localhost:1337), será necessário realizar a configuração inicial:

1. **Criar o usuário administrador** preenchendo o formulário de registro com:
   - **Username**: `admin`
   - **Password**: `admin123`
2. Após o login, **adicionar uma nova conexão** com o Kong informando a URL da Admin API:
   - **URL do Kong Admin**: `http://kong:8001`

> **Nota**: A URL `http://kong:8001` utiliza a resolução de nomes interna do Docker/Kubernetes, onde `kong` é o nome do serviço do Kong na rede. Isso garante que o Konga consiga se comunicar com o Kong Admin API de forma transparente.

---

## ⚙️ Variáveis de Ambiente dos Microsserviços

As seguintes variáveis de ambiente configuram a comunicação dos microsserviços .NET 10 com as dependências de infraestrutura:

### 1. Configurações Compartilhadas de Mensageria (MassTransit / RabbitMQ)

| Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- |
| `RabbitMQ__Host` | Endpoint do servidor RabbitMQ | `rabbitmq` ou `localhost` |
| `RabbitMQ__Username` | Nome do usuário do RabbitMQ | `fcg_user` |
| `RabbitMQ__Password` | Senha do usuário do RabbitMQ | `fcg_password` |
| `RabbitMQ__VirtualHost` | Virtual Host do RabbitMQ | `/` |

### 2. Configurações de Bancos de Dados por Serviço (PostgreSQL)

| Serviço | Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- | :--- |
| **Users** | `ConnectionStrings__DefaultConnection` | String de conexão com banco de dados `users` | `Host=fiapcloudgames;Database=users;Username=fcg_user;Password=fcg_password` |
| **CatalogWorkerService** | `ConnectionStrings__DefaultConnection` | String de conexão com banco de dados `catalog` | `Host=fiapcloudgames;Database=catalog;Username=fcg_user;Password=fcg_password` |
| **Catalog** | `ConnectionStrings__DefaultConnection` | String de conexão com banco de dados `catalog` | `Host=fiapcloudgames;Database=catalog;Username=fcg_user;Password=fcg_password` |
| **Payments** | `ConnectionStrings__DefaultConnection` | String de conexão com banco de dados `payments` | `Host=fiapcloudgames;Database=payments;Username=fcg_user;Password=fcg_password` |
| **Notifications** | `ConnectionStrings__DefaultConnection` | String de conexão com banco de dados `notifications` | `Host=fiapcloudgames;Database=notifications;Username=fcg_user;Password=fcg_password` |

### 3. Configurações de Filas e Chaves de Rota (RabbitMQ) por Serviço

| Serviço | Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- | :--- |
| **Payments** | `RabbitMQ__KeyQueueOrderPlaced` | Chave/Fila para consumo de pedidos criados | `order_placed` |
| **Payments** | `RabbitMQ__KeyPublisher` | Chave de roteamento para publicação do resultado do pagamento | `payment.processed` |
| **CatalogWorkerService** | `RabbitMQ__KeyQueuePaymentProcessed` | Chave/Fila para consumo de pagamentos processados | `payment.processed` |

### 4. Configurações de Cache Distribuído (Redis)

| Serviço | Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- | :--- |
| **Catalog** | `Redis__ConnectionString` | Endereço e porta de conexão do Redis | `redis:6379` |
| **Catalog** | `Redis__InstanceName` | Prefixo das chaves no Redis | `fcg:catalog:` |
| **Catalog** | `Redis__DefaultTtlMinutes` | TTL padrão do cache (em minutos) | `15` |

### 5. Configurações de Banco de Dados NoSQL (MongoDB)

| Serviço | Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- | :--- |
| **Catalog** | `MongoDB__ConnectionString` | String de conexão com o MongoDB | `mongodb://fcg_user:fcg_password@mongo:27017/fcg_catalog?authSource=admin` |
| **Catalog** | `MongoDB__DatabaseName` | Nome do banco de dados no MongoDB | `fcg_catalog` |
| **Catalog** | `MongoDB__ReviewsCollectionName` | Nome da collection de reviews | `reviews` |

### 6. Configurações de Segurança / JWT

| Serviço | Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- | :--- |
| **Users** | `Jwt__Key` | Chave secreta simétrica para assinatura dos tokens JWT | `sua_chave_secreta_com_mais_de_32_caracteres` |
| **Catalog** | `Jwt__SigningKey` | Chave secreta simétrica para validação dos tokens JWT | `sua_chave_secreta_com_mais_de_32_caracteres` |

### 7. Configurações de E-mail / SMTP (Notifications)

| Serviço | Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- | :--- |
| **Notifications** | `Smtp__Host` | Host do servidor SMTP | `smtp.gmail.com` |
| **Notifications** | `Smtp__Port` | Porta do servidor SMTP | `587` |
| **Notifications** | `Smtp__Username` | Usuário de autenticação SMTP | `exemplo@email.com` |
| **Notifications** | `Smtp__Password` | Senha ou Token de aplicativo SMTP | `suasenha` |
| **Notifications** | `Smtp__SenderName` | Nome de exibição do remetente | `Fiap Cloud Games` |
| **Notifications** | `Smtp__SenderEmail` | E-mail do remetente | `exemplo@email.com` |

### 8. Configurações de Observabilidade (OpenTelemetry / Tempo)

| Serviço | Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- | :--- |
| **Users** | `OTEL_EXPORTER_OTLP_ENDPOINT` | Endpoint OTLP do Tempo para envio de traces | `http://tempo:4317` |
| **Catalog** | `OTEL_EXPORTER_OTLP_ENDPOINT` | Endpoint OTLP do Tempo para envio de traces | `http://tempo:4317` |
