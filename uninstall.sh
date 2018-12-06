#!/usr/bin/env bash

kubectl --namespace=argo-events delete deployments sensor-controller gateway-controller

kubectl --namespace=argo-events delete configmap sensor-controller-configmap gateway-controller-configmap

kubectl --namespace=argo-events delete crd gateways.argoproj.io sensors.argoproj.io
