# Required Google APIs

locals {
  googleapis = ["bigtable.googleapis.com", "cloudkms.googleapis.com", ]
}

resource "google_project_service" "bigtable" {
  for_each           = toset(local.googleapis)
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_kms_key_ring" "example-keyring690" {
  name     = "keyring-example690"
  location = "us-central1"
  depends_on = [
    google_project_service.bigtable
  ]
}

resource "google_kms_crypto_key" "bt_key690" {
  name     = "key690"
  key_ring = google_kms_key_ring.example-keyring690.id
}

resource "google_kms_key_ring" "example-keyring691" {
  name     = "keyring-example691"
  location = "us-east1"
  depends_on = [
    google_project_service.bigtable
  ]
}

resource "google_kms_crypto_key" "bt_key691" {
  name     = "key691"
  key_ring = google_kms_key_ring.example-keyring691.id
}


# Deployment to PROD need to have HA support deploying cluster in different zones of regions.

resource "google_bigtable_instance" "bt_prod_instance690" {
  name                = "bt-wf-instance690"
  deletion_protection = false

  cluster {
    cluster_id   = "bt-instance-cluster-central"
    storage_type = "HDD"
    zone         = "us-central1-b"
    kms_key_name = google_kms_crypto_key.bt_key690.id
    autoscaling_config {
      min_nodes  = 1
      max_nodes  = 5
      cpu_target = 50
    }
  }

  cluster {
    cluster_id   = "bt-instance-cluster-east"
    storage_type = "HDD"
    zone         = "us-east1-b"
    kms_key_name = google_kms_crypto_key.bt_key691.id
    autoscaling_config {
      min_nodes  = 1
      max_nodes  = 5
      cpu_target = 50
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_bigtable_table" "table" {
  name          = "tf-table"
  instance_name = google_bigtable_instance.bt_prod_instance690.name
  split_keys    = ["a", "b", "c"]

  lifecycle {
    prevent_destroy = true
  }
}

# resource "google_bigtable_instance" "bt_prod_instance651" {
#   name                = "bt-wf-instance651"
#   deletion_protection = false

#   cluster {
#     cluster_id   = "bt-instance-cluster-central-b"
#     storage_type = "HDD"
#     zone         = "us-central1-b"
#     kms_key_name = google_kms_crypto_key.bt_key650.id
#     autoscaling_config {
#       min_nodes  = 1
#       max_nodes  = 5
#       cpu_target = 50
#     }
#   }

#   cluster {
#     cluster_id   = "bt-instance-cluster-central-a"
#     storage_type = "HDD"
#     zone         = "us-central1-a"
#     kms_key_name = google_kms_crypto_key.bt_key650.id
#     autoscaling_config {
#       min_nodes  = 1
#       max_nodes  = 5
#       cpu_target = 50
#     }
#   }
# }
 