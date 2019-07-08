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

resource "kubernetes_service_account" "metallb-serviceaccount-controller" {
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
    name      = "config-watcher"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
    labels = {
      app = "metallb"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create"]
  }
}

resource "kubernetes_cluster_role_binding" "metallb-rolebinding-controller" {
  metadata {
    name = "metallb-system-controller"
    labels = {
      app = "metallb"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "${kubernetes_cluster_role.metallb-clusterrole-controller.metadata.0.name}"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "controller"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
  }
}

resource "kubernetes_cluster_role_binding" "metallb-rolebinding-speaker" {
  "metadata" {
    name = "metallb-system-speaker"
    labels = {
      app = "metallb"
    }
  }
  "role_ref" {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "${kubernetes_cluster_role.metallb-clusterrole-speaker.metadata.0.name}"
  }
  "subject" {
    kind = "ServiceAccount"
    name = "speaker"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
  }
}

resource "kubernetes_role_binding" "metallb-rolebinding" {
  "metadata" {
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
    name = "config-watcher"
    labels = {
      app = "metallb"
    }
  }
  "role_ref" {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = "${kubernetes_role.metallb-role.metadata.0.name}"
  }
  "subject" {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
  }
  "subject" {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
  }
}