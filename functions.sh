function transcribe_audio {
    whisperx $1 --verbose False --model medium --language en --output_dir /tmp  --output_format txt
}    

function transcribe {
    rm /tmp/video.*
    yt-dlp -x --cookies-from-browser firefox --audio-format mp3 -o /tmp/video.mp3 $1
    transcribe_audio /tmp/video.mp3
    cat /tmp/video.txt | more
}

function install_alt_java {
    for file in $1/bin/*
    do
	if [ -x $file ]
	then
	    filename=`basename $file`
	    sudo alternatives --install /usr/bin/$filename $filename $file 20000
	    sudo alternatives --set $filename $file
      #echo $file $filename
	fi
    done
}

function git_post_init {
    path=$1
    git_place=${2:-"https://github.com/sjasoft"}
    git commit -m 'first commit'
    git remote add origin $git_place/$path
    git push -u origin main
}
function into_to_git {
    git init
    git_post_init $1
}
function install_mongo {
    code=$(lsb_release -c -s)
    sudo apt-get install gnupg
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo  apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu ${code}/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    sudo apt update && sudo apt install mongodb-org
}
function ubuntu_base {
    sudo apt update
    sudo apt install git docker.io  unzip nginx
    sudo usermod -a -G docker ubuntu
    git https://github.com/sjatkins/shell
}

function install_aws {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
}

function pr_dockers {
    source ~/shell/aws/functions
    ecr_pull pr
    ecr_pull prserver
}

function erda_dockers {
    pr_dockers
    ecr_pull erdaserver 
    ecr_pull erda
}

function fusion_docker {
    curl -fsSL https://raw.githubusercontent.com/FusionAuth/fusionauth-containers/master/docker/fusionauth/docker-compose.yml > docker-compose.yml && \
    curl -fsSL https://raw.githubusercontent.com/FusionAuth/fusionauth-containers/master/docker/fusionauth/.env > .env && \
    docker-compose up
}

