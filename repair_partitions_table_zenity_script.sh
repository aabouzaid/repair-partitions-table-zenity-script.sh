#! /bin/bash

##############################################################
#
# Simple script with Zenity GUI to backup, restore or repair partitions table.
# Tested on Ubuntu 14.04 (and probably will work with Debian).
# By Ahmed M. AbouZaid (www.aabouzaid.com), July 2014, under MIT license.
#
##############################################################

#Check if gksu, sfdisk and gdisk (fixparts) are installed, and add missing package in array.
if [[ ! -f /usr/bin/gksu ]]; then
  required_packages=(gksu)
elif [[ ! -f /sbin/sfdisk ]]; then
  required_packages+=(util-linux)
elif [[ ! -f /sbin/fixparts ]]; then
  required_packages+=(gdisk)
fi

#Check if there is any missing package and start Ubuntu Software Center to install it.
if [[ ${#required_packages[@]} != 0 ]]; then
  zenity --error --text="Please install required packages! Ubuntu Software Center will start with missing packages now."
  /usr/bin/software-center ${required_packages[@]}
fi

#Select hard disk if there are many.
harddisk=$(zenity --list --radiolist\
 --title="Choose hard disk" \
 --column=" " --column="Hard disk" --column="Size" \
    $(lsblk | grep disk | awk '{print "FALSE /dev/"$1,$4}')
)

#Check if user click "Cancel" before select the harddisk.
  if [[ $? = 1 ]]; then
    exit
  fi

#Backup, restore or repair partitions table dialog.
partitions_table_dialog () {
  partitions_table_action=$(zenity --list --radiolist \
    --title="What do you want to do?" \
    --column=" " --column="Action" \
      FALSE "Backup partitions table." \
      FALSE "Restore partitions table." \
      FALSE "Repair partitions table."
  )
}

#Check exit status and return message in the case of success or fails.
check_exit_status () {
  if [[ $? = 0 ]]; then
    zenity --info --text="Done"
   else
    echo $(printf '=%.0s' {1..50}) >> /tmp/repair_partitions_table_zenity_script.log
    zenity --error --text="Sorry! Unexpected error! Please check logs: /tmp/repair_partitions_table_zenity_script.log"
  fi
}

while :
do
#Run partitions table dialog.
partitions_table_dialog

#Checking user's choice.
case "$partitions_table_action" in
#-------------------------------------------------------------
  "Backup partitions table.")
    #Dump the partitions of a device.
    /usr/bin/gksu /sbin/sfdisk -d $harddisk > ~/partitions_table_backup_$(date +%Y%m%d).dump 2>> /tmp/repair_partitions_table_zenity_script.log

    #Check exit status of previous command and return to main dialog.
    if [[ $? = 0 ]]; then
      zenity --info --text="You can find partitions table backup file in your Home with name \"partitions_table_backup_$(date +%Y%m%d).dump\".\n\nPlease copy it in a safe place."
    else
      echo $(printf '=%.0s' {1..50}) >> /tmp/repair_partitions_table_zenity_script.log
      zenity --error --text="Sorry! Unexpected error! Please check logs: /tmp/repair_partitions_table_zenity_script.log"
    fi
  ;;
#-------------------------------------------------------------
  "Restore partitions table.")
    #Restore the partitions table.
    /usr/bin/gksu /sbin/sfdisk -f $harddisk < $(zenity --file-selection --title="Select a File") >> /tmp/repair_partitions_table_zenity_script.log 2>&1

    #Check exit status of previous command and return to main dialog.
    check_exit_status
  ;;
#-------------------------------------------------------------
  "Repair partitions table.")
    #Run Fixparts in non-interactive mode to repair partitions table.
    /usr/bin/gksu /sbin/fixparts $harddisk 2> /tmp/repair_partitions_table_zenity_script.log << EOD
Y
w
yes
EOD

    #Check exit status of previous command and return to main dialog.
    check_exit_status
  ;;
#-------------------------------------------------------------
  *)
    if [[ $? = -1 ]]; then
      zenity --error --text="Sorry! Unexpected error!"
      break
    else
      break
    fi
  ;;
esac
done
