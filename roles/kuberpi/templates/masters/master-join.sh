#!/usr/bin/env bash
sudo {{ hostvars['master1'].kubeadm_token.stdout }} --experimental-control-plane --certificate-key {{ hostvars['master1'].kubeadm_certs.stdout_lines[2] }}
