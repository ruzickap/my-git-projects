resource "random_password" "supabase_project_container_image_scans" {
  length = 16
}

resource "supabase_project" "container_image_scans" {
  organization_id = "nejknhtshawlnwtrxyaj"
  name            = "container-image-scans"
  # kics-scan ignore-line
  database_password = random_password.supabase_project_container_image_scans.result
  region            = "us-east-1"
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
  value       = "https://${supabase_project.container_image_scans.id}.supabase.co"
}

output "supabase_container_image_scans_env_yaml" {
  description = "Supabase env.yaml snippet for container-image-scans"
  sensitive   = true
  value       = <<-EOT
    # Supabase - web app (read-only, anon key)
    NEXT_PUBLIC_SUPABASE_ANON_KEY: "${data.supabase_apikeys.container_image_scans.anon_key}"
    NEXT_PUBLIC_SUPABASE_URL: "${"https://${supabase_project.container_image_scans.id}.supabase.co"}"

    # Supabase - scan script (write, service-role key)
    SUPABASE_SERVICE_ROLE_KEY: "${data.supabase_apikeys.container_image_scans.service_role_key}"
    SUPABASE_URL: "${"https://${supabase_project.container_image_scans.id}.supabase.co"}"

    # Supabase - schema migrations
    SUPABASE_ACCESS_TOKEN: "${data.sops_file.env_yaml.data["SUPABASE_ACCESS_TOKEN"]}"
    SUPABASE_DB_PASSWORD: "${random_password.supabase_project_container_image_scans.result}"
    SUPABASE_PROJECT_REF: "${supabase_project.container_image_scans.id}"
  EOT
}
# keep-sorted end
