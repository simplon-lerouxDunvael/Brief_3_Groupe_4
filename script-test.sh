#!/bin/bash

# PREREQUIS INSTALLER LA LIBRAIRIE JQ ! apt install jq

NOMVM="debian-gr4"
NOMGR="testB" #CHANGER LE NOM
ADMINUSER="adminuser"
NOMVNET="vnetgr4"
NOMBASTION="BastionGr4"
NOMDISK="diskgr4"
LOCAL="JapanEast"
RSA="@authorized_keys" #"$HOME/.ssh/id_rsa.pub"
RETVAL=

MENU=6
####################################
#            M E N U               #
# 0 Installe tout                  #
# 1 Installe à partir du réseau    #
# 2 Installe à partir du Bastion   #
# 3 Installe à partir de la VM     #
# 4 Création du disque additionel  #
# 5 Connection ssh/bastion à la VM #
# 6 Backup                         #
####################################
# Effaceur de ressources
rollback() {
    desc="$1"
    echo "Erreur lié à $desc"
    if [ ! -z "$ITEMID"]; then
	    az backup protection disable --ids $ITEMID --delete-backup-data -y
    fi
    if [ ! -z "$VAULTID" ]; then
	    az backup vault delete --resource-group $NOMGR --name myRecoveryServicesVault -y --force
    fi
    az group delete -n $NOMGR -y
    exit 0
}

## fonction d'execution de commandes
## format: cmd "commande à executer", "description de la commande")
## retourne le resultat de l'execution de commande
cmd() {
    command=$1
    desc=$2
    RETVAL=$($command)
    if [ $? -ne 0 ]; then
        rollback "$desc" 
    fi
}

create_network() {
    echo " Création du vnet"
    cmd "az network vnet create --resource-group $NOMGR --name $NOMVNET --address-prefix 10.0.0.0/16 --subnet-name AzureBastionSubnet --subnet-prefix 10.0.0.0/24 --location $LOCAL" "vnet"
    vnet=$RETVAL
    echo " Création de l'IP bastion"
    cmd "az network public-ip create --resource-group $NOMGR --name ipbastion --sku Standard --allocation-method Static --sku Standard --location $LOCAL" "ip pour bastion"
    adresse_ipbastion=$RETVAL
    echo " Création de l'IP VM"
    cmd "az network public-ip create --resource-group $NOMGR --name ipvm --sku Standard --allocation-method Static --sku Standard --location $LOCAL" "ip pour vm"
    adresse_ipvm=$RETVAL
}

create_bastion() {
    echo " Création du bastion"
    cmd "az network bastion create --location $LOCAL --name $NOMBASTION --public-ip-address ipbastion --resource-group $NOMGR --vnet-name $NOMVNET" "Création_Bastion"
    BAS=$RETVAL
    IDBAST=$(echo $BAS | jq -r ".id")

}

create_vm() {
    echo " Création de la VM"
    cmd "az vm create -n $NOMVM -g $NOMGR --image Debian:debian-11:11:latest --ssh-key-values $RSA --generate-ssh-keys --public-ip-sku Standard --admin-username $ADMINUSER --vnet-name $NOMVNET --subnet-address-prefix 10.0.1.0/24 --public-ip-address ipvm --subnet SubVM --location $LOCAL" "création_VM"
    RES=$RETVAL
    IPVM=$(echo $RES | jq -r ".publicIpAddress")
    IDVM=$(echo $RES | jq -r ".id")
        echo "###############################"
        echo "# IP DE LA VM : $IPVM  #"
        echo "###############################" 
    echo " Ouverture des ports 22, 8080 et 80 "
    cmd "az vm open-port --port 80 --resource-group $NOMGR --name $NOMVM --priority 155" "ouverture port 80"
    cmd "az vm open-port --port 8080 --resource-group $NOMGR --name $NOMVM --priority 159" "ouverture port 8080"
    cmd "az vm open-port --port 22 --resource-group $NOMGR --name $NOMVM --priority 158" "ouverture port 22"
    cmd "az extension add --name ssh" "disk ssh"

}

create_disk() {
    echo " Création du disque"
    cmd "az disk create --name $NOMDISK --resource-group $NOMGR --size-gb 64 --location $LOCAL --encryption-type EncryptionAtRestWithPlatformKey" "création du disque"
    echo " Voir l'ID Disk"
    diskId=$(az disk show -g $NOMGR -n $NOMDISK --query 'id' -o tsv)
    #az vm disk attach -g $NOMGR --vm-name $NOMVM --name $diskId
    cmd "az vm disk attach -g $NOMGR --vm-name $NOMVM --name $diskId" "attachement du disque"

}

create_connect() {
    echo " Installation du script Jenkins :"
    out=$(az vm run-command invoke -g $NOMGR -n $NOMVM --command-id RunShellScript --scripts @install_jenkins.sh)
    JENKEY=$(echo $out | jq -r '.value[0].message' | grep -B2 '\[stderr\]' | head -1)
    echo " Ouverture du tunneling"
    cmd "az resource update --ids $IDBAST --set properties.enableTunneling=True" "update des ressources"
    echo "##################################################"
    echo "# Installation OK, pour terminer :               #"
    echo "# Aller sur :  http://$IPVM:8080         #"
    echo "# Clée Jenkin : $JENKEY        #"
    echo "##################################################"
    $PASS2=$(az vm run-command invoke -g $NOMGR -n $NOMVM --command-id RunShellScript --scripts "cat /var/lib/jenkins/secrets/initialAdminPassword")
    echo "# Clée Jenkin MÉTHODE 2 : $PASS2        #"
    echo " Connection à la VM via Bastion"
    #az network bastion ssh --target-resource-id $IDVM --auth-type "ssh-key" --username $ADMINUSER --ssh-key "$HOME/.ssh/id_rsa.pub" --name $NOMBASTION --resource-group $NOMGR

}

