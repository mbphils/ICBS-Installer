#!/bin/bash

display_menu() {
    echo "1. Install pre-requisites"
    echo "2. Install Postgresql 9.6"
    echo "3. Install Java 7"
    echo "4. Install Glassfish 4"
    echo "5. Install Jasper 6"
    echo "6. Create Autostart Glassfish"
    echo "7. Create Autostart Jasper"
    echo "8. Exit"
}

update_sshd_config() {
    sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/#Port 22/Port 66/' /etc/ssh/sshd_config
    printf "SSH Port: assigned to 66.\n"
    sleep 5
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl enable ssh
    sudo systemctl restart sshd || { printf "Failed to restart SSH service\n"; return 1; }
}

install_prerequisites() {
    printf "Installing Pre-requisites... \n"
    sleep 3
    sudo apt install wget htop net-tools unzip openssh-server pgadmin3 -y
    update_sshd_config
    printf "Pre-requisites Installed Successfully!\n"
    return 0
}

install_postgresql() {
    if sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - &&
        echo "deb https://apt-archive.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/postgresql-pgdg.list > /dev/null &&
        sudo apt update &&
        sudo apt install postgresql-9.6 -y &&
        sudo sed -i 's/#listen_addresses = '\''localhost'\''/listen_addresses = '\''*'\''/g' /etc/postgresql/9.6/main/postgresql.conf &&
install_java() {
    sudo wget -P /home/xmanager/ https://github.com/mbphils/ICBS-Installer/releases/download/Required-Files/jdk-7u80-linux-x64.tar.gz || { printf "Failed to download Java JDK"; return 1; }

    if sudo mkdir -p /usr/local/java &&
        sudo mv jdk-7u80-linux-x64.tar.gz /usr/local/java/ &&
        cd /usr/local/java &&
        sudo tar xvzf jdk-7u80-linux-x64.tar.gz &&
        sudo sed -i '/^export JAVA_HOME=/d; /^export JRE_HOME=/d; /^export PATH=\$PATH:\$JAVA_HOME\/bin:\$JRE_HOME\/bin/d; $ a\export JAVA_HOME=/usr/local/java/jdk1.7.0_80\nexport JRE_HOME=/usr/local/java/jdk1.7.0_80/jre\nexport PATH=\$PATH:\$JAVA_HOME\/bin:\$JRE_HOME\/bin' /etc/profile &&
        source /etc/profile &&
        sudo update-alternatives --install "/usr/bin/java" "java" "/usr/local/java/jdk1.7.0_80/bin/java" 1 &&
        sudo update-alternatives --install "/usr/bin/javac" "javac" "/usr/local/java/jdk1.7.0_80/bin/javac" 1 &&
        sudo update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/local/java/jdk1.7.0_80/bin/javaws" 1 &&
        sudo update-alternatives --set java /usr/local/java/jdk1.7.0_80/bin/java &&
        sudo update-alternatives --set javac /usr/local/java/jdk1.7.0_80/bin/javac &&
        sudo update-alternatives --set javaws /usr/local/java/jdk1.7.0_80/bin/javaws &&
        java -version; then
        printf "\n Java Successfully Installed \n";
        return 0
    else
        echo "Something went wrong :("
        return 1
    fi
}

install_glassfish() {
       printf "Commencing Glassfish 4 Installation... \n" &&
    if sudo wget -P /home/xmanager https://github.com/mbphils/ICBS-Installer/releases/download/Required-Files/glassfish-4.1.2.zip &&
        sudo unzip /home/xmanager/glassfish-4.1.2.zip &&
        sudo /home/xmanager/glassfish4/glassfish/bin/asadmin start-domain &&
        printf "Change admin password manually\n" &&
        sudo /home/xmanager/glassfish4/glassfish/bin/asadmin change-admin-password &&
        printf "Enabling secure admin\n" &&
        sudo /home/xmanager/glassfish4/glassfish/bin/asadmin enable-secure-admin &&
        printf "Restarting domain....\n" &&
        sudo /home/xmanager/glassfish4/glassfish/bin/asadmin restart-domain &&
        printf "Creating JDBC Pool...\n" &&
        sudo /home/xmanager/glassfish4/glassfish/bin/asadmin create-jdbc-connection-pool --datasourceclassname org.postgresql.ds.PGConnectionPoolDataSource --restype javax.sql.ConnectionPoolDataSource --property portNumber=7477:databaseName=icbs:serverName=127.0.0.1:user=postgres:password=postgres icbs &&
        printf "Installing postgresql connector... \n" &&
        sudo wget -P /home/xmanager/glassfish4/glassfish/domains/domain1/lib https://github.com/mbphils/ICBS-Installer/releases/download/Required-Files/postgresql-9.3-1103.jdbc4.jar &&
        sudo unzip /home/xmanager/glassfish4/glassfish/domains/domain1/lib/postgresql-9.3-1103.jdbc4.jar &&
        printf "Changing Perm size... \n" &&
        sudo sed -i 's/-XX:MaxPermSize=192m/-XX:MaxPermSize=8196m/; s/-Xmx512m/-Xmx8196m/' /home/xmanager/glassfish4/glassfish/domains/domain1/config/domain.xml &&
        printf "Https listener to 443... \n" &&
        #sudo sed -i 's/<network-listener port="8181"/<network-listener port="443"/g' ~/glassfish4/glassfish/domains/domain1/config/domain.xml
        printf "Backing up  domain.xml\n" &&
        #sudo rm ~/glassfish4/glassfish/domains/domain1/config/domain.xml.bak #useless yung current domain.xml.bak kaya binura
        #sudo cp ~/glassfish4/glassfish/domains/domain1/config/domain.xml ~/glassfish4/glassfish/domains/domain1/config/domain.xml.bak
        printf "Finalizing... \n" &&
        sudo /home/xmanager/glassfish4/glassfish/bin/asadmin restart-domain; then
        echo "Glassfish setup SUCCESS";
        return 0
    else
        echo "Glassfish setup FAILED"
        return 1
    fi
}

install_jasper() {
    if sudo wget -P /opt https://github.com/mbphils/ICBS-Installer/releases/download/Required-Files/jasperreports-server-cp-6.3.0-linux-x64-installer.run &&
        sudo chmod +x /opt/jasperreports-server-cp-6.3.0-linux-x64-installer.run &&
        cd /opt &&
        sudo ./jasperreports-server-cp-6.3.0-linux-x64-installer.run &&
        cd /opt/jasperreports-server-cp-6.3.0 &&
        sudo sh ctlscript.sh start; then
        printf "Jasper 6 Successfully Installed\n"
        return 0
    else
        printf "Installation failed for Jasper 6\n"
        return 1
    fi
}

create_autostart_glassfish() {
    if [ -f "/etc/init.d/glassfish" ]; then
        printf "\nAutostart Glassfish detected! Deleting....\n"
        sudo rm /etc/init.d/glassfish
        printf "Success!\n\n"
    fi

    if printf "Creating Autostart Glassfish...\n" &&
        sudo sh -c 'cat > /etc/init.d/glassfish << EOF
#!/bin/sh
export AS_JAVA=/usr/local/java/jdk1.7.0_80
GLASSFISHPATH="/home/xmanager/glassfish4/glassfish"
case "\$1" in
    start)
        echo "Starting GlassFish from \$GLASSFISHPATH"
        sudo  $GLASSFISHPATH/bin/asadmin start-domain
        ;;
    restart)
        $0 stop
        $0 start
        ;;
    stop)
        echo "Stopping GlassFish from \$GLASSFISHPATH"
        sudo  $GLASSFISHPATH/bin/asadmin stop-domain
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart}"
        exit 1
        ;;
esac

exit 0
EOF'; then
        sudo chmod +x /etc/init.d/glassfish &&
        sudo update-rc.d glassfish defaults &&
        sudo service glassfish restart &&
        printf "\n\n"
        sudo service glassfish status &&
        printf "Autostart Glassfish created successfully.\n\n" &&
        return 0
    else
        printf "Creating Autostart Glassfish Failed \n"
        return 1
    fi
}

create_autostart_jasper() {
    if printf "Creating Autostart Jasper...\n" &&
        sudo sh -c 'cat > /etc/init.d/jasper << "EOF"
#!/bin/sh
    JASPER_HOME="/opt/jasperreports-server-cp-6.3.0"
    case "$1" in
        start)
            if [ -f "$JASPER_HOME/ctlscript.sh" ]; then
                echo "Starting JasperServer"
                "$JASPER_HOME/ctlscript.sh" start
            fi
            ;;
        stop)
            if [ -f "$JASPER_HOME/ctlscript.sh" ]; then
                echo "Stopping JasperServer"
                "$JASPER_HOME/ctlscript.sh" stop
            fi
            ;;
        restart)
            if [ -f "$JASPER_HOME/ctlscript.sh" ]; then
                echo "Restarting JasperServer"
                "$JASPER_HOME/ctlscript.sh" restart
            fi
            ;;
        status)
            if [ -f "$JASPER_HOME/ctlscript.sh" ]; then
                echo "Checking JasperServer status"
                "$JASPER_HOME/ctlscript.sh" status
            fi
            ;;
        *)
            echo $"Usage: $0 {start|stop|restart|status}"
            exit 1
            ;;
    esac
EOF'; then
        sudo chmod +x /etc/init.d/jasper &&
        sudo update-rc.d jasper defaults &&
        sudo service jasper restart &&
        printf "Autostart Jasper created successfully.\n" &&
        return 0
    else
        printf "Creating Autostart Jasper script Failed \n" &&
        return 1
    fi
}

exit_script() {
    printf "\n Bye bye.. \n"
    exit
}

# Main function
main() {
    while true; do
        display_menu
        read -p "Choose number: " choice
        case $choice in
            1) install_prerequisites ;;
            2) install_postgresql ;;
            3) install_java ;;
            4) install_glassfish ;;
            5) install_jasper ;;
            6) create_autostart_glassfish ;;
            7) create_autostart_jasper ;;
            8) exit_script ;;
            *) printf "Invalid choice. Please choose a number between 1 and 8.\n" ;;
        esac
    done
}

# Call the main function
main
