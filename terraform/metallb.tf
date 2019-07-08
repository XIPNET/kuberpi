resource "kubernetes_namespace" "metallb-namespace" {
  metadata {
    annotations = {
      name = "metallb-system"
    }

    labels = {
      app = "metallb"
    }

    name = "metallb-system"
  }

}

resource "kubernetes_service_account" "metallb-serviceaccount-conttroller" {
  metadata {
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"

    name = "controller"

    labels = {
      app = "metallb"
    }

  }

}

resource "kubernetes_service_account" "metallb-serviceaccount-speaker" {
  metadata {
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"

    name = "speaker"

    labels = {
      app = "metallb"
    }

  }

}
