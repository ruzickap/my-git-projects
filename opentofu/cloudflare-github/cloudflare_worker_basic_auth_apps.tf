locals {
  # Simple HTML page behind HTTP Basic Auth, shared by all *.xvx.cz "appN" Workers below
  basic_auth_worker_script = <<-JS
    export default {
      async fetch(request, env) {
        const unauthorized = () =>
          new Response("Unauthorized", {
            status: 401,
            headers: { "WWW-Authenticate": `Basic realm="$${new URL(request.url).hostname}"` },
          });

        const auth = request.headers.get("Authorization");
        if (!auth || !/^Basic /i.test(auth)) {
          return unauthorized();
        }

        let decoded;
        try {
          decoded = atob(auth.slice(6));
        } catch {
          return unauthorized();
        }

        const separatorIndex = decoded.indexOf(":");
        const user = decoded.slice(0, separatorIndex);
        const pass = decoded.slice(separatorIndex + 1);
        if (user !== env.BASIC_AUTH_USERNAME || pass !== env.BASIC_AUTH_PASSWORD) {
          return unauthorized();
        }

        const hostname = new URL(request.url).hostname;
        return new Response(
          `<!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <title>$${hostname}</title>
    </head>
    <body>
      <h1>$${hostname}</h1>
      <p>This page is protected by HTTP Basic Auth.</p>
    </body>
    </html>
    `,
          { headers: { "Content-Type": "text/html; charset=UTF-8" } },
        );
      },
    };
  JS

  # keep-sorted start block=yes
  basic_auth_apps = {
    "app1" = {
      username = data.aws_ssm_parameter.app1_xvx_cz_basic_auth_username.value
      password = data.aws_ssm_parameter.app1_xvx_cz_basic_auth_password.value
    }
    "app2" = {
      username = data.aws_ssm_parameter.app2_xvx_cz_basic_auth_username.value
      password = data.aws_ssm_parameter.app2_xvx_cz_basic_auth_password.value
    }
    "app3" = {
      username = data.aws_ssm_parameter.app3_xvx_cz_basic_auth_username.value
      password = data.aws_ssm_parameter.app3_xvx_cz_basic_auth_password.value
    }
  }
  # keep-sorted end
}

# Cloudflare Workers serving a simple HTML page behind HTTP Basic Auth on appN.xvx.cz
resource "cloudflare_workers_script" "basic_auth_apps" {
  for_each = local.basic_auth_apps

  account_id         = local.cloudflare_account_id
  script_name        = "${each.key}-xvx-cz"
  content            = local.basic_auth_worker_script
  content_sha256     = sha256(local.basic_auth_worker_script)
  main_module        = "${each.key}_xvx_cz.js"
  compatibility_date = "2025-01-01"

  # Ensure the token used by the Cloudflare provider already has Workers Scripts Write
  # before creating these Workers, to avoid a 403 race on the first apply.
  depends_on = [cloudflare_account_token.opentofu_cloudflare_github]

  bindings = [
    {
      name = "BASIC_AUTH_USERNAME"
      type = "secret_text"
      text = each.value.username
    },
    {
      name = "BASIC_AUTH_PASSWORD"
      type = "secret_text"
      text = each.value.password
    },
  ]
}

resource "cloudflare_workers_custom_domain" "basic_auth_apps" {
  for_each = local.basic_auth_apps

  account_id = local.cloudflare_account_id
  zone_id    = cloudflare_zone.xvx_cz.id
  hostname   = "${each.key}.${cloudflare_zone.xvx_cz.name}"
  service    = cloudflare_workers_script.basic_auth_apps[each.key].script_name
}

output "basic_auth_apps_urls" {
  description = "URLs with embedded HTTP Basic Auth credentials for appN.xvx.cz"
  value = {
    for app_name, app in local.basic_auth_apps :
    app_name => "https://${urlencode(app.username)}:${urlencode(app.password)}@${app_name}.${cloudflare_zone.xvx_cz.name}"
  }
  sensitive = true
}
