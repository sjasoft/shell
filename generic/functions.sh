function install_mongo {
    code=$(lsb_release -c -s)
    sudo apt-get install gnupg
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu ${code}/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    update
}

function install_aws {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
}


function fusion_docker {
    curl -fsSL https://raw.githubusercontent.com/FusionAuth/fusionauth-containers/master/docker/fusionauth/docker-compose.yml > docker-compose.yml && \
    curl -fsSL https://raw.githubusercontent.com/FusionAuth/fusionauth-containers/master/docker/fusionauth/.env > .env && \
    docker-compose up
}

function lucs-open {
    drive_partition=$1
    mapped_as=$2
    sudo cryptsetup luksOpen $drive_partition $mapped_as
}
    
function luks-install {
    drive_partition=$1
    sudo cryptsetup luksFormat $drive_partition
}

function luks-use {
    drive_partition=$1
    mapper_name=$2
    mount_to=$3
    lucs-open $drive_partition $mapper_name
    sudo mount /dev/mapper/$mapper_name $mount_to
}

function luks-close {
   mounted_as=$1
   mapper_name=$2
   sudo umount $mounted_as
   sudo cryptsetup luksClose $mapper_name
}
