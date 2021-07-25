#!/usr/bin/env bash

configurate_git() {
	echo "Configurate git"
	git config --global --add user.name frechousky
	git config --global --add user.email alexandre.freche@gmail.com
	echo "Git has been successfully configured"
}

create_user() {
	read -p "Would you like to create a unix user [y|N] ? " createUserYN
	if [[ "$createUserYN" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo "Creating unix user"
		read -p "Enter username: " username
		if sudo useradd -m "$username"; then
			echo "User $username created" 
		else
			echo "Error creating user $username"
			exit 1
		fi
		if sudo passwd "$username"; then
			echo "User $username password has been updated"
		else
			echo "Error updating user $username password"
			exit 1
		fi
		if sudo usermod -aG wheel "$username"; then
			echo "User $username added to sudoers"
		else
			echo "Error adding user $username to sudoers"
			exit 1
		fi
	fi
}

display_help() {
	echo "Download, install and configure softwares for software engineering."
	echo "It is advised not to run this script with sudo."
	echo "Usage: ./set_dev_env.sh [all|compose|docker|git|intellij|user]"
	echo -e "\tall\t\tfull installation"
	echo -e "\tcompose\t\tdownload and install docker-compose"
	echo -e "\tdocker\t\tdownload, install and configure docker (add user to docker group)"
	echo -e "\tgit\t\tconfigure git"
	echo -e "\tintellij\tdownload and install intellij idea community"
	echo -e "\maven\tdownload and install maven"
	echo -e "\tuser\t\tcreate unix user"
}

install_docker() {
	echo "Installing docker"
	if sudo dnf -y install dnf-plugins-core; then
		echo "Dnf-plugins-core installed"
	else
		echo "Error installing dnf-plugins-core"
		exit 1
	fi
	if sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo; then
		echo "Docker repo added to dnf repos"
	else
		echo "Error adding docker repo to dnf repos"
		exit 1
	fi
	if sudo dnf -y install docker-ce docker-ce-cli containerd.io; then
		echo "Docker has been successfully installed"
	else
		echo "Error installing docker"
		exit 1
	fi
	sudo groupadd docker && echo "Group docker created"
	if sudo usermod -aG docker "$username"; then
		echo "User $username added to group docker"
	else
		echo "Error adding user $username to group docker"
		exit 1
	fi
	sudo systemctl enable docker.service
 	sudo systemctl enable containerd.service
}

install_docker_compose() {
	echo "Installing docker-compose"
	# https://github.com/docker/compose/releases/latest redirects to latest tag
	dockerComposeLatestTag=$(curl -Ls -I -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest)
	dockerComposeLatestTagDownloadUrl=${dockerComposeLatestTag/tag/download}
	sudo curl -L "$dockerComposeLatestTagDownloadUrl/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod 755 /usr/local/bin/docker-compose
	if /usr/local/bin/docker-compose --version; then
		echo "Docker-compose has been successfully installed"
	else
		echo "Error installing docker-compose"
		exit 1
	fi
}

install_intellij() {
	# https://www.jetbrains.com/help/idea/installation-guide.html#snap
	echo "Installing intellij idea community"
	echo "snapd is required to install intellij idea community"
	# snapd install
	# https://snapcraft.io/docs/installing-snap-on-fedora
	if sudo dnf -y install snapd; then
		echo "snapd has been successfully installed"
	else
		echo "Error installing snapd"
		exit 1
	fi
	if sudo ln -s /var/lib/snapd/snap /snap; then
		echo "Created symlink from /var/lib/snapd/snap to /snap"
	else
		echo "Error creating symlink from /var/lib/snapd/snap to /snapln "
	fi
	# end snap install
	if sudo snap install intellij-idea-community --classic; then
		echo "intellij idea community has been successfully installed"
	else
		echo "Error installing intellij idea community"
		exit 1
	fi
}

install_maven() {
  echo "Installing maven"
  if sudo dnf -y install maven; then
		echo "maven has been successfully installed"
	else
		echo "Error installing maven"
		exit 1
	fi
}

username=$USER
case $1 in
	user) 
		create_user;;

	compose)
		install_docker_compose;;

	docker)
		install_docker;;

	git)
		configurate_git;;
	
	intellij)
		install_intellij;;

  	maven)
		install_maven;;

	all)
		create_user
		install_docker
		install_docker_compose
		install_intellij
		install_maven
		configurate_git;;
	*)
		display_help;;
esac