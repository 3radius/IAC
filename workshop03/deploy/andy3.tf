terraform {
    required_providers {
        digitalocean = {
            source = "digitalocean/digitalocean"
            version = "2.26.0"
        }
        cloudflare = {
            source = "cloudflare/cloudflare"
            version = "4.2.0"
        }
        local = {
            source = "hashicorp/local"
            version = "2.4.0"
        }
    }
}

provider digitalocean {
    token = var.do_token
}


provider local { }

data "digitalocean_ssh_key" "andyaipcpub" {
    name = var.do_ssh_key
}

data "digitalocean_image" "codeserver" {
    name = "codeserver"
}


resource "digitalocean_droplet" "codeserver-andy" {
    name = "codeserver-andy"
    image = var.do_image
    region = var.do_region
    size = var.do_size

    ssh_keys = [ data.digitalocean_ssh_key.andyaipcpub.id ]

    connection {
      type = "ssh"
      user = "root"
      private_key = file(var.ssh_private_key)
      host = self.ipv4_address
    }

    provisioner "remote-exec" {
      inline = [
        "sed -i 's/__codeserver_domain/codeserver-${digitalocean_droplet.codeserver-andy.ipv4_address}.nip.io/' /etc/nginx/sites-available/code-server.conf",
        "sed -i 's/__codeserver_password/changeit/' /lib/systemd/system/code-server.service",
        "/usr/bin/systemctl restart code-server",
        "/usr/bin/systemctl restart nginx"
      ]
    }
}



resource "local_file" "root_at_codeserver" {
    filename = "root@${digitalocean_droplet.codeserver.ipv4_address}"
    content = ""
    file_permission = "0444"
}

output codeserver_ip {
    value = digitalocean_droplet.codeserver.ipv4_address
}

variable do_token {
    type = string
    sensitive = true
}

variable ssh_private_key {
    type = string
    sensitive = true
}

variable do_region {
    type = string
    default = "sgp1"
}

variable do_image {
    type = string 
    default = "ubuntu-20-04-x64"
}

variable do_size {
    type = string
    default = "s-1vcpu-512mb-10gb"
}

variable do_ssh_key {
    type = string 
    default = "andyaipcpub"
}

variable cs_domain {
    type = string
}

variable cs_password {
    type = string
    sensitive = true
}

variable cf_token {
    type = string 
    sensitive = true
}