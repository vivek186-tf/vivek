#!/bin/bash
sudo apt-get update
sudo apt install openjdk-8-jdk -y
sudo apt install mysql-server -y
userpath=/home/vivek
home_user=vivek
mkdir -p $userpath/ovaledge
ovaledge_artifacts_folder=/home/vivek/ovaledge
mkdir -p $ovaledge_artifacts_folder/jars
mkdir -p $ovaledge_artifacts_folder/SSL
mkdir -p $ovaledge_artifacts_folder/extprop
wget https://ovaledge-jars.s3.amazonaws.com/third_party_jars/third_party_jars_latest/apache-tomcat-9.0.70.tar.gz -P $ovaledge_artifacts_folder/
wget https://ovaledge.s3.us-west-1.amazonaws.com/Release+Builds/Release6.0/Final/Scripts/MasterScripts.sql -P $ovaledge_artifacts_folder/
wget https://ovaledge.s3.us-west-1.amazonaws.com/Release+Builds/Release6.0/Final/Build/ovaledge.war -P $ovaledge_artifacts_folder/
wget https://jenkins-ovaledge-s3.s3.amazonaws.com/Internal_Release6.0.0.X/240/csp-lib-6.0.jar -P $ovaledge_artifacts_folder/jars/
wget https://mckinseytesting.s3.us-east-2.amazonaws.com/oasis.properties -P $ovaledge_artifacts_folder/extprop
tar -xvzf $ovaledge_artifacts_folder/apache-tomcat-9.0.70.tar.gz -C $ovaledge_artifacts_folder/
echo mysql User credentails
mysql_host=vi-mysql.mysql.database.azure.com
mysql_username=cat /c/Users/Admin/Downloads/terra-keyvault/username.txt
mysql_password=cat /c/Users/Admin/Downloads/terra-keyvault/password.txt
sudo mysql -h $mysql_host -u $mysql_username -p$mysql_password < $ovaledge_artifacts_folder/MasterScripts.sql
sed -i "s/localhost:3306/$mysql_host:3306/g" $ovaledge_artifacts_folder/extprop/oasis.properties
sed -i "s/username=ovaledge/username=$mysql_username/g" $ovaledge_artifacts_folder/extprop/oasis.properties
sed -i "s/password=0valEdge!/password=$mysql_password/g" $ovaledge_artifacts_folder/extprop/oasis.properties
sudo mysql -h $mysql_host -u $mysql_username -p$mysql_password> -e "SET GLOBAL ssl_enforcement = OFF;"
echo  Creating setenv.sh file for extprop setup
echo 'export CATALINA_OPTS="-Duse.http=true -Dext.properties.dir=file:'$ovaledge_artifacts_folder'/extprop/"' > $ovaledge_artifacts_folder/apache-tomcat-9.0.70/bin/setenv.sh
echo tomcat starting
cp -r $ovaledge_artifacts_folder/ovaledge.war $ovaledge_artifacts_folder/apache-tomcat-9.0.70//webapps
sudo chown -R $home_user:$home_user $ovaledge_artifacts_folder/
sudo echo "[Unit]
Description=Apache Tomcat Web Application Container
After=network.target
[Service]
Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64/
Environment=CATALINA_HOME="$ovaledge_artifacts_folder"/apache-tomcat-9.0.70
Environment=CATALINA_BASE="$ovaledge_artifacts_folder"/apache-tomcat-9.0.70
ExecStart="$ovaledge_artifacts_folder"/apache-tomcat-9.0.70/bin/startup.sh
ExecStop="$ovaledge_artifacts_folder"/apache-tomcat-9.0.70/bin/shutdown.sh
User="$home_user"
Group="$home_user"
UMask=0007
RestartSec=10
Restart=always
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/tomcat.service
sudo systemctl daemon-reload
sudo systemctl enable tomcat.service
sudo systemctl start tomcat
~
~
~
~
~



