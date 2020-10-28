alias gb="git for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'"

aws-elbrules() {
    lbname=${1:-'web-lb-np'}
    lbarn=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?LoadBalancerName==`'"$lbname"'`].LoadBalancerArn' --output text)
    lblistener=$(aws elbv2 describe-listeners --load-balancer-arn $lbarn --query 'Listeners[?Port==`443`].ListenerArn' --output text)
    aws elbv2 describe-rules --listener-arn $lblistener
}
