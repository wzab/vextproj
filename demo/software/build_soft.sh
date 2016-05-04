#!/bin/bash
#Please note, that even though the Buildroot version
#is put into the environment variable, it may be also
#set in different configuration files or paths in 
#the zip archive. So if you want to change the Buildroot
#version, it may be difficult...
BRNAME=buildroot-2016.02
wget https://buildroot.org/downloads/$BRNAME.tar.bz2
#Unpack Buildroot
tar -xjf $BRNAME.tar.bz2
#Add our stuff
tar -xjf example.tar.bz2
#Modify the packages menu
#It is not the most elegant way, but the simplest 
#we just add new menu
cat >> $BRNAME/package/Config.in <<AddedMenu
menu "Additional example packages"
	source "package/axil2ipb-module/Config.in"
endmenu
AddedMenu
cd $BRNAME
make

