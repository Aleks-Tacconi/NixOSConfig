# Kubernetes administration and container editor tooling.
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