create_backup() {
    echo " Création de la sauvegarde/Backup :"
    az backup vault create --location $LOCAL --name MyRecoveryServicesVault --resource-group $NOMGR
    echo "NOMGR = ${NOMGR}"
    SORTIE=$(az backup vault show --name MyRecoveryServicesVault --resource-group $NOMGR)
    echo "etape toto avec ${SORTIE}:"
    VAULTID=$(az backup vault show --name MyRecoveryServicesVault --resource-group $NOMGR | jq -r '.id')
    echo "etape titi: VAULTID = ${VAULTID}."
    az resource update --ids ${VAULTID}/backupconfig/vaultconfig --set properties.softDeleteFeatureState=disabled
    #az backup protection check-vm -g $NOMGR --vm $NOMVM
    az backup vault backup-properties set --name myRecoveryServicesVault --resource-group $NOMGR --backup-storage-redundancy LocallyRedundant
    echo "Nom de la VM: ${NOMVM}."
    az backup protection enable-for-vm --resource-group $NOMGR --vault-name myRecoveryServicesVault --vm $NOMVM --policy-name DefaultPolicy
    ITEMIDS=$(az backup item list -g $NOMGR -v myRecoveryServicesVault | jq -r '.[0].id')
    az backup protection backup-now --ids $ITEMIDS --retain-until 15-08-2022
}
    <<EOF
    echo " Installation du script Jenkins :"
    # Créer un coffre recovery services
    az backup vault create --resource-group $NOMGR --name myRecoveryServicesVault --$LOCAL
    az backup vault backup-properties set --name myRecoveryServicesVault --resource-group $NOMGR --backup-storage-redundancy "LocallyRedundant/GeoRedundant"
    # Activer la sauvegarde pour une machine virtuelle Azure
    az backup protection enable-for-vm --resource-group $NOMGR --vault-name myRecoveryServicesVault --vm $NOMVM --policy-name DefaultPolicy
    az backup protection enable-for-vm --resource-group $NOMGR --vault-name myRecoveryServicesVault --vm $IDVM --policy-name DefaultPolicy
    # Démarrer la sauvegarde
    az backup protection backup-now --resource-group $NOMGR --vault-name myRecoveryServicesVault --container-name $NOMVM --item-name $NOMVM --backup-management-type AzureIaaSVM --retain-until jj-mm-aaaa
    # Surveiller le travail de sauvegarde
    az backup job list --resource-group $NOMGR --vault-name myRecoveryServicesVault --output table
    # Nettoyer le déploiement
    az backup protection disable --resource-group $NOMGR --vault-name myRecoveryServicesVault --container-name $NOMVM --item-name $NOMVM --backup-management-type AzureIaaSVM --delete-backup-data true
    az backup vault delete --resource-group $NOMGR --name myRecoveryServicesVault
    az group delete --name $NOMGR
}
EOF

if [ $MENU -lt 1 ]; then
    cmd "az group create --location $LOCAL --name $NOMGR" "création de groupe"
    RG=$RETVAL
    echo "Création du ressource groupe: $NOMGR"
fi
if [ $MENU -lt 2 ]; then
    create_network
fi
if [ $MENU -lt 3 ]; then
    create_bastion
fi
if [ $MENU -lt 4 ]; then
    create_vm
fi
if [ $MENU -lt 5 ]; then
    create_disk
fi
if [ $MENU -lt 6 ]; then
    create_connect
fi
if [ $MENU -lt 7 ]; then
    create_backup
fi


    #if [[ $1=="del" ]]; then
    #rollback
    #fi
exit 0

# az vm wait # permet de mettre en attente la CLI jusqu'a ce qu'une condition soit remplie
# Extention pour avoir toute les commandes et option disponible
# az interactive 
# installation SSH    
# az ssh
# CRÉATION DE LA VM  ==> jq -r == | sed -e "s/\"//g") pour enlever les ""
# creation des disques et attachement
# SSHVM=$(az sshkey show --ids $IDVM --name $NOMVM --resource-group $NOMGR)
### cat <<EOF | az network bastion ssh --target-resource-id $IDVM --auth-type "ssh-key" --username $ADMINUSER --ssh-key "$HOME/.ssh/id_rsa.pub" --name $NOMBASTION --resource-group $NOMGR 
### ls -l /
### pwd
### exit 0
### EOF

# activer le tunneling dans bastion
# az resource update --ids <bastion resource ids> --set properties.enableTunneling=True
# az vm run-command invoke -g $NOMGR -n $NOMVM --command-id RunShellScript --scripts "sudo su - && apt update && apt -y upgrade && apt install -y default-jdk && groupadd tomcat && apt -y install tomcat9 tomcat9-admin "
# commande script bash Azure
# az vm run-command invoke -g MyResourceGroup -n MyVm --command-id RunShellScript --scripts 'echo $1 $2' --parameters hello world
