alias gb="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'"

alias uuidgen='uuidgen | tr "[:upper:]" "[:lower:]"'

aws-elbrules() {
    lbname=${1:-'web-lb-np'}
    lbarn=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?LoadBalancerName==`'"$lbname"'`].LoadBalancerArn' --output text)
    lblistener=$(aws elbv2 describe-listeners --load-balancer-arn $lbarn --query 'Listeners[?Port==`443`].ListenerArn' --output text)
    aws elbv2 describe-rules --listener-arn $lblistener
}

alias mfa-ait="ykman oath accounts code -s AWS-ait:mjmayer"

# enables a form of wildcard `terraform -target` https://github.com/hashicorp/terraform/issues/2182
# terraform plan | terraform-targets | grep 'some pattern' | xargs -r terraform apply -auto-approve
terraform-targets () {
  sed 's/\x1b\[[0-9;]*m//g' | grep -o '# [^( ]* ' | grep '\.' | sed " s/^# /-target '/; s/ $/'/; "
}
