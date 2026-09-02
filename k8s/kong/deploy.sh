#!/bin/bash

set -e

echo "======================================"
echo "Aplicando infraestrutura..."
echo "======================================"

kubectl apply -k .

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

kubectl apply -f kong-service/restore-job.yaml

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