data "digitalocean_kubernetes_versions" "k8s_version" {
  version_prefix = "1.26."
}

resource "digitalocean_kubernetes_cluster" "explorer-blue" {
  name    = "explorer-blue"
  region  = "nyc1"
  version      = data.digitalocean_kubernetes_versions.example.latest_version
  tags        = ["staging"]

  node_pool {
    name       = "autoscale-worker-pool"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 3
  }

  taint {
    key    = "app"
    value  = "explorer-blue"
    effect = "NoSchedule"
  }

}

resource "digitalocean_kubernetes_cluster" "explorer-green" {
  name    = "explorer-green"
  region  = "nyc1"
  version      = data.digitalocean_kubernetes_versions.k8s_version.latest_version
  tags        = ["prod"]

  node_pool {
    name       = "autoscale-worker-pool"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 3
  }

  taint {
    key    = "app"
    value  = "explorer-green"
    effect = "NoSchedule"
  }
}

