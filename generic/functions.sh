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

