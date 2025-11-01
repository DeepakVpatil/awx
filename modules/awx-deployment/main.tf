resource "kubernetes_namespace" "awx" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "awx_operator" {
  name       = "awx-operator"
  repository = "https://ansible.github.io/awx-operator/"
  chart      = "awx-operator"
  namespace  = kubernetes_namespace.awx.metadata[0].name
  version    = var.operator_version

  values = [
    yamlencode(var.operator_values)
  ]
}