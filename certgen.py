#!/usr/bin/python
import readline
import os
import time

user = raw_input("Enter your username: ")
group = raw_input("Enter your RBAC group: ")
print("[+]Generate Private Key")
os.system("openssl genrsa -out $HOME/{}.key 2048".format(user))
print("[+]Create CSR")
os.system("openssl req -new -key $HOME/{}.key -out $HOME/{}.csr -subj '/CN={}/O={}'".format(user, user, user, group))
print("[+]Sign CSR")
os.system("sudo openssl x509 -req -in $HOME/{}.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out $HOME/{}.crt".format(user, user))
print("[+]Register Kubectl Credentials")
os.system("kubectl config set-credentials {} --client-certificate=$HOME/{}.crt --client-key=$HOME/{}.key --embed-certs=true".format(user, user, user))
print("[+]Set Kubectl Context")
os.system("kubectl config set-context {}@kubernetes --cluster=kubernetes --user={}".format(user, user))
print("[+]Assign RBAC Permissions")
os.system("kubectl create clusterrolebinding {}-admin-binding --clusterrole=cluster-admin --group={}".format(user, group))
print("[+]Test Context")
os.system("kubectl config use-context {}@kubernetes".format(user))
print("[+]Assign RBAC Permissions")
os.system("kubectl get pods --all-namespaces")
print("[+]Reset Context")
os.system("kubectl config use-context kubernetes-admin@kubernetes")
