#!/bin/bash

sudo apt -y update
sudo apt-get install -y libc6-dev g++-multilib python p7zip-full pwgen jq curl
cd ~

if [ -f canyacoin.zip ]
then
    rm canyacoin.zip
fi
wget -O canyacoin.zip `curl -s 'https://api.github.com/repos/canyacoin-pod/canyacoin/releases/latest' | jq -r '.assets[].browser_download_url' | egrep "canyacoin.+x64.zip"`
7z x -y canyacoin.zip
chmod -R a+x ~/canyacoin-pkg
rm canyacoin.zip

cd ~/canyacoin-pkg
./fetch-params.sh

if ! [[ -d ~/.canyacoin ]]
then
    mkdir -p ~/.canyacoin
fi

if ! [[ -f ~/.canyacoin/canyacoin.conf ]] 
then
    echo "rpcuser=rpc`pwgen 15 1`" > ~/.canyacoin/canyacoin.conf
    echo "rpcpassword=rpc`pwgen 15 1`" >> ~/.canyacoin/canyacoin.conf
fi

./canyad