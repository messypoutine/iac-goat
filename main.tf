module "project-services" {
  source     = "terraform-google-modules/project-factory/google//modules/project_services"
  version    = "~> 14.5"
  project_id = var.project_id
  activate_apis = [
    "compute.googleapis.com",
    "iap.googleapis.com",
    "serviceusage.googleapis.com",
    "bigquery.googleapis.com",
  ]
}

module "iap_bastion" {
  source  = "messypoutine/bastion-ghost/google"
  version = "~> 1.0"

  project = module.project-services.project_id
  zone    = var.zone
  network = google_compute_network.network.self_link
  subnet  = google_compute_subnetwork.subnet.self_link
  members = var.members
}

resource "google_compute_network" "network" {
  project                 = module.project-services.project_id
  name                    = "goat-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  project                  = module.project-services.project_id
  name                     = "goat-subnet"
  region                   = var.region
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.network.self_link
  private_ip_google_access = true
}

resource "google_compute_firewall" "allow_access_from_bastion" {
  project = module.project-services.project_id
  name    = "allow-bastion-ssh"
  network = google_compute_network.network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Allow SSH only from IAP Bastion
  source_service_accounts = [module.iap_bastion.service_account]
}
