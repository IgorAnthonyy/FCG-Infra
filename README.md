# FCG (FIAP Cloud Games) - Infraestrutura e Orquestração

Este repositório contém as configurações e manifestos de infraestrutura necessários para orquestrar e executar os microsserviços do projeto **FCG (FIAP Cloud Games)**.

O projeto é composto por 5 microsserviços desenvolvidos em **.NET 10**:
1. **Users**: Gerenciamento de usuários.
2. **Catalog**: Catálogo de jogos e início do fluxo de compra.
3. **Payments**: Worker de background para processamento de pagamentos das compras.
4. **CatalogWorkerService**: Worker de background para processamento de respostas de pagamentos e persistência de bibliotecas de jogos.
5. **Notifications**: Worker de background para envio de notificações e e-mails transacionais.

---

## 🛠️ Tecnologias Utilizadas

- **.NET 10** como runtime principal das APIs.
- **RabbitMQ** como message broker para comunicação assíncrona orientada a eventos (utilizando **MassTransit**).
- **PostgreSQL** como banco de dados relacional (instância compartilhada com múltiplos databases isolados).
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

O arquivo `docker-compose.yml` na raiz sobe os cinco microsserviços juntamente com o banco de dados PostgreSQL e o RabbitMQ pré-configurados.

### Passos para Iniciar
1. Execute o comando na raiz do repositório:
   ```bash
   docker-compose up -d
   ```
2. Os bancos de dados (`users`, `library`, `catalog`, `payments`) serão criados e migrados automaticamente pelos próprios microsserviços (.NET migrations) em sua inicialização.

### Endereços Locais Importantes:
*   **RabbitMQ Management UI**: [http://localhost:15672](http://localhost:15672) (Usuário: `fcg_user` | Senha: `fcg_password`)
*   **PostgreSQL**: `localhost:5432` (Usuário: `fcg_user` | Senha: `fcg_password`)
*   **Users**: `http://localhost:8081`
*   **Catalog**: `http://localhost:8082`
*   *Nota: Os workers `CatalogWorkerService`, `Payments` e `Notifications` rodam como background workers e não expõem portas HTTP de forma padrão.*

---

## ☸️ Deploy no Kubernetes (k8s)

Os manifestos contidos na pasta `/k8s` sobem os serviços compartilhados de infraestrutura (PostgreSQL e RabbitMQ) no namespace ativo (por padrão, `default`). A comunicação interna é realizada de forma transparente utilizando a resolução de nomes interna do Kubernetes (`rabbitmq:5672` e `postgres:5432`).

### Ordem de Deploy
1. **RabbitMQ**:
   ```bash
   kubectl apply -f k8s/rabbitmq/
   ```
2. **PostgreSQL**:
   ```bash
   kubectl apply -f k8s/postgres/
   ```

Ou aplique recursivamente apontando para a pasta raiz `k8s`:
```bash
kubectl apply -R -f k8s/
```

---

## ⚙️ Variáveis de Ambiente dos Microsserviços

As seguintes variáveis de ambiente configuram a comunicação dos microsserviços .NET 10 com o PostgreSQL e RabbitMQ (MassTransit):

### Configurações Compartilhadas de Mensageria (MassTransit)

| Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- |
| `RabbitMQ__Host` | Endpoint do servidor RabbitMQ | `rabbitmq` ou `localhost` |
| `RabbitMQ__Username` | Nome do usuário do RabbitMQ | `fcg_user` |
| `RabbitMQ__Password` | Senha do usuário do RabbitMQ | `fcg_password` |

### Configurações de Bancos de Dados por Serviço

| Serviço | Nome da Variável | Descrição | Exemplo de Valor |
| :--- | :--- | :--- | :--- |
| **Users** | `ConnectionStrings__DefaultConnection` | String de conexão com banco de dados `users` | `Host=fiapcloudgames;Database=users;Username=fcg_user;Password=fcg_password` |
| **CatalogWorkerService** | `ConnectionStrings__DefaultConnection` | String de conexão com banco de dados `library` | `Host=fiapcloudgames;Database=library;Username=fcg_user;Password=fcg_password` |
| **Catalog** | `ConnectionStrings__DefaultConnection` | String de conexão com banco de dados `catalog` | `Host=fiapcloudgames;Database=catalog;Username=fcg_user;Password=fcg_password` |
| **Payments** | `ConnectionStrings__DefaultConnection` | String de conexão com banco de dados `payments` | `Host=fiapcloudgames;Database=payments;Username=fcg_user;Password=fcg_password` |
| **Notifications** | *Nenhum banco de dados configurado* | Consome eventos RabbitMQ apenas | - |