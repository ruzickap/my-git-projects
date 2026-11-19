locals {
  supabase_container_image_scans_url = "https://${supabase_project.container_image_scans.id}.supabase.co"
}

resource "random_password" "supabase_project_container_image_scans" {
  length = 16
}

resource "supabase_project" "container_image_scans" {
  organization_id   = "nejknhtshawlnwtrxyaj"
  name              = "container-image-scans"
  database_password = random_password.supabase_project_container_image_scans.result
  region            = "us-east-1"

  # Holds the nightly scan history - blocks destroy and replace, but not removing
  # or renaming this block (the guard goes with it): use a moved block to rename
  lifecycle {
    prevent_destroy = true
  }
}

data "supabase_apikeys" "container_image_scans" {
  project_ref = supabase_project.container_image_scans.id
}

# keep-sorted start block=yes newline_separated=yes
output "supabase_container_image_scans_apikeys" {
  description = "Supabase API keys for container-image-scans"
  value       = data.supabase_apikeys.container_image_scans
  sensitive   = true
}

output "supabase_container_image_scans_database_password" {
  description = "Supabase database password for container-image-scans"
  value       = random_password.supabase_project_container_image_scans.result
  sensitive   = true
}

output "supabase_container_image_scans_endpoint" {
  description = "Supabase endpoint for container-image-scans"
  value       = local.supabase_container_image_scans_url
}
# keep-sorted end
