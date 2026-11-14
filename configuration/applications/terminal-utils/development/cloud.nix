# Kubernetes administration and container editor tooling.
# Kept global because cluster management (kubectl, k9s, helm) and container/Compose LSPs
# are used across infrastructure, ops, and multiple projects rather than a single stack.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    k9s
    kubectl
    kubernetes-helm
    docker-compose-language-service
    dockerfile-language-server
    docker-ls
    hadolint
  ];
}
