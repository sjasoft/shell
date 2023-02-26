installer=apt
function update {
    sudo $installer update && sudo $installer upgrade
}
function ubuntu_base {
    sudo apt update
    sudo apt install git docker.io  unzip nginx
    sudo usermod -a -G docker ubuntu
    git https://github.com/sjatkins/shell
}
