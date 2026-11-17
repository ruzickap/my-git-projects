# Settings shared by all zones
locals {
  cloudflare_zone_ids = {
    # keep-sorted start
    mylabs_dev  = cloudflare_zone.mylabs_dev.id
    ruzicka_dev = cloudflare_zone.ruzicka_dev.id
    xvx_cz      = cloudflare_zone.xvx_cz.id
    # keep-sorted end
  }
}

resource "cloudflare_zone_dnssec" "this" {
  for_each = local.cloudflare_zone_ids
  zone_id  = each.value
  status   = "active"

  # Workaround: Cloudflare API returns "pending" until DS records propagate,
  # causing perpetual drift against the desired "active" status.
  # https://github.com/cloudflare/terraform-provider-cloudflare/issues/6237
  lifecycle {
    ignore_changes = [status]
  }
}

resource "cloudflare_zone_setting" "min_tls_version" {
  for_each   = local.cloudflare_zone_ids
  zone_id    = each.value
  setting_id = "min_tls_version"
  value      = "1.3"
}

# Compression Rules - Enable Zstandard (Zstd) Compression
resource "cloudflare_ruleset" "compression" {
  for_each    = local.cloudflare_zone_ids
  zone_id     = each.value
  name        = "Compression Rules"
  description = "Enable Zstandard compression with Brotli and Gzip fallbacks"
  kind        = "zone"
  phase       = "http_response_compression"
  rules = [{
    action      = "compress_response"
    expression  = "true"
    description = "Enable Zstd compression"
    enabled     = true
    action_parameters = {
      algorithms = [
        { name = "zstd" },
        { name = "brotli" },
        { name = "gzip" },
      ]
    }
  }]
}

# Cache Rules - Cache default file extensions
resource "cloudflare_ruleset" "cache" {
  for_each    = local.cloudflare_zone_ids
  zone_id     = each.value
  name        = "Cache Rules"
  description = "Cache default file extensions"
  kind        = "zone"
  phase       = "http_request_cache_settings"
  rules = [{
    action      = "set_cache_settings"
    expression  = "(http.request.uri.path.extension in {\"7z\" \"avi\" \"avif\" \"apk\" \"bin\" \"bmp\" \"bz2\" \"class\" \"css\" \"csv\" \"doc\" \"docx\" \"dmg\" \"ejs\" \"eot\" \"eps\" \"exe\" \"flac\" \"gif\" \"gz\" \"ico\" \"iso\" \"jar\" \"jpg\" \"jpeg\" \"js\" \"mid\" \"midi\" \"mkv\" \"mp3\" \"mp4\" \"ogg\" \"otf\" \"pdf\" \"pict\" \"pls\" \"png\" \"ppt\" \"pptx\" \"ps\" \"rar\" \"svg\" \"svgz\" \"swf\" \"tar\" \"tif\" \"tiff\" \"ttf\" \"webm\" \"webp\" \"woff\" \"woff2\" \"xls\" \"xlsx\" \"zip\" \"zst\"})"
    description = "Cache default file extensions"
    enabled     = true
    action_parameters = {
      cache = true
    }
  }]
}
