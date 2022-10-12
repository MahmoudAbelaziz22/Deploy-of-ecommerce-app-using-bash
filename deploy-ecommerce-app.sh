#!/bin/sh

#--------------------------------Functions-----------------------------------------------
function print_colored() {
   case $1 in
     "green") COLOR="\033[0;32m" ;;
     "red") COLOR="\033[0;31m" ;;
     "*") COLOR="\033[0m"
    esac
   echo -e "${COLOR} $2 ${NC}" 
}

function check_service_status() {
    service_name= $1
    is_service_active="$(sudo systemctl is-active ${service_name})"
    if [ ${is_service_active}="active" ]
    then
       print_colored "green" "${service_name} Service is active."
    else
       print_colored "red" "${service_name} Service is not active." 
       exit 1
    fi
}

function is_firewalld_rule_configured() {
    firewall_ports=$(sudo firewall-cmd --list-all --zone=public |grep ports)

    port_number=$1
    if [[ $firewall_ports = *$port_number* ]]
    then
      print_colored "green" "Port ${port_number} Configured."
    else
      print_colored "red" "Prot ${port_number} not Configured."
    fi 

}

#---------------------------Database Configuration---------------------------------------

#Install FirewallD
print_colored "green" "Installing FirewallD....."
sudo yum install -y firewalld
#sudo service firewalld start
sudo systemctl start firewalld 
sudo systemctl enable firewalld

is_firewallD_active=$(sudo systemctl is-active firewalld)

check_service_status "firewalld"

#Install MariaDB
print_colored "green" "Installing MariaDB....."
sudo yum install -y mariadb-server
#sudo service mariadb start
sudo systemctl start mariadb
sudo systemctl enable mariadb

check_service_status mariadb

#Configure firewall for Database
print_colored "green" "Configureing firewall....."
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

is_firewalld_rule_configured 3306

#Configure Database
print_colored "green" "Configureing Database....."
cat > configure-db.sql -<< EOT
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOT

sudo mysql < configure-db.sql


#Create the db-load-script.sql
print_colored "green" "Creating the db-load-script.sql....."
cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF

sudo mysql < db-load-script.sql

#---------------------------Web Server Configuration---------------------------------------

#Install required packages
print_colored "green" "Installing required web server packages....."
sudo yum install -y httpd php php-mysqlnd
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

is_firewalld_rule_configured 80

#Configure httpd
print_colored "green" "Configureing httpd....."
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

#Start httpd
print_colored "green" "Starting httpd....."
#sudo service httpd start
sudo systemctl start httpd 
sudo systemctl enable httpd

check_service_status httpd

#Download code
print_colored "green" "Downloadding code....."
sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

#Update index.php
print_colored "green" "Updateing index.php....."
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

print_colored "green" "Doneeeeeeee....."

web_page=$(curl http://localhost)

if [[ $web_page = *Laptop* ]]
then
  print_colored "green" "Item Laptop is exist."
else
  print_colored "red" "Item Laptop is not exist."
fi