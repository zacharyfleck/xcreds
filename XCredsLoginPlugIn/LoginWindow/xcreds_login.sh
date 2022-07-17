#!/bin/bash

f_install=0
f_remove=0

while getopts ":ir" o; do
	case "${o}" in
		i)
			f_install=1
		;;
		r)
			f_remove=1
		;;
	esac
done



if [ $(id -u) -ne 0 ]; then
	echo please run with sudo
	exit -1
fi

script_path="$0"
script_folder=$(dirname "${script_path}")
authrights_path="${script_folder}"/authrights
plugin_path="${script_folder}"/XCredsLoginPlugin.bundle
auth_backup_folder=/Library/"Application Support"/xcreds
rights_backup_path="${auth_backup_folder}"/rights.bak

if [ $f_install -eq 1 ] && [ $f_remove -eq 1 ]; then
	echo "you can't specify both -i and -r"
	exit -1
fi

if [ $f_install -eq 1 ]; then
	
	if [ ! -e  "${auth_backup_folder}" ]; then
		mkdir -p "${auth_backup_folder}"
	fi
	
	if [ ! -e "${rights_backup_path}" ]; then 
		security authorizationdb read system.login.console > "${rights_backup_path}"
		
	fi
	
	if [ -e  "${plugin_path}" ]; then
		
		cp -R "${plugin_path}" "${target_volume}"/Library/Security/SecurityAgentPlugins/
		chown -R root:wheel "${target_volume}"/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle
	fi
	
	if [ -e ${authrights_path} ]; then
		"${authrights_path}" -r "loginwindow:login" "XCredsLoginPlugin:LoginWindow" 
		"${authrights_path}" -a  "XCredsLoginPlugin:LoginWindow" "XCredsLoginPlugin:PowerControl,privileged" 
		"${authrights_path}" -a  "loginwindow:done" "XCredsLoginPlugin:KeychainAdd,privileged"
		
	else
		echo "could not find authrights tool"
		exit -1
	fi

	
elif [ $f_remove -eq 1 ]; then

	if [ -e "${rights_backup_path}" ]; then 
		security authorizationdb write system.login.console < "${rights_backup_path}"
	fi
	
	if [ -e  "/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle" ]; then
		rm -rf "/Library/Security/SecurityAgentPlugins/XCredsLoginPlugin.bundle"
		
	fi
	
	
else 
	echo "you must specify -i or -r to install or remove xcreds login"
	exit -1
	
fi