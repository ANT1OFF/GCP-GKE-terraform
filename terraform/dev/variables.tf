variable "project_name" {
  type = string
}

variable "region" {
  type = string
  default = "europe-west1"
}

variable "zone" {
  type = string
  default = "europe-west1-b"
}

variable "pool_name" {
  type = string
  default = "tf-node-pool-default"
}

variable "cluster_name" {
  type = string
  default = "tf-gke-cluster-default"
}