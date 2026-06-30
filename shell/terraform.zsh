# ┌─────────────────────────────────────────────────────────────────┐
# │ Terraform Aliases                                               │
# └─────────────────────────────────────────────────────────────────┘

if command -v terraform &>/dev/null; then
  alias tf="terraform"
  alias tfi="terraform init"
  alias tfp="terraform plan"
  alias tfa="terraform apply"
  alias tfd="terraform destroy"
  alias tfw="terraform workspace"
  alias tfo="terraform output"
  alias tff="terraform fmt"
  alias tfv="terraform validate"
  alias tfs="terraform state"
  alias tfim="terraform import"
fi
