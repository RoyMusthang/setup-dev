#!/usr/bin/env bash
# ----------------------------- VARIABLES ----------------------------- #
TEMP_PROGRAMS_DIRECTORY="$HOME/temp_programs" # temporary folder to save .deb files
UBUNTU_VERSION=$(lsb_release -c | grep -oE "[^:]*$") # get version codename: focal, eoan...

# .deb list
URL_DEB_FILES=(
  https://zoom.us/client/latest/zoom_amd64.deb
  https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  https://updates.insomnia.rest/downloads/ubuntu/latest
)

# apt list
PROGRAMS_VIA_APT=(
  apt-transport-https
  build-essential
  slack-desktop
  nodejs 
  nodejs-doc 
  zsh
  net-tools
  unrar
  unzip
  gparted
  gnome-tweak-tool
  git
  youtube-dl
  docker-ce 
  docker-ce-cli 
)

# snap list
PROGRAMS_VIA_SNAP=(
  "code --classic"
  "spotify"
  "postman"
  "slack --classic"
)
# ---------------------------------------------------------------------- #


# ----------------------------- PRE INSTALL STEP ----------------------------- #
echo "==== Removendo travas eventuais do apt ===="
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/cache/apt/archives/lock

echo "==== Adicionando/Confirmando arquitetura de 32 bits ====" 
sudo dpkg --add-architecture i386

echo "==== Atualizando o repositório ===="
sudo apt update -y

echo "==== Adicionando repositórios PPA ===="
sudo apt install software-properties-common -y
for ppa_address in ${PPA_ADDRESSES[@]}; do
    sudo add-apt-repository "$ppa_address" -y
done


echo "==== Configura repositório docker e docker-compose ===="
sudo apt-get remove docker docker-engine docker.io containerd runc -y
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $UBUNTU_VERSION stable" | sudo tee /etc/apt/sources.list.d/docker-release.list
wget --quiet -O - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key --keyring /etc/apt/trusted.gpg.d/docker-release.gpg add -
sudo wget -c "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -P /usr/local/bin/
sudo mv /usr/local/bin/docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
# ------------------------------------------------------------------------ #

# ----------------------------- INSTALL STEP ----------------------------- #
echo "==== Atualizando o APT depois da adição de novos repositórios ===="
sudo apt update -y

echo "==== Instalando programas no APT ===="
for apt_program in ${PROGRAMS_VIA_APT[@]}; do
  echo "[INSTALANDO VIA APT] - $apt_program"
  sudo apt install "$apt_program" -y
done

echo "==== Download de programas .deb ===="
mkdir "$TEMP_PROGRAMS_DIRECTORY"
for url in ${URL_DEB_FILES[@]}; do
  wget -c "$url" -P "$TEMP_PROGRAMS_DIRECTORY"
done

echo "==== Instalando pacotes .deb baixados ===="
sudo dpkg -i $TEMP_PROGRAMS_DIRECTORY/*.deb
sudo apt --fix-broken install -y
# caso haja erro na primeira vez por conta de pacotes dependentes, ele roda novamente o comando
sudo dpkg -i $TEMP_PROGRAMS_DIRECTORY/*.deb

echo "==== Instalando pacotes Snap ===="
sudo apt install snapd -y
for snap_program in "${PROGRAMS_VIA_SNAP[@]}"; do
  echo "[INSTALANDO VIA SNAP] - $snap_program"
  sudo snap install $snap_program
done

echo "==== Configura docker para funcionar sem sudo ===="
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
sudo systemctl enable docker

echo "==== Criando atalho para um arquivo em branco ===="
mkdir $HOME/Templates
touch $HOME/Templates/"blank file"
# ---------------------------------------------------------------------- #

# ----------------------------- CLEANING ------------------------------- #
echo "==== Finalização, atualização e limpeza ===="
sudo apt update && sudo apt dist-upgrade -y
sudo apt autoclean
sudo apt autoremove -y
sudo rm -rf $TEMP_PROGRAMS_DIRECTORY
# ---------------------------------------------------------------------- #

# ----------------------------- FINISH --------------------------------- #
echo "==== PARA O DOCKER FUNCIONAR SEM O SUDO BASTA REINICIAR ===="

read -p "REINICIAR AGORA? [s/n]: " opcao
if [ "$opcao" == "s" ] || [ "$opcao" == "S" ]; then
  sudo reboot
fi

exit 0 ---------------------------------------------------------------------- #
