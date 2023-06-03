#!/bin/bash

cd "$(dirname "$0")"

if [[ ! -f "/home/qdnqn/.run.once" ]]; then
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

  while [[ $(kubectl get crd | grep ingressroutes.traefik.containo.us | wc -l) == 0 ]];
  do
    sleep 5
  done;

  docker run -d -p 5000:5000 --restart=always --name registry registry:2

  for arg in "$@"
  do
      if [[ $arg == "kafka"]]; then
          kubectl create ns kafka
          helm upgrade --install kafka ../charts/kafka --namespace kafka --values ../charts/kafka/values.yaml
      elif [[ $arg == "kafdrop" ]]; then
          kubectl create ns kafdrop
          helm upgrade --install kafka ../charts/kafdrop --namespace kafdrop --values ../charts/kafdrop/values.yaml
      elif [[ $arg == "kafdrop" ]]; then
          kubectl create ns argocd
          helm upgrade --install argocd ../charts/argocd --namespace argocd --values ../charts/argocd/values.yaml
      else
        echo "Invalid argument $arg"
      fi
  done

  kubectl apply -f resources/raw/yaml/setup/traefik-config-k3s.yaml

  VM_IP=$(hostname -I | cut -d " " -f1)
  sed -i "s/{VM_IP}/${VM_IP}/g" resources/raw/yaml/setup/ingresses.yaml

  kubectl apply -f resources/raw/yaml/setup/ingresses.yaml
  
  touch /home/ubuntu/.run.once
fi