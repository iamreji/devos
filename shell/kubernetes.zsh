# ┌─────────────────────────────────────────────────────────────────┐
# │ Kubernetes Aliases                                              │
# └─────────────────────────────────────────────────────────────────┘

if command -v kubectl &>/dev/null; then
  alias k="kubectl"
  alias kg="kubectl get"
  alias kgp="kubectl get pods"
  alias kgs="kubectl get services"
  alias kgd="kubectl get deployments"
  alias kgn="kubectl get nodes"
  alias kd="kubectl describe"
  alias kdp="kubectl describe pod"
  alias kds="kubectl describe service"
  alias kdd="kubectl describe deployment"
  alias kl="kubectl logs"
  alias klf="kubectl logs -f"
  alias kex="kubectl exec -it"
  alias kaf="kubectl apply -f"
  alias kdf="kubectl delete -f"
  alias kctx="kubectl config use-context"
  alias kns="kubectl config set-context --current --namespace"
fi
