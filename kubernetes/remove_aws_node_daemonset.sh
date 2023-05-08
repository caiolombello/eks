#!/bin/bash

if kubectl -n kube-system get daemonset aws-node > /dev/null 2>&1; then
  kubectl -n kube-system delete daemonset aws-node
else
  echo "aws-node daemonset not found, skipping deletion."
fi