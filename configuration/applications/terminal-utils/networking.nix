# Networking, VPN, and remote filesystem tools.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    openvpn
    sshfs
    nmap
    dig
  ];
}
