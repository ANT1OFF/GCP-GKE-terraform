variable "project_id" {
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

variable "zone-for-cluster" {
  default = ["europe-west1-b"]
}

variable "cluster_name" {
  type = string
  default = "tf-gke-cluster-default"
}

variable "cluster_name_suffix" {
  type = string
  default = ""
}

variable "network_name" {
  type = string
  default = "vpc-network"
}

variable "subnet_name" {
  type = string
  default = "vpc-subnet"
}

variable "ip_range_sub" {
  type = string
  default = "10.10.10.0/24"
}

variable "ip_range_pods" {
  type = string
  default = "10.10.11.0/24"
}

variable "ip_range_services" {
  type = string
  default = "10.10.12.0/24"
}
