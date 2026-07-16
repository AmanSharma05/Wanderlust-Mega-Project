#!/bin/bash
#Can remove sudo as it is already running as root user
set -e

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting DevSecOps Server Provisioning"

JAVA_PACKAGE="openjdk-21-jdk"
KUBECTL_VERSION="v1.33.2"
EKSCTL_VERSION="v0.214.0"
HELM_VERSION="v3.18.4"
AWSCLI_VERSION="2.30.1"
TRIVY_VERSION="0.72.0"
DEPENDENCY_CHECK_VERSION="12.1.8"
SONARQUBE_IMAGE="sonarqube:lts-community"
PLUGIN_MANAGER_VERSION="2.13.2"


echo "Updating package repositories..."
sudo apt update -y

sudo apt install -y \
git \
curl \
wget \
jq \
unzip \
ca-certificates \
gnupg \
lsb-release

echo "Installing Docker..."

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y

sudo apt install -y \
docker-ce \
docker-ce-cli \
containerd.io \
docker-buildx-plugin \
docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu


echo "Installing Java..."
sudo apt install -y ${JAVA_PACKAGE}
java -version

echo "Installing Jenkins..."

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
| sudo tee \
/usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
| sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install -y jenkins
mkdir -p /etc/systemd/system/jenkins.service.d
cat <<EOF >/etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_OPTS=-Djenkins.install.runSetupWizard=false"
EOF

systemctl daemon-reload
cd /tmp
rm -rf Wanderlust-Mega-Project #Idempotent check to remove the repo if it already exists
git clone https://github.com/AmanSharma05/Wanderlust-Mega-Project.git

mkdir -p /var/lib/jenkins/init.groovy.d
cp -r \
/tmp/Wanderlust-Mega-Project/terraform/jenkins/init.groovy.d/* \
/var/lib/jenkins/init.groovy.d/

cp \
/tmp/Wanderlust-Mega-Project/terraform/jenkins/plugins.txt \
/tmp/plugins.txt

systemctl enable jenkins
systemctl start jenkins
sleep 10

wget -q -O /tmp/jenkins-plugin-manager.jar \
https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/${PLUGIN_MANAGER_VERSION}/jenkins-plugin-manager-${PLUGIN_MANAGER_VERSION}.jar


java -jar /tmp/jenkins-plugin-manager.jar \
  --war /usr/share/java/jenkins.war \
  --plugin-file /tmp/plugins.txt \
  --plugin-download-directory /var/lib/jenkins/plugins

sudo systemctl enable jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart docker
sudo systemctl restart jenkins

echo "Installing Trivy ${TRIVY_VERSION}..."

wget \
https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.deb

sudo dpkg -i trivy_${TRIVY_VERSION}_Linux-64bit.deb

rm trivy_${TRIVY_VERSION}_Linux-64bit.deb

echo "Installing AWS CLI ${AWSCLI_VERSION}..."

cd /tmp

curl -L \
"https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" \
-o awscliv2.zip

unzip -q awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip

echo "Installing OWASP Dependency Check ${DEPENDENCY_CHECK_VERSION}..."

cd /opt
sudo wget \
https://github.com/dependency-check/DependencyCheck/releases/download/v${DEPENDENCY_CHECK_VERSION}/dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip

sudo unzip -q dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip
sudo mv dependency-check dependency-check-${DEPENDENCY_CHECK_VERSION}
sudo ln -sf \
/opt/dependency-check-${DEPENDENCY_CHECK_VERSION}/bin/dependency-check.sh \
/usr/local/bin/dependency-check
sudo rm dependency-check-${DEPENDENCY_CHECK_VERSION}-release.zip


echo "Pulling SonarQube image..."
sudo docker pull ${SONARQUBE_IMAGE}
echo "Starting SonarQube container..."
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w vm.max_map_count=524288
sudo docker run -d \
--name SonarQube-server \
--restart unless-stopped \
-p 9000:9000 \
${SONARQUBE_IMAGE}

sudo apt autoremove -y
sudo apt autoclean

echo "Docker:"
docker --version

echo ""
echo "Docker Compose:"
docker compose version

echo ""
echo "Java:"
java -version

echo ""
echo "Jenkins Status:"
systemctl is-active jenkins || true

echo ""
echo "Trivy:"
trivy --version

echo ""
echo "AWS CLI:"
aws --version

echo ""
echo "OWASP Dependency Check:"
dependency-check --version

echo ""
echo "Docker Containers:"
docker ps

echo ""
echo "Jenkins : http://<EC2-PUBLIC-IP>:8080"
echo "SonarQube : http://<EC2-PUBLIC-IP>:9000"
