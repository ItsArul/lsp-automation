#!/bin/bash

GREEN_COLOR='\033[0;32m'

echo -e "${GREEN_COLOR}Welcome To Installasi Manager LSP\n"

read -p "Masukan IP Linux (ex. 192.168.20.1): " ip_linux
read -p "Masukan IP Camera (ex. 192.168.20.1): " ip_camera
read -p "Masukan IP Briker (ex. 192.168.20.1): " ip_briker
read -p "Masukan NIS Kalian (ex. 13453): " nis


repo_deb_11="deb http://repo.antix.or.id/debian bullseye main contrib non-free
deb-src http://repo.antix.or.id/debian bullseye main contrib non-free

deb http://repo.antix.or.id/debian-security/ bullseye-security main contrib non-free
deb-src http://repo.antix.or.id/debian-security/ bullseye-security main contrib non-free

deb http://repo.antix.or.id/debian bullseye-updates main contrib non-free
deb-src http://repo.antix.or.id/debian bullseye-updates main contrib non-free
"

rep_deb_10="deb http://kartolo.sby.datautama.net.id/debian/ buster main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian/ buster-updates main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian-security/ buster/updates main contrib non-free"

read -p "Do you want to insert repository ? (y/n): " yn
if [[ $(cat /etc/debian_version) > "10.10" ]]
then
    case $yn in
        "y") echo "${repo_deb_11}" >> /etc/apt/sources.list
        ;;
        "n") echo "Okayy, next stepp"
        ;;
    esac
else
    case $yn in
        "y") echo "${repo_deb_10}" >> /etc/apt/sources.list
        ;;
        "n") echo "Okayy, next stepp"
        ;;
    esac
fi
