resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "monitoring"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.13.2"
  values     = [file("${path.module}/values/cilium.yaml")]

  depends_on = [
    kubernetes_manifest.serviceMonitorCRD
  ]
}

resource "null_resource" "restart_pods" {
  depends_on = [helm_release.cilium]

  provisioner "local-exec" {
    command = <<EOF
      kubectl get pods --kubeconfig ../kubeconfig.yaml --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod
    EOF
  }
}

# resource "null_resource" "enable_security_group" {
#   depends_on = [null_resource.restart_pods]

#   provisioner "local-exec" {
#     command = <<EOF
#       export EKS_CLUSTER_NAME=${data.terraform_remote_state.eks.outputs.cluster_name}
#       export EKS_CLUSTER_ROLE_NAME=$(aws eks describe-cluster \
#           --name "$${EKS_CLUSTER_NAME}" \
#           | jq -r '.cluster.roleArn' | awk -F/ '{print $NF}')
#       aws iam attach-role-policy \
#           --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController \
#           --role-name "$${EKS_CLUSTER_ROLE_NAME}"
#     EOF
#   }
# }