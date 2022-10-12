#!/bin/sh

#---------------------------Database Configuration---------------------------------------

#Install FirewallD
echo "\033[0;32mInstalling FirewallD.....\033[0m"
sudo yum install -y firewalld
sudo service firewalld start
sudo systemctl enable firewalld

#Install MariaDB
echo "\033[0;32mInstalling MariaDB.....\033[0m"
sudo yum install -y mariadb-server
sudo service mariadb start
sudo systemctl enable mariadb

#Configure firewall for Database
echo "\033[0;32mConfigureing firewall.....\033[0m"
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

#Configure Database
echo "\033[0;32mConfigureing Database.....\033[0m"
cat > configure-db.sql -<< EOT
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOT

sudo mysql < configure-db.sql


#Create the db-load-script.sql
echo "\033[0;32mCreating the db-load-script.sql.....\033[0m"
cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF

sudo mysql < db-load-script.sql

#---------------------------Web Server Configuration---------------------------------------

#Install required packages
echo "\033[0;32mInstalling required web server packages.....\033[0m"
sudo yum install -y httpd php php-mysqlnd
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

#Configure httpd
echo "\033[0;32mConfigureing httpd.....\033[0m"
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

#Start httpd
echo "\033[0;32mStarting httpd.....\033[0m"
sudo service httpd start
sudo systemctl enable httpd

#Download code
echo "\033[0;32mDownloadding code.....\033[0m"
sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

#Update index.php
echo "\033[0;32mUpdateing index.php.....\033[0m"
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

