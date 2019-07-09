resource "kubernetes_namespace" "metallb-namespace" {
  metadata {
    name = "metallb-system"
    labels = {
      app = "metallb"
    }
  }
}

resource "kubernetes_service_account" "metallb-serviceaccount-controller" {
  metadata {
    name      = "controller"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
    labels = {
      app = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
    }
  }
}

resource "kubernetes_service_account" "metallb-serviceaccount-speaker" {
  metadata {
    name      = "speaker"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
    labels = {
      app = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
    }
  }
}

resource "kubernetes_cluster_role" "metallb-clusterrole-controller" {
  metadata {
    name = "metallb-system-controller"
    labels = {
      app       = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
      component = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["services", "secrets"]
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
      app       = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
      component = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "nodes", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role" "metallb-role" {
  metadata {
    name      = "config-watcher"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
    labels = {
      app = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets"]
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
      app       = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
      component = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "${kubernetes_cluster_role.metallb-clusterrole-controller.metadata.0.name}"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
  }
}

resource "kubernetes_cluster_role_binding" "metallb-rolebinding-speaker" {
  metadata {
    name = "metallb-system-speaker"
    labels = {
      app       = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
      component = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "${kubernetes_cluster_role.metallb-clusterrole-speaker.metadata.0.name}"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
  }
}

resource "kubernetes_role_binding" "metallb-rolebinding" {
  metadata {
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
    name      = "config-watcher"
    labels = {
      app = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${kubernetes_role.metallb-role.metadata.0.name}"
  }
  subject {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
  }
  subject {
    kind = "ServiceAccount"
    name = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
  }
}

resource "kubernetes_daemonset" "metallb-daemonset" {
  metadata {
    name      = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
    labels = {
      app       = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
      component = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
    }
  }
  spec {
    selector {
      match_labels = {
        app       = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
        component = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
      }
    }
    template {
      metadata {
        labels = {
          app       = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
          component = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = 7472
        }
      }
      spec {
        automount_service_account_token  = "true"
        service_account_name             = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
        termination_grace_period_seconds = 0
        host_network                     = "true"
        container {
          name              = "${kubernetes_service_account.metallb-serviceaccount-speaker.metadata.0.name}"
          image             = "metallb/speaker:v0.7.3"
          image_pull_policy = "IfNotPresent"
          args              = ["--port=7472", "--config=config"]
          env {
            name = "METALLB_NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          port {
            container_port = 7472
            name           = "monitoring"
          }
          resources {
            limits {
              cpu    = "100m"
              memory = "100Mi"
            }
          }
          security_context {
            allow_privilege_escalation = "false"
            read_only_root_filesystem  = "true"
            capabilities {
              drop = ["all"]
              add  = ["net_raw"]
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "metallb-deployment" {
  metadata {
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
    name      = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
    labels = {
      app       = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
      component = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
    }
  }
  spec {
    revision_history_limit = 3

    selector {
      match_labels = {
        app       = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
        component = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
      }
    }
    template {
      metadata {
        labels = {
          app       = "${kubernetes_namespace.metallb-namespace.metadata[0].labels.app}"
          component = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = 7472
        }
      }
      spec {
        automount_service_account_token  = "true"
        service_account_name             = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
        termination_grace_period_seconds = 0
        security_context {
          run_as_non_root = "true"
          run_as_user     = 65534 #Nobody
        }
        container {
          name              = "${kubernetes_service_account.metallb-serviceaccount-controller.metadata.0.name}"
          image             = "metallb/controller:v0.7.3"
          image_pull_policy = "IfNotPresent"
          args              = ["--port=7472", "--config=config"]
          port {
            container_port = 7472
            name           = "monitoring"
          }
          resources {
            limits {
              cpu    = "100m"
              memory = "100Mi"
            }
          }
          security_context {
            allow_privilege_escalation = "false"
            capabilities {
              drop = ["all"]
            }
            read_only_root_filesystem = "true"
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "metallb-configmap" {
  metadata {
    name      = "config"
    namespace = "${kubernetes_namespace.metallb-namespace.metadata.0.name}"
  }
  data = {
    config = "${file("${path.module}/metallb-config.yaml")}"
  }
}