terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  project     = "innate-beacon-424414-k5"
  credentials = file("credentials.json")
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network-unique1"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "default" {
  name          = "terraform-subnet-unique1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-west1"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_instance" "default" {
  name         = "flask-vm-unique1"
  machine_type = "f1-micro"
  zone         = "us-west1-a"
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y python3-pip git
    pip3 install -r /home/tu-usuario/my-terraform-project/requirements.txt

    # Clona el proyecto desde el repositorio de GitHub
    git clone https://github.com/devjosalazar/gcp-terraform.git /home/tu-usuario/my-terraform-project

    # Navega al directorio del proyecto y ejecuta la aplicación
    cd /home/tu-usuario/my-terraform-project
    python3 app.py
  EOT

  network_interface {
    subnetwork = google_compute_subnetwork.default.id

    access_config {
      # Incluye esta sección para darle a la VM una dirección IP externa
    }
  }
}

resource "google_compute_firewall" "ssh" {
  name = "allow-ssh-unique1"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "flask" {
  name    = "flask-app-firewall-unique1"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }
  source_ranges = ["0.0.0.0/0"]
}

output "Web-server-URL" {
  value = join("", ["http://", google_compute_instance.default.network_interface.0.access_config.0.nat_ip, ":5000"])
}
