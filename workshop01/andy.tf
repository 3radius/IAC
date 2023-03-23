terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
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

provider "docker" {
  host = "tcp://146.190.106.1:2376"
  cert_path = var.docker_cert_path
}

provider digitalocean {
    token = var.do_token

}

provider local { }

resource "docker_network" "bgg-net" {
  name = "bgg-net"
}

#volume
resource "docker_volume" "data-vol" {
    name = "bgg_volume"
}



# pull the image
# docker pull <image>
resource "docker_image" "bgg-database" {
    name = var.image_name_db
}

resource "docker_image" "bgg-backend" {
    name = var.image_name_app
}

# run the container
# docker run -d -p 3000:3000 
resource "docker_container" "bgg-database" {
    #count = var.app_instance_count
    name = "bgg-database"
    image = docker_image.bgg-database.image_id
    
    networks_advanced    {
        name=docker_network.bgg-net.id
    }
    
    volumes {
      volume_name = docker_volume.data-vol.name
      container_path = "/var/lib/mysql"
    }

    ports {
        internal = 3306
        external = 3306 
    }
    
}

resource "docker_container" "bgg-backend" {

    count = var.app_instance_count

    name = "bgg-backend-${count.index}"
    image = docker_image.bgg-backend.image_id

    networks_advanced {
      name = docker_network.bgg-net.id
    }

    env = [
        "BGG_DB_USER=root",
        "BGG_DB_PASSWORD=changeit",
        "BGG_DB_HOST=${docker_container.bgg-database.name}",
    ]

    ports {
        internal = 3000
    }
}



variable do_token {
    type = string
    sensitive = true
}

variable image_name_db {
    type = string 
    default = "chukmunnlee/bgg-database:v3.1"
}

variable image_name_app {
    type = string 
    default = "chukmunnlee/bgg-backend:v3"
}


variable docker_cert_path {
    type = string
    sensitive = true
}

variable app_namespace {
    type = string 
    default = "my"
}

variable database_version {
    type = string
    default = "v3.1"
}

variable backend_version {
    type = string
    default = "v3"
}

variable app_instance_count{
    type = number
    default = 3
}

variable do_region {
    type = string
    default = "sgp1"
}
