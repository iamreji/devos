# ┌─────────────────────────────────────────────────────────────────┐
# │ Kubernetes Aliases                                              │
# └─────────────────────────────────────────────────────────────────┘

if command -v kubectl &>/dev/null; then
  # Core
  alias k="kubectl"
  alias kg="kubectl get"
  alias kga="kubectl get all"
  alias kgp="kubectl get pods"
  alias kgs="kubectl get services"
  alias kgd="kubectl get deployments"
  alias kgn="kubectl get nodes"
  alias kgns="kubectl get namespaces"
  alias kgsec="kubectl get secrets"
  alias kgcm="kubectl get configmaps"
  alias kgpv="kubectl get persistentvolumes"
  alias kgpvc="kubectl get persistentvolumeclaims"
  alias kging="kubectl get ingress"
  alias kgnp="kubectl get networkpolicies"
  alias kghpa="kubectl get hpa"
  alias ktail="kubectl get events --watch"
  # Describe
  alias kd="kubectl describe"
  alias kdp="kubectl describe pod"
  alias kds="kubectl describe service"
  alias kdd="kubectl describe deployment"
  alias kdn="kubectl describe node"
  alias kdns="kubectl describe namespace"
  # Logs
  alias kl="kubectl logs"
  alias klf="kubectl logs -f"
  alias klp="kubectl logs --previous"
  # Exec
  alias kex="kubectl exec -it"
  # Apply / Delete
  alias kaf="kubectl apply -f"
  alias kdf="kubectl delete -f"
  alias kdel="kubectl delete"
  alias kdpod="kubectl delete pod"
  # Debug
  alias kr="kubectl rollout"
  alias krs="kubectl rollout status"
  alias krh="kubectl rollout history"
  alias kru="kubectl rollout undo"
  alias kpf="kubectl port-forward"
  alias ktop="kubectl top"
  alias ktopn="kubectl top node"
  alias ktopp="kubectl top pod"
  # Context / Namespace
  alias kctx="kubectl config use-context"
  alias kcctx="kubectl config current-context"
  alias kns="kubectl config set-context --current --namespace"
  alias kgctx="kubectl config get-contexts"
  # Drain / Cordon
  alias kcordon="kubectl cordon"
  alias kuncordon="kubectl uncordon"
  alias kdrain="kubectl drain --ignore-daemonsets --delete-emptydir-data"
fi

# Helm
if command -v helm &>/dev/null; then
  alias h="helm"
  alias hl="helm list"
  alias hs="helm search"
  alias hi="helm install"
  alias hu="helm upgrade"
  alias hui="helm upgrade --install"
  alias hd="helm delete"
  alias hr="helm rollback"
  alias hg="helm get"
  alias hga="helm get all"
  alias hgv="helm get values"
  alias hgo="helm get manifest"
fi

# k9s
if command -v k9s &>/dev/null; then
  alias k9="k9s"
fi
