terraform {
  # The modules used in this example have been updated with 0.12 syntax, additionally we depend on a bug fixed in
  # version 0.12.20.
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
  create_service_account = true


}

resource "kubernetes_pod" "nginx-example" {
  metadata {
    name = "nginx-example"

    labels = {
      maintained_by = "terraform"
      app           = "nginx-example"
    }
  }

  spec {
    container {
      image = "nginx:1.7.9"
      name  = "nginx-example"
    }
  }
  depends_on = [module.kubernetes-engine, module.vpc]
}

resource "kubernetes_service" "nginx-example" {
  metadata {
    name = "terraform-example"
  }

  spec {
    selector = {
      app = kubernetes_pod.nginx-example.metadata[0].labels.app
    }

    session_affinity = "ClientIP"

    port {
      port        = 8080
      target_port = 80
    }

    type = "LoadBalancer"
  }

  depends_on = [module.kubernetes-engine]
}