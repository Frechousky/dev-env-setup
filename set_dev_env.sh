#!/usr/bin/env bash

check_snapd_install() {
	if which snap > /dev/null 2>&1; then
		echo "snapd already installed"
	else
		install_snapd
	fi
}

configurate_git() {
	echo "Configurate git"
	git config --global --add user.name frechousky
	git config --global --add user.email alexandre.freche@gmail.com
	echo "git has been successfully configured"
}

create_unix_user() {
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
	echo "Install and configure softwares for software engineering."
	echo "It is advised not to run this script with sudo."
	echo "Usage: $0 [all|compose|docker|git|postman|snapd|vscode|user]"
	echo -e "\tall\t\tfull installation"
	echo -e "\tcompose\t\tinstall docker-compose"
	echo -e "\tdocker\t\tinstall and configure docker (add user to docker group)"
	echo -e "\tgit\t\tconfigure git"
	echo -e "\tpostman\t\tinstall postman"
	echo -e "\tsnapd\t\tinstall snapd"
	echo -e "\tvscode\t\tinstall vscode"
	echo -e "\tuser\t\tcreate unix user"
}

install_docker() {
	echo "Installing docker"
	echo "dnf-plugins-core is required to install docker"
	if sudo dnf -y install dnf-plugins-core; then
		echo "dnf-plugins-core has been successfully installed"
	else
		echo "Error installing dnf-plugins-core"
		exit 1
	fi
	if sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo; then
		echo "docker repo added to dnf repos"
	else
		echo "Error adding docker repo to dnf repos"
		exit 1
	fi
	if sudo dnf -y install docker-ce docker-ce-cli containerd.io; then
		echo "docker has been successfully installed"
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
		echo "docker-compose has been successfully installed"
	else
		echo "Error installing docker-compose"
		exit 1
	fi
}

install_postman() {
	# https://code.visualstudio.com/docs/setup/linux#_snap
	check_snapd_install
	if sudo snap install postman; then
		echo "postman has been successfully installed"
	else
		echo "Error installing postman"
		exit 1
	fi
}

install_snapd() {
	# https://snapcraft.io/docs/installing-snap-on-fedora
	echo "Installing snapd"
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
}

install_vscode() {
	# https://code.visualstudio.com/docs/setup/linux#_snap
	check_snapd_install
	if sudo snap install --classic code; then
		echo "vscode has been successfully installed"
	else
		echo "Error installing vscode"
		exit 1
	fi
}

username=$USER
case $1 in
	all)
		create_unix_user
		install_snapd
		install_docker
		install_docker_compose
		install_postman
		install_vscode
		configurate_git;;

	compose)
		install_docker_compose;;

	docker)
		install_docker;;

	git)
		configurate_git;;

	postman)
		install_postman;;

	snapd)
		install_snapd;;

	user) 
		create_unix_user;;

	vscode)
		install_vscode;;

	*)
		display_help;;
esac