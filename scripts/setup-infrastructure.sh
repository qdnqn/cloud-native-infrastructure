#!/bin/bash

cd "$(dirname "$0")"

if [[ ! -f "/home/qdnqn/.run.once" ]]; then
  curl -sfL https://get.k3s.io | sh -
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

  while [[ $(kubectl get crd | grep ingressroutes.traefik.containo.us | wc -l) == 0 ]];
  do
    sleep 5
  done;

  # Setup Traefik
  kubectl apply -f resources/raw/yaml/setup/traefik-config-k3s.yaml

  VM_IP=$(hostname -I | cut -d " " -f1)
  sed -i "s/{VM_IP}/${VM_IP}/g" resources/raw/yaml/setup/ingress.yaml

  kubectl apply -f resources/raw/yaml/setup/ingresses.yaml

  # Start docker registry on the Virtual Machine - used for pulling from k3s cluster
  docker run -d -p 5000:5000 --restart=always --name registry registry:2

  # Install specified helm charts for the parent repository
  for arg in "$@"
  do
      if [[ $arg == "kafka"]]; then
          kubectl create ns kafka
          helm upgrade --install kafka ../charts/kafka --namespace kafka --values ../charts/kafka/values.yaml
      elif [[ $arg == "kafdrop" ]]; then
          kubectl create ns kafdrop
          helm upgrade --install kafka ../charts/kafdrop --namespace kafdrop --values ../charts/kafdrop/values.yaml
      elif [[ $arg == "argocd" ]]; then
          kubectl create ns argocd
          helm upgrade --install argocd ../charts/argocd --namespace argocd --values ../charts/argocd/values.yaml
          kubectl apply -f resources/raw/yaml/argocd/ingress.yaml
      else
        echo "Invalid argument $arg"
      fi
  done

  touch /home/ubuntu/.run.once
fi