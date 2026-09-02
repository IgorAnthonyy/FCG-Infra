#!/bin/bash

set -e

echo "======================================"
echo "Aplicando infraestrutura..."
echo "======================================"

echo "Aplicando rabbitmq"

kubectl apply -f ./k8s/rabbitmq

echo "Aguardando rabbitmq ficar disponivel"

kubectl rollout status \
  deployment/rabbitmq \
  --timeout=120s

echo "Rabbitmq ficou disponivel"

echo "======================================"
echo "Aplicando postgres da aplicação"

kubectl apply -f ./k8s/postgres

echo "Aguardando postgres ficar disponivel"

kubectl rollout status \
  deployment/postgres \
  --timeout=120s

echo "Postgres ficou disponivel"


echo "======================================"
echo "Aplicando prometheus da aplicação"

kubectl apply -f ./k8s/prometheus/configmap.yaml
kubectl apply -f ./k8s/prometheus/deployment.yaml

echo "Aguardando prometheus ficar disponivel"

kubectl rollout status \
  deployment/prometheus \
  --timeout=120s

echo "Prometheus ficou disponivel"

echo "======================================"
echo "Aplicando tempo da aplicação"

kubectl apply -f ./k8s/tempo --validate=false

echo "Aguardando tempo ficar disponivel"

kubectl rollout status \
  deployment/tempo \
  --timeout=120s

echo "Tempo ficou disponivel"


echo "======================================"
echo "Aplicando logs da aplicação"

kubectl apply -f ./k8s/logs --validate=false

echo "Logs ficou disponivel"


echo "======================================"
echo "Aplicando grafana da aplicação"

kubectl apply -k ./k8s/grafana --validate=false

echo "Aguardando grafana ficar disponivel"

kubectl rollout status \
  deployment/grafana \
  --timeout=120s

echo "Grafana ficou disponivel"

echo "======================================"
echo "Subindo kong da aplicação"


echo "======================================"
echo "Aplicando infraestrutura..."
echo "======================================"

kubectl apply -k ./k8s/kong

echo "Parando Kong temporariamente..."

kubectl scale deployment/kong --replicas=0

echo "Removendo restore anterior..."

kubectl delete job kong-restore --ignore-not-found

echo "Aguardando PostgreSQL..."

kubectl rollout status \
  deployment/kong-database \
  --timeout=120s

echo "Aguardando Kong migrations..."

kubectl wait \
  --for=condition=complete \
  job/kong-migrations \
  --timeout=180s

echo "Criando Kong restore..."

kubectl apply -f ./k8s/kong/kong-service/restore-job.yaml

echo "Aguardando restore..."

kubectl wait \
  --for=condition=complete \
  job/kong-restore \
  --timeout=180s

echo "Iniciando Kong..."

kubectl scale deployment/kong --replicas=1

echo "Aguardando Kong..."

kubectl rollout status \
  deployment/kong \
  --timeout=180s

echo "Aguardando Konga prepare..."

kubectl wait \
  --for=condition=complete \
  job/konga-prepare \
  --timeout=180s

echo "Aguardando Konga..."

kubectl rollout status \
  deployment/konga \
  --timeout=180s

echo "======================================"
echo "Kong stack iniciado com sucesso!"
echo "======================================"

echo "Infraestrutura da aplicação subiu"