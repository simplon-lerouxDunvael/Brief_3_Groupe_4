sudo su - 
apt-get update 
apt-get install -y openjdk-11-jdk 
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | tee \  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \  https://pkg.jenkins.io/debian-stable binary/ | tee \  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update && apt-get install -y jenkins
#if $?...; then
#    echo "ERROR"
#    exit 1
#fi
systemctl enable jenkins --now

cat /var/lib/jenkins/secrets/initialAdminPassword