resource "kubernetes_cluster_role" "metallb-clusterrole-controller" {
  metadata {
    name = "metallb-system-controller"
    labels = {
      app = "metallb"
      component = "controller"
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
      app = "metallb"
      component = "speaker"
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
    namespace = "metallb-system"
    labels = {
      app = "metallb"
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
      app = "metallb"
      component = "controller"
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
    namespace = "metallb-system"
  }
}

resource "kubernetes_cluster_role_binding" "metallb-rolebinding-speaker" {
  metadata {
    name = "metallb-system-speaker"
    labels = {
      app = "metallb"
      component = "speaker"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "${kubernetes_cluster_role.metallb-clusterrole-speaker.metadata.0.name}"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "speaker"
    namespace = "metallb-system"
  }
}

resource "kubernetes_role_binding" "metallb-rolebinding" {
  metadata {
    namespace = "metallb-system"
    name      = "config-watcher"
    labels = {
      app = "metallb"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${kubernetes_role.metallb-role.metadata.0.name}"
  }
  subject {
    kind = "ServiceAccount"
    name = "controller"
  }
  subject {
    kind = "ServiceAccount"
    name = "speaker"
  }
}

resource "kubernetes_daemonset" "metallb-daemonset" {
  metadata {
    name      = "speaker"
    namespace = "metallb-system"
    labels = {
      app       = "metallb"
      component = "speaker"
    }
  }
  spec {
    selector {
      match_labels = {
        app       = "metallb"
        component = "speaker"
      }
    }
    template {
      metadata {
        labels = {
          app       = "metallb"
          component = "speaker"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = 7472
        }
      }
      spec {
        service_account_name             = "speaker"
        termination_grace_period_seconds = 0
        host_network                     = "true"
        container {
          name              = "speaker"
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
    namespace = "metallb-system"
    name      = "controller"
    labels = {
      app       = "metallb"
      component = "controller"
    }
  }
  spec {
    revision_history_limit = 3
    selector {
      match_labels = {
        app       = "metallb"
        component = "controller"
      }
    }
    template {
      metadata {
        labels = {
          app       = "metallb"
          component = "controller"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = 7472
        }
      }
      spec {
        service_account_name             = "controller"
        termination_grace_period_seconds = 0
        security_context {
          run_as_non_root = "true"
          run_as_user     = 65534 #Nobody
        }
        container {
          name              = "controller"
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
