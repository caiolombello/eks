apiVersion: v1
clusters:
- cluster:
    server: ${endpoint}
    certificate-authority-data: ${certificate_authority}
  name: ${cluster_name}
contexts:
- context:
    cluster: ${cluster_name}
    user: ${service_account_name}
  name: ${service_account_name}@${cluster_name}
current-context: ${service_account_name}@${cluster_name}
kind: Config
preferences: {}
users:
- name: ${service_account_name}
  user:
    token: ${token}
