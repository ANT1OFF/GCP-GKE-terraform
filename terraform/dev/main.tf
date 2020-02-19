terraform {
  required_version = ">= 0.12.20"
}


locals {
  cluster_type = "deploy-service"
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------


provider "google" {
  version = "~> 3.9.0"
  region  = var.region
  project = var.project_id
  credentials = file("credentials.json")
}


provider "kubernetes" {
  load_config_file       = false
  host                   = "https://${module.kubernetes-engine.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.kubernetes-engine.ca_certificate)
}

data "google_client_config" "default" {
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE A NETWORK TO DEPLOY THE CLUSTER TO
# ---------------------------------------------------------------------------------------------------------------------


module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "2.1.1"

  project_id   = var.project_id
  network_name = var.network_name
  subnets = [
      {
          subnet_name           = "sub-02"
          subnet_ip             = var.ip_range_sub
          subnet_region         = var.region
      },
  ]
  secondary_ranges = {
        sub-02 = [
            {
                range_name    = "sub-02-secondary-01-pods"
                ip_cidr_range = var.ip_range_pods
            },
            {
                range_name    = "sub-02-secondary-02-services"
                ip_cidr_range = var.ip_range_services
            },            
        ]
    }
}


module "service_accounts" {
  source        = "terraform-google-modules/service-accounts/google"
  project_id    = var.project_id
  prefix        = "tf"
  names         = ["gke-np-1-service-account"]
  project_roles = ["${var.project_id}=>roles/storage.objectViewer"]
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------


module "kubernetes-engine" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "7.2.0"
  
  project_id = var.project_id
  name       = "${local.cluster_type}-cluster${var.cluster_name_suffix}"
  region     = var.region
  zones      = var.zone-for-cluster
  network    = module.vpc.network_name
  subnetwork = module.vpc.subnets_names[0]

  ip_range_pods          = "sub-02-secondary-01-pods"
  ip_range_services      = "sub-02-secondary-02-services"

  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 1
      max_count          = 100
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = module.service_accounts.email
    },
  ]
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATE RECURCES IN THE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------


resource "kubernetes_service" "hello-world" {
  metadata {
    name = "terraform-hello-world"
  }
  spec {
    selector = {
      App = "${kubernetes_deployment.hello.spec[0].template[0].metadata[0].labels.App}"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "hello" {
  metadata {
    name = "terraform-hello"
    labels = {
      App = "hello"
    }
  }

  spec {
    replicas = 6
    selector {
      match_labels = {
        App = "hello"
      }
    }

    template {
      metadata {
        labels = {
          App = "hello"
        }
      }

      spec {
        container {
          image = "gcr.io/bachelor-2020/hello-world@sha256:52cd3259e461429ea5123623503920622fad5deb57f44e14167447d1cb1c777b"
          name  = "hello"
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}
