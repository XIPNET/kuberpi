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
    name      = "controller"
    labels = {
      app = "metallb"
    }
  }
}

resource "kubernetes_service_account" "metallb-serviceaccount-speaker" {
  metadata {
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
    name      = "speaker"
    labels = {
      app = "metallb"
    }
  }
}

resource "kubernetes_cluster_role" "metallb-clusterrole-controller" {
  metadata {
    name = "metallb-system-controller"
    labels = {
      app = "metallb"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["services/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }
}

resource "kubernetes_cluster_role" "metallb-clusterrole-speaker" {
  metadata {
    name = "metallb-system-speaker"
    labels = {
      app = "metallb"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role" "metallb-role" {
  metadata {
    name = "config-watcher"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
    labels = {
      app = "metallb"
    }
  }
  
  rule {
    api_groups = [""]
    resources = ["configmaps"]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources = ["events"]
    verbs = ["create"]
  }
}

