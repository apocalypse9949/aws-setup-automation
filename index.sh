#!/bin/bash
set -e

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run as root. Try using: sudo ./setup.sh"
  exit 1
fi

echo "Updating system and installing required packages..."
yum update -y
yum install -y java-17-amazon-corretto-devel maven git nginx unzip curl wget nano --allowerasing

echo "Configuring Java environment..."
export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto.x86_64
export PATH=$JAVA_HOME/bin:$PATH
ln -sf $JAVA_HOME/bin/java /usr/bin/java
ln -sf $JAVA_HOME/bin/javac /usr/bin/javac

echo "Verifying Java installation:"
java -version

# Tomcat Installation
echo "Downloading and extracting Apache Tomcat 9.0.89..."
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.89/bin/apache-tomcat-9.0.89.tar.gz
tar -xvzf apache-tomcat-9.0.89.tar.gz
mv apache-tomcat-9.0.89 tomcat9
chmod +x tomcat9/bin/*.sh

# Update Tomcat port
echo "Updating Tomcat port from 8080 to 9090..."
sed -i 's/port="8080"/port="9090"/' tomcat9/conf/server.xml

# Configure Tomcat user roles
echo "Adding Tomcat user roles and credentials..."
sed -i '/<\/tomcat-users>/i \
<role rolename="manager-gui"/>\n\
<role rolename="manager-script"/>\n\
<user username="admin" password="admin" roles="manager-gui,manager-script"/>' tomcat9/conf/tomcat-users.xml

# Allow remote access to management interfaces
echo "Enabling remote access to manager and host-manager applications..."
for file in tomcat9/webapps/manager/META-INF/context.xml tomcat9/webapps/host-manager/META-INF/context.xml; do
  sed -i 's/<Valve /<!-- <Valve /' "$file"
  sed -i 's/\/> -->/\/> -->/' "$file"
done

# Start Tomcat
echo "Starting Tomcat service..."
cd tomcat9/bin
export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto.x86_64
export PATH=$JAVA_HOME/bin:$PATH
./startup.sh
cd ~

echo "Tomcat is now running on port 9090."
echo "Access it via: http://<your-ec2-ip>:9090"

# Jenkins Installation
echo "Installing Jenkins..."
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install -y jenkins

# Start Jenkins service
echo "Starting and enabling Jenkins service..."
systemctl start jenkins
systemctl enable jenkins

echo "Jenkins is installed and running on port 8080."
echo "Access it via: http://<your-ec2-ip>:8080"
echo "Ensure that ports 8080 and 9090 are open in the instance's security group."
