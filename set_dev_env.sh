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
	echo "Usage: ./set_dev_env.sh [all|docker|git|user|vscode]"
	echo -e "\tall\tfull installation"
	echo -e "\tdocker\tdownload, install and configure docker (add user to docker group)"
	echo -e "\tgit\tconfigure git"
	echo -e "\tuser\tcreate unix user"
	echo -e "\tvscode\tdownload and install vscode"
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
}

install_vscode() {
	echo "Installing vscode"
	echo -e \
		"[vscode]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" \
		| sudo tee /etc/yum.repos.d/vscode.repo || (echo "error creating vscode repo file"; exit 1;)
	sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || (echo "rpm import failed"; exit 1;) 
	if sudo dnf -y install code; then
		echo "Vscode has been successfully installed"
	else
		echo "Error installing vscode"
		exit 1
	fi
}

username=$USER
case $1 in
	user) 
		create_user;;

	docker)
		install_docker;;

	vscode)
		install_vscode;;

	git)
		configurate_git;;

	all)
		create_user
		install_docker
		install_vscode
		configurate_git;;
	*)
		display_help;;
esac