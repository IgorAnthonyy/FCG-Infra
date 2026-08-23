#!/bin/bash

set -e

echo "Aplicando infraestrutura..."
kubectl apply -k .

echo "Aguardando PostgreSQL..."
kubectl rollout status deployment/kong-database --timeout=120s

echo "Aguardando Kong migrations..."
kubectl wait \
  --for=condition=complete \
  job/kong-migrations \
  --timeout=180s

echo "Aguardando Kong..."
kubectl rollout status deployment/kong --timeout=180s

echo "Aguardando Konga prepare..."
kubectl wait \
  --for=condition=complete \
  job/konga-prepare \
  --timeout=180s

echo "Aguardando Konga..."
kubectl rollout status deployment/konga --timeout=180s

echo "================================"
echo "Kong stack iniciado com sucesso!"
echo "================================"