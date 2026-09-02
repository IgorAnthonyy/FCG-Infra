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
* **Users API**: [http://localhost:8081](http://localhost:8081)
* **Catalog API**: [http://localhost:8082](http://localhost:8082)
* *Nota: Os workers `CatalogWorkerService`, `Payments` e `Notifications` rodam como background workers e não expõem portas HTTP.*

---

## ☸️ Deploy no Kubernetes (k8s)

Os manifestos contidos na pasta `/k8s` sobem os serviços compartilhados de infraestrutura (PostgreSQL, RabbitMQ e Redis) no namespace ativo (por padrão, `default`). A comunicação interna é realizada de forma transparente utilizando a resolução de nomes de serviço do Kubernetes (`rabbitmq:5672`, `postgres:5432` e `redis:6379`).

### Ordem de Deploy Individual
1. **RabbitMQ**:
   ```bash
   kubectl apply -f k8s/rabbitmq/
   ```
2. **PostgreSQL**:
   ```bash
   kubectl apply -f k8s/postgres/
   ```
3. **Redis**:
   ```bash
   kubectl apply -f k8s/redis/
   ```

### Ou Deploy Recursivo:
```bash
kubectl apply -R -f k8s/
```

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

### 5. Configurações de Segurança / JWT

| Serviço | Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- | :--- |
| **Users** | `Jwt__Key` | Chave secreta simétrica para assinatura dos tokens JWT | `sua_chave_secreta_com_mais_de_32_caracteres` |
| **Catalog** | `Jwt__SigningKey` | Chave secreta simétrica para validação dos tokens JWT | `sua_chave_secreta_com_mais_de_32_caracteres` |

### 6. Configurações de E-mail / SMTP (Notifications)

| Serviço | Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- | :--- |
| **Notifications** | `Smtp__Host` | Host do servidor SMTP | `smtp.gmail.com` |
| **Notifications** | `Smtp__Port` | Porta do servidor SMTP | `587` |
| **Notifications** | `Smtp__Username` | Usuário de autenticação SMTP | `exemplo@email.com` |
| **Notifications** | `Smtp__Password` | Senha ou Token de aplicativo SMTP | `suasenha` |
| **Notifications** | `Smtp__SenderName` | Nome de exibição do remetente | `Fiap Cloud Games` |
| **Notifications** | `Smtp__SenderEmail` | E-mail do remetente | `exemplo@email.com` |
