provider "digitalocean" {
  token = var.do_token
}
data "digitalocean_ssh_key" "nazar-key" {
  name = "Nazar SSH Key"
}
data "digitalocean_ssh_key" "leo-key" {
  name = "Leo SSH Key"
}
data "digitalocean_ssh_key" "serge-key" {
  name = "Serge SSH Key"
}
