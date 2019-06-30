# KuberPi
A Kubernetes cluster built with Ansible and Python

These files are meant to be a starting point and any keys, passwords, or other sensitive strings should be changed prior to production use.

All files are meant to be run in numbered order

## Image used for all 7 nodes
I chose the Hypriot image as it comes preconfigure with Docker and all changes made to operating system to support containers. You'll see in the first playbook that the only change required is a change to swap using dphys-swapfile.
https://blog.hypriot.com/downloads/
