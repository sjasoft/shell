function aws_account {
    profile=${1:-default}
    echo $(aws sts get-caller-identity --query "Account" --profile $profile --output text)
}

function aws_region {
    profile=${1:-default}
    echo $(aws configure get region --profile $profile)
}

function ecr_base {
    profile=${1:-default}
    account=$(aws_account $profile)
    region=$(aws_region $profile)
    echo ${account}.dkr.ecr.${region}.amazonaws.com
}

function ecr_arn {
    repo=$1
    profile=${2:-default}
    echo $(ecr_base $profile)/$repo
}

function ecr_password {
    profile=${1:-default}
    echo $(aws ecr get-login-password --region $(aws_region $profile) --profile ${profile})
}

function ecr_login {
    profile=${1:-default}
    echo $(ecr_password $profile) | docker login --username AWS --password-stdin $(ecr_base $profile)
}

function build_repo {
    docker build --no-cache --tag $1 --build-arg MACHINE_USER_ACCESS_TOKEN=$MACHINE_USER_ACCESS_TOKEN .
}

function get_image_id {
    ref=*/$1
    echo $(docker images --filter="reference=*/$1" --quiet 2>&1)
}

function ecr_pull {
    repo=$1
    profile=${2:-default}
    arn=$(ecr_arn $repo $profile)

    ecr_login $profile
    docker pull $arn
    echo $arn
}

function pull_run {
    # note we assume profile=default here
    repo=$1
    arn=$(ecr_arn $repo)
    ecr_pull $repo
    shift 1
    echo docker run -d $@ $arn
    docker run -d $@ $arn

}

function pull_run_host {
    pull_run $1 --network host
}
    

function ecr_build_push {
    repo=$1
    profile=${2:-default}
    arn=$(ecr_arn $repo $profile)

    ecr_login $profile
    build_repo $repo
    image=$(get_image_id $repo)
    docker tag $image $arn
    docker push $arn
}
export AL2023=public.ecr.aws/amazonlinux/amazonlinux:2023
