locals {
  home        = var.deployer.ssh_user == "root" ? "/root" : "/home/${var.deployer.ssh_user}"
  staging_dir = "${local.home}/subspace"
  staged_dir  = "${local.staging_dir}/host-agent"
  deploy_dir  = "${local.home}/deploy/host-agent"

  # every .yml in compose/ is uploaded and installed, and only those count
  # towards the trigger; COMPOSE_FILE picks the ones in use
  compose_dir   = "${path.module}/compose"
  compose_files = ["docker-compose.yml"]

  scrape_config = templatefile("${path.module}/scrape.yml.tftpl", {
    server       = var.host.name
    scrape_ports = var.host.scrape_ports
  })

  # Compose reads this from the deploy directory, so `docker compose` run there
  # by hand sees the same project, files and values as the deploy
  env = {
    COMPOSE_PROJECT_NAME    = "host-agent"
    COMPOSE_FILE            = join(":", local.compose_files)
    VMAGENT_IMAGE           = var.images.vmagent
    NODE_EXPORTER_IMAGE     = var.images.node_exporter
    SMARTCTL_EXPORTER_IMAGE = var.images.smartctl_exporter
    PYTHON_IMAGE            = var.images.python
    LOKI_URL                = var.loki_url
    VMETRICS_URL            = var.vmetrics_url
    SERVER_NAME             = var.host.name
    EXPECTED_DISKS          = var.host.disks
    SCRAPE_CONFIG_HASH      = md5(local.scrape_config)
    TEXTFILES_HASH          = filemd5("${path.module}/textfiles.py")
  }
  # single-quoted, so Compose takes each value literally instead of expanding a
  # $ in it; the precondition below keeps quotes out of the values
  env_file = join("", [for k in keys(local.env) : "${k}='${local.env[k]}'\n"])
}

resource "null_resource" "deploy" {
  # A reinstalled server has new host keys, so rebuilding it at the same address
  # deploys again
  triggers = {
    ipv4            = var.ipv4
    host_key        = sensitive(var.host.host_key)
    ssh_user        = var.deployer.ssh_user
    compose_hash    = sha1(join("", [for f in sort(fileset(local.compose_dir, "*.yml")) : "${f}:${filesha1("${local.compose_dir}/${f}")}\n"]))
    env_hash        = md5(local.env_file)
    credential_hash = sha256(jsonencode(var.vmetrics_credential))
    deploy_hash     = filemd5("${path.module}/deploy.sh")
    port_guard_hash = filemd5("${var.deployer.path_to_scripts}/compose-port-guard.py")
  }

  lifecycle {
    precondition {
      condition     = alltrue([for v in values(local.env) : !strcontains(v, "'")])
      error_message = "A value for the host agent's .env contains a single quote, which its quoting can't hold."
    }
    precondition {
      condition     = alltrue([for f in local.compose_files : fileexists("${local.compose_dir}/${f}")])
      error_message = "COMPOSE_FILE names a file that is not in the module's compose/ directory."
    }
  }

  connection {
    host           = var.ipv4
    user           = var.deployer.ssh_user
    host_key       = var.host.host_key
    type           = "ssh"
    agent          = true
    agent_identity = var.deployer.ssh_agent_identity
    timeout        = "300s"
  }

  # A directory only the deploy user can read, since provisioners can't set a
  # file's mode; deploy.sh empties it however it ends. The credential goes last,
  # so an upload that fails early leaves none behind.
  provisioner "remote-exec" {
    inline = ["install -d -m 0700 ${local.staged_dir} ${local.staged_dir}/credentials"]
  }

  provisioner "file" {
    source      = "${path.module}/deploy.sh"
    destination = "${local.staging_dir}/host-agent-deploy.sh"
  }

  provisioner "file" {
    source      = "${var.deployer.path_to_scripts}/compose-port-guard.py"
    destination = "${local.staging_dir}/compose-port-guard.py"
  }

  # the trailing slash uploads the directory's contents
  provisioner "file" {
    source      = "${local.compose_dir}/"
    destination = local.staged_dir
  }

  provisioner "file" {
    content     = local.scrape_config
    destination = "${local.staged_dir}/scrape.yml"
  }

  provisioner "file" {
    source      = "${path.module}/textfiles.py"
    destination = "${local.staged_dir}/textfiles.py"
  }

  provisioner "file" {
    content     = local.env_file
    destination = "${local.staged_dir}/.env"
  }

  provisioner "file" {
    content     = var.vmetrics_credential.username
    destination = "${local.staged_dir}/credentials/vmetrics-username"
  }

  provisioner "file" {
    content     = var.vmetrics_credential.password
    destination = "${local.staged_dir}/credentials/vmetrics-password"
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
      sudo DEPLOY_USER=${var.deployer.ssh_user} \
        DEPLOY_DIR=${local.deploy_dir} \
        STAGED_DIR=${local.staged_dir} \
        PORT_GUARD=${local.staging_dir}/compose-port-guard.py \
        bash ${local.staging_dir}/host-agent-deploy.sh
      EOT
    ]
  }
}
