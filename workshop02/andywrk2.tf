terraform {
    required_providers {
        
        digitalocean = {
            source = "digitalocean/digitalocean"
            version = "2.26.0"
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

#resource
# images
data "digitalocean_ssh_key" "andyaipcpub" {
    name = var.do_ssh_key
}

resource "digitalocean_droplet" "codeserver" {
    name = "codeserver"
    image = var.do_image
    region = var.do_region
    size = var.do_size

    ssh_keys = [ data.digitalocean_ssh_key.andyaipcpub.id ]
}

resource "local_file" "root_at_codeserver" {
    filename = "root@${digitalocean_droplet.codeserver.ipv4_address}"
    content = ""
    file_permission = "0444"
}

resource "local_file" "inventory" {
    filename = "inventory.yaml"
    content = templatefile("inventory.yaml.tftpl", {
        codeserver_ip = digitalocean_droplet.codeserver.ipv4_address
        ssh_private_key = var.ssh_private_key
        codeserver_domain = "code-server-${digitalocean_droplet.codeserver.ipv4_address}.nip.io"
        codeserver_password = var.codeserver_password
    })
    file_permission = "0444"
}

output codeserver_ip {
    value = digitalocean_droplet.codeserver.ipv4_address
}


#variable

variable do_token {
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
    default = "s-1vcpu-1gb"
}

variable do_ssh_key {
    type = string 
    default = "andyaipcpub"
}

variable ssh_private_key {
    type = string
}

variable codeserver_password {
    type = string
}