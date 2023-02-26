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
