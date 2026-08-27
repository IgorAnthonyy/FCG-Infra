#!/bin/bash

set -e

echo "======================================"
echo "RESETANDO KONG / KONGA"
echo "======================================"

echo ""
echo "1. Removendo recursos do Kustomize..."

kubectl delete -k . || true

echo ""
echo "2. Removendo Kong Restore Job..."

if kubectl get job kong-restore >/dev/null 2>&1; then
    kubectl delete job kong-restore
fi

echo ""
echo "3. Removendo Kong Migrations Job..."

if kubectl get job kong-migrations >/dev/null 2>&1; then
    kubectl delete job kong-migrations
fi

echo ""
echo "4. Removendo Konga Prepare Job..."

if kubectl get job konga-prepare >/dev/null 2>&1; then
    kubectl delete job konga-prepare
fi

echo ""
echo "5. Removendo PVC do PostgreSQL..."

if kubectl get pvc kong-postgres-pvc >/dev/null 2>&1; then
    kubectl delete pvc kong-postgres-pvc
fi

echo ""
echo "6. Aguardando remoção dos recursos..."

sleep 5

echo ""
echo "======================================"
echo "RECURSOS RESTANTES"
echo "======================================"

echo ""
echo "Pods:"
kubectl get pods

echo ""
echo "Deployments:"
kubectl get deployments

echo ""
echo "Services:"
kubectl get services

echo ""
echo "Jobs:"
kubectl get jobs

echo ""
echo "PVCs:"
kubectl get pvc

echo ""
echo "======================================"
echo "RESET CONCLUÍDO"
echo "======================================"