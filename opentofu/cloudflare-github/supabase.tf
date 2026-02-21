resource "random_password" "supabase_project_container_image_scans" {
  length = 16
}

resource "supabase_project" "container_image_scans" {
  organization_id   = "nejknhtshawlnwtrxyaj"
  name              = "container-image-scans"
  database_password = random_password.supabase_project_container_image_scans.result
  region            = "us-east-1"
}

data "supabase_apikeys" "container_image_scans" {
  project_ref = supabase_project.container_image_scans.id
}

output "supabase_container_image_scans_apikeys" {
  description = "Supabase API keys for container-image-scans"
  value       = data.supabase_apikeys.container_image_scans
  sensitive   = true
}

output "supabase_container_image_scans_endpoint" {
  description = "Supabase endpoint for container-image-scans"
  value       = "https://${supabase_project.container_image_scans.id}.supabase.co"
}
