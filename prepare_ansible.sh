#!/bin/bash

gluster_servers=2
public_subnet=172.16.0.0/24
private_subnet=172.16.1.0/24
intel_mpi=true
intel_mpi_version=2019.4-070
configure_nfs=true
nfs_mount_path=/mnt/nfs-share
scheduler=NONE
gluster_share=true
gluster_servers=2
openfoam_install=true
openfoam_path=/mnt/gluster-share/


sudo yum install -y nmap
rm /tmp/hosts
for i in `nmap -sL ${private_subnet} | grep "Nmap scan report for" | grep ")" | awk '{print $6}'`;do echo ${i:1:-1} >> /tmp/hosts; done


echo [bastion] > playbooks/inventory
echo `hostname` ansible_host=`ifconfig | grep 'netmask 255.255.255.0  broadcast' | awk '{print $2}'` ansible_user=opc role=bastion >> playbooks/inventory
echo [compute] >> playbooks/inventory
for i in `cat /tmp/hosts`; do echo `ssh -o StrictHostKeyChecking=no $i 'hostname'` ansible_host=$i ansible_user=opc role=compute >> playbooks/inventory;done
echo [nfs] >> playbooks/inventory
for i in `head -1 /tmp/hosts`; do echo `ssh -o StrictHostKeyChecking=no $i 'hostname'` >> playbooks/inventory;done
echo [gluster] >> playbooks/inventory
for i in `tail -$gluster_servers /tmp/hosts`; do echo `ssh -o StrictHostKeyChecking=no $i 'hostname'` >> playbooks/inventory;done
cat >> playbooks/inventory <<- EOF
[all:children]
bastion
compute
[all:vars]
ansible_connection=ssh
ansible_user=opc
rdma_network=192.168.168.0
rdma_netmask=255.255.252.0
public_subnet=${public_subnet}
private_subnet=${private_subnet}
intel_mpi=${intel_mpi}
intel_mpi_version=${intel_mpi_version}
configure_nfs=${configure_nfs}
nvme_path=/mnt/localdisk/
nfs_export_path=/mnt/localdisk/nfs-share
nfs_mount_path=${nfs_mount_path}
scheduler=${scheduler}
gluster_share=${gluster_share}
gluster_servers=${gluster_servers}
openfoam_install=${openfoam_install}
openfoam_path=${openfoam_path}
EOF
