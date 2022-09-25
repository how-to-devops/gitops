terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.0.13"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

provider "kind" {}
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kind_cluster" "staging" {
  name = "staging"

  node_image = "kindest/node:v1.25.2"
  
  wait_for_ready = true
  kubeconfig_path = pathexpand("~/.kube/config")

  kind_config {
    kind = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"
    node {
      extra_port_mappings {
        container_port = 30000
        host_port      = 8081
      }
    }
  }
}

resource "helm_release" "argocd" {
  depends_on = [
    kind_cluster.staging
  ]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.5.4"
  
  namespace = "argocd"
  create_namespace = true

  values = [
    "${file("argocd-values.yaml")}"
  ]
}

resource "helm_release" "argocd_apps" {
  depends_on = [
    helm_release.argocd
  ]

  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "0.0.1"
  
  namespace = "argocd"

  values = [
    "${file("argocd-app-values.yaml")}"
  ]
}