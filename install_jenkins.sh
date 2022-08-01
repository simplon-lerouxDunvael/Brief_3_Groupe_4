sudo su - 
apt-get update 


### Installation LVM
apt-get -y install lvm2 && /etc/init.d/lvm start

### Création Volume Physique
pvcreate /dev/sdc 

vgcreate monGV-GR4 /dev/sdc  

### Créer un Volume logique dans un VG
lvcreate -n monLV-GR4-LOG -L 20g monGV-GR4 -y
lvcreate -n monLV-GR4-USERS -L 30g monGV-GR4 -y

### Formater le disque logique dans le système de fichiers souhaité 
sleep 15


mkfs -t ext4 /dev/monGV-GR4/monLV-GR4-LOG
mkfs -t ext4 /dev/monGV-GR4/monLV-GR4-USERS

mv /var/log /var/log2 

mount /dev/monGV-GR4/monLV-GR4-LOG /var/log
mount /dev/monGV-GR4/monLV-GR4-USERS /var/lib/jenkins/userContent

mv -f /var/log2/* /var/log 
rmdir log2

apt-get install -y openjdk-11-jdk 
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | tee \  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \  https://pkg.jenkins.io/debian-stable binary/ | tee \  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update && apt-get -y install jenkins

systemctl enable jenkins --now

cat /var/lib/jenkins/secrets/initialAdminPassword
