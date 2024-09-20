#!/bin/bash
# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should not be run directly. Please use the parent script."
    whiptail --title "Error" --msgbox "This script should not be run directly. Please use the parent script." 8 78
    exit 1
fi

function sub_menu_advanced_settings(){
    while true; do
        LINES=$(tput lines)
        COLUMNS=$(tput cols)
        OPTION=$(whiptail --title "Advanced settings" --backtitle "$MAIN_TITLE" --menu ""  --ok-button "select" --cancel-button "Back" $(( $LINES - 6 ))  $(( $COLUMNS - 40 )) $(( $LINES - 14 )) \
        "1" "Version name                 [$VERSION_NAME]" \
        "2" "Set debug mode               [$DEBUG]" \
        "3" "Set symlink mode             [$SYMLINK]" \
        "4" "DICOM filter profile         [$SCP_CONFIG_PROFILE]" \
        3>&1 1>&2 2>&3)
        
        exitstatus=$?
        if [ $exitstatus == 1 ]; then
            return
        fi

        case $OPTION in
            1) ask_version;;
            2) ask_debug;;
            3) ask_symlink;;
            4) ask_dicom_filter_profile;;
            *) whiptail --textbox "Invalid option. Please try again.";;
        esac
    done
}

function main_menu(){
    while true; do
        LINES=$(tput lines)
        COLUMNS=$(tput cols)
        OPTION=$(whiptail --title "PACSOR settings menu" --backtitle "$MAIN_TITLE" --menu ""  --ok-button "select" --cancel-button "Exit without saving" $(( $LINES - 6 ))  $(( $COLUMNS - 40 )) $(( $LINES - 12 )) \
        "1" "Client name                   [$CLIENT_NAME]" \
        "2" "Client token                  [$CLIENT_TOKEN]" \
        "3" "Environement URL              [$INTEGRATOR_URL]" \
        "" "" \
        "4" "Set PACS AE Title             [$PACS_AET]" \
        "5" "Set PACS IP                   [$PACS_IP]" \
        "6" "Set PACS Port                 [$PACS_PORT]" \
        "7" "Set RIS IP                    [$RIS_IP]" \
        "8" "Set RIS Port                  [$RIS_PORT]" \
        "" "" \
        "9" "Set Milvue SCP Port           [$SCP_PORT]" \
        "10" "Set Milvue SCP AET            [$MILVUE_AET]" \
        "" "" \
        "11" "Advanced settings" \
        "" "" \
        "o" "Load configuration" \
        "d" "Display current configuration" \
        "w" "Save configuration and exit" \
        3>&1 1>&2 2>&3)
       

        exitstatus=$?
        if [ $exitstatus == 1 ]; then
            #clear
            echo "Deployment cancelled. Exiting..."
            exit
        fi

        case $OPTION in
            1) ask_client_name;;
            2) ask_client_token;;
            3) ask_env_url;;
            4) ask_pacs_aet;;
            5) ask_pacs_ip;;
            6) ask_pacs_port;;
            7) ask_ris_ip;;
            8) ask_ris_port;;
            9) ask_scp_port;;
            10) ask_milvue_aet;;
            11) sub_menu_advanced_settings;;
            o) load_config;;
            d) display_config;;
            w) save_and_exit;;
            *) whiptail --textbox "Invalid option. Please try again.";;
        esac
    done
}

function startwizard(){
    local step=1
    local max_steps=8
    
    while [ $step -le $max_steps ]; do
        case $step in
            
            1)
                if ! ask_env_url "wizard"; then
                    ((step--))
                else
                    ((step++))
                fi
                ;;
            2)
                if ! ask_client_name "wizard"; then
                    ((step--))
                else
                    ((step++))
                fi
                ;;
            3)
                if ! ask_client_token "wizard"; then
                    ((step--))
                else
                    ((step++))
                fi
                ;;
            4)
                if ! ask_pacs_aet "wizard"; then
                    ((step--))
                else
                    ((step++))
                fi
                ;;

            5)
                if ! ask_pacs_ip "wizard"; then
                    ((step--))
                else
                    ((step++))
                fi
                ;;

            6)
                if ! ask_pacs_port "wizard"; then
                    ((step--))
                else
                    ((step++))
                fi
                ;;
            7)
                if ! ask_ris_ip "wizard"; then
                    ((step--))
                else
                    ((step++))
                fi
                ;;
            8)
                if ! ask_ris_port "wizard"; then
                    ((step--))
                else
                    ((step++))
                fi
                ;;
            *)
                break
                ;;
        esac

        if [ $step -eq 0 ]; then
            
            whiptail --title "Info" --msgbox "Wizard cancelled." 8 78
            return 1
        fi
    done
    return 0
}