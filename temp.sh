#!/bin/bash
sudo apt update -y && sudo apt upgrade -y
sudo apt-get install snap -y snapd
sudo apt install gedit -y 
sudo apt install vim -y
sudo apt install npm
sudo apt install xclip

#vs code
sudo snap install --classic code
#installing python
sudo apt install -y python3 python3-pip
#chrome browser
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt-get install -f -y

#anaconda

#wget https://repo.anaconda.com/archive/Anaconda3-2024.06-1-Linux-x86_64.sh
#bash ~/Downloads/Anaconda3-2024.06-1-Linux-x86_64.sh

#setup of mingW for my C++
sudo apt-get install -y build-essential gdb gcc

#nvida stting
#set to propierty and tested
#sudo apt install -y nvidia-cuda-toolkit
#conda create -n tf python=3.9 ipykernel -y
#conda activate tf
#pip install jupyter
#pip install tensorflow[and-cuda]

#obs studio 
sudo add-apt-repository ppa:obsproject/obs-studio
sudo apt install obs-studio

#vlc
sudo apt install vlc

#for my night lighht
sudo apt install redshift
#usgwe redshift -x to turn ogg
#redshift -O 3500 to tuern on

#microsoft edge
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list > /dev/null
sudo apt update
sudo apt install microsoft-edge-stable

curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm --version
nvm install 20
sudo npm uninstall -g @google/gemini-cli
npm install -g @google/gemini-cli
gemini

