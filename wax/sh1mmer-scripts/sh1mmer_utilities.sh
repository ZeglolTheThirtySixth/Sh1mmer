source /usr/sbin/sh1mmer_gui.sh
source /usr/sbin/sh1mmer_optionsSelector.sh

deprovision() {
    vpd -i RW_VPD -s check_enrollment=0
    unblock_devmode
}

reprovision() {
    vpd -i RW_VPD -s check_enrollment=1
}

usb() {
    crossystem dev_boot_usb=1
}

fix_gbb() {
    /usr/share/vboot/bin/set_gbb_flags.sh 0x0
}

disable_verity() {
    movecursor_generic 2
    echo "READ THIS!!!!!! DON'T BE STUPID"
    movecursor_generic 3
    echo "This script will disable rootfs verification. What does this mean? You'll be able to edit any file on the chromebook, useful for development, messing around, etc"
    /usr/share/vboot/bin/make_dev_ssd.sh -i /dev/mmcblk0 --remove_rootfs_verification
}

unblock_devmode() {
    vpd -i RW_VPD -s block_devmode=0
    crossystem block_devmode=0
    res=$(cryptohome --action=get_firmware_management_parameters 2>&1)
    if [ $? -eq 0 ] && [[ ! $(echo $res | grep "Unknown action") ]]; then
        tpm_manager_client take_ownership
        # sleeps no longer needed
        cryptohome --action=remove_firmware_management_parameters
    fi
}

shell() {
    cleanup
    echo "You can su chronos if you need to use chromebrew"
    su -c 'PATH="$PATH:/usr/local/bin" LD_LIBRARY_PATH="/lib64:/usr/lib64:/usr/local/lib64" /bin/bash' # ok i didn't think of this very cool :+1: -ce
    setup
    clear
    sleep 0.1
}

runtask() {
    # are you happy now?!
    # no, i am not YOU USED IT WRONG!!! -r58Playz
    showbg terminalGeneric.png

    curidx=0
    movecursor_generic $curidx # you need to put in a number!
    echo "Starting task $1"
    sleep 2
    curidx=1
    if $1; then
        movecursor_generic $curidx # ya forgot it here
        echo "Task $1 succeeded."
        sleep 3
    else
        # movecursor_generic $curidx # ya forgot it here
        # NO I DIDN'T! i wasn't skidding, the issue i told you would happen did happen! -ce
        read "THERE WAS AN ERROR! The utility likely did not work. Press return to continue."
    fi
}

selector() {
    #clear # FOR TESTING! REMOVE THIS ONCE ASSETS ARE FIXED -ce

    selected=0
    while true; do
        showbg "utils/utils-select0${selected}.png" # or something
        input=$(readinput)
        case $input in
        'kB') exit ;;
        'kE') return ;;
        'kU')
            ((selected--))
            if [ $selected -lt 0 ]; then selected=0; fi
            ;;
        'kD')
            ((selected++))
            if [ $selected -ge $# ]; then selected=$(($# - 1)); fi
            ;;
        esac
    done
}

while true; do
    showbg Utilities.png
    selector 0 1 2 3 4 5 6
    case $selected in
    '0') runtask fix_gbb ;;
    '1') runtask deprovision ;;
    '2') runtask reprovision ;;
    '3') runtask usb ;;
    '4') runtask disable_verity ;;
    '5') shell ;;
    '6') runtask unblock_devmode ;;
    esac
done
