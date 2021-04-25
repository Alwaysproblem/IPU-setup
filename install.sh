#!/bin/bash

if [[ ! -d "$HOME/.ipuenv" ]]; then
    mkdir -p "$HOME/.ipuenv"
fi

wget https://raw.githubusercontent.com/Alwaysproblem/IPU-setup/main/executable/IPUconda -O $HOME/.ipuenv/IPUconda
wget https://raw.githubusercontent.com/Alwaysproblem/IPU-setup/main/executable/popvision_enable -O $HOME/.ipuenv/popvision_enable
wget https://raw.githubusercontent.com/Alwaysproblem/IPU-setup/main/executable/popvision_enable_oom -O $HOME/.ipuenv/popvision_enable_oom
wget https://raw.githubusercontent.com/Alwaysproblem/IPU-setup/main/executable/setupVscode -O $HOME/.ipuenv/setupVscode