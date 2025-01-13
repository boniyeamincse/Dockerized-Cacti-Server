# Dockerfile for setting up a Cacti server on Ubuntu 20.04
# Author: Boney Yamin
# Date: 2025-01-13
# Description: This Dockerfile sets up a Cacti server with Apache, MariaDB, and PHP on Ubuntu 20.04.

# Use Ubuntu 20.04 as the base image
FROM ubuntu:20.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update packages and install necessary dependencies
RUN apt-get update -y && apt-get install -y \
    apache2 \
    mariadb-server \
    php \
    php-mysql \
    libapache2-mod-php \
    php-xml \
    php-ldap \
    php-mbstring \
    php-gd \
    php-gmp \
    snmp \
    php-snmp \
    rrdtool \
    librrds-perl \
    unzip \
    curl \
    git \
    gnupg2 \
    && apt-get clean

# Configure PHP settings
RUN PHP_INI_DIR=$(php -i | grep "Loaded Configuration File" | awk '{print $5}') && \
    sed -i 's/memory_limit = .*/memory_limit = 512M/' "$PHP_INI_DIR" && \
    sed -i 's/max_execution_time = .*/max_execution_time = 60/' "$PHP_INI_DIR" && \
    echo "date.timezone = Asia/Dhaka" >> "$PHP_INI_DIR"

# Configure MariaDB
RUN service mysql start && \
    mysql -e "CREATE DATABASE cactidb;" && \
    mysql -e "GRANT ALL ON cactidb.* TO cactiuser@localhost IDENTIFIED BY 'Akijgroup@1234';" && \
    mysql -e "FLUSH PRIVILEGES;" && \
    mysql -e "GRANT SELECT ON mysql.time_zone_name TO cactiuser@localhost;" && \
    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql

# Download and set up Cacti
RUN wget https://www.cacti.net/downloads/cacti-latest.tar.gz && \
    tar -zxvf cacti-latest.tar.gz && \
    mv cacti-1* /var/www/html/cacti && \
    mysql cactidb < /var/www/html/cacti/cacti.sql

# Set permissions for Cacti
RUN chown -R www-data:www-data /var/www/html/cacti/ && \
    chmod -R 775 /var/www/html/cacti/ && \
    touch /var/www/html/cacti/log/cacti.log

# Configure Apache
RUN echo "Alias /cacti /var/www/html/cacti" > /etc/apache2/sites-available/cacti.conf && \
    echo "<Directory /var/www/html/cacti>" >> /etc/apache2/sites-available/cacti.conf && \
    echo "  Options +FollowSymLinks" >> /etc/apache2/sites-available/cacti.conf && \
    echo "  AllowOverride None" >> /etc/apache2/sites-available/cacti.conf && \
    echo "  Require all granted" >> /etc/apache2/sites-available/cacti.conf && \
    echo "</Directory>" >> /etc/apache2/sites-available/cacti.conf && \
    a2ensite cacti && \
    systemctl restart apache2

# Expose necessary ports
EXPOSE 80

# Start Apache in the foreground
CMD ["apachectl", "-D", "FOREGROUND"]
