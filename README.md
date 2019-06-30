# KuberPi
A Kubernetes cluster built with Ansible and Python

These files are meant to be a starting point and any keys, passwords, or other sensitive strings should be changed prior to production use. I used 7 nodes for my Kubernetes cluster: 2 masters, 3 workers, and 2 loadbalancers. 

All playbooks are meant to be run in numbered order.

## Image used for all 7 nodes
I chose the Hypriot image as it comes preconfigure with Docker and all changes made to operating system to support containers. You'll see in the first playbook that the only change required is a change to swap using dphys-swapfile.
https://blog.hypriot.com/downloads/

## Inspiration articles
I had the idea to do something cool with all of my extra Raspberry Pis and consulted many articles to fine tune the files I now use.
- https://medium.com/nycdev/k8s-on-pi-9cc14843d43
- https://kubecloud.io/setting-up-a-kubernetes-1-11-raspberry-pi-cluster-using-kubeadm-952bbda329c8
