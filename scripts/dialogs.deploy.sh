#!/bin/bash
# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should not be run directly. Please use the parent script."
    whiptail --title "Error" --msgbox "This script should not be run directly. Please use the parent script." 8 78
    exit 1
fi

function display_config(){
    local msg=""
    msg+="$CLIENT_NAME:\n"
    msg+="  Environment settings:\n"
    msg+="    Version: $VERSION_NAME\n"
    msg+="    URL: $INTEGRATOR_URL\n"
    msg+="    Client token: $CLIENT_TOKEN\n"
    msg+="    Use signed URL: $USE_SIGNED_URL\n"
    msg+="  PACS settings:\n"
    msg+="    pacs_aet: $PACS_AET\n"
    msg+="    pacs_ip: $PACS_IP\n"
    msg+="    pacs_port: $PACS_PORT\n"
    msg+="  Milvue SCP settings:\n"
    msg+="    scp_port: $SCP_PORT\n"
    msg+="    milvue_aet: $MILVUE_AET\n"
    msg+="  Milvue SCU settings:\n"
    msg+="    Callbacks: $SENDER_CALLBACKS_URL\n"
    msg+=" General settings:\n"
    msg+="    debug: $DEBUG\n"
    msg+="    symlink: $SYMLINK\n"
    
    whiptail --title "Pacsor settings" --backtitle "$MAIN_TITLE" --msgbox "$msg" 25 78
}

function ask_version(){
    
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Cancel"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi

    initial=$VERSION_NAME
    # we loop until the user enters a valid version number
    while true; do
        VERSION_NAME=$(whiptail --backtitle "$MAIN_TITLE" --title "Version number" --inputbox "Enter the version number using this format : v<major>.<minor>.<patch> or dev.{8-digits-hex}" --ok-button $ok_button --cancel-button $cancel_button 8 78 "$VERSION_NAME" 3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            VERSION_NAME=$initial
            return 1
        fi
        if ! validate_version_name; then
            continue
        else
            return 0
        fi
    done
}

#we do the same with ask_env_url,  a predifined single radio list (using whiptail radiolist) of integrator urls, prodict.milvue.com, staging.milvue.com, dev.milvue.com, other. if other is selected, we ask for the url ask_integrator_url
function ask_env_url() {
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Cancel"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi
    # Map friendly names to URLs
    declare -A urls=(
        ["Azure-prod"]="https://k8s.predict.milvue.com"
        ["Azure-preprod"]="https://azure-preprod.predict.milvue.com"
        ["Azure-beta"]="https://azure-beta.predict.milvue.com"
        ["GCP-precert"]="https://precert.predict.milvue.com"
        ["GCP-staging"]="https://staging.predict.milvue.com"
        ["localor"]="http://integrator:8080"
        ["other"]="other"
    )
    
    local options=("Azure-prod" "Azure-preprod" "Azure-beta" "GCP-precert" "GCP-staging" "localor" "other")
    local prompt="Select environement:"
    local default_status
    local choice

    while true; do
        # Setup the options for the radiolist
        local radiolist_options=()
        for option in "${options[@]}"; do
            default_status="OFF"
            if [[ "${urls[$option]}" == "$INTEGRATOR_URL" ]]; then
                default_status="ON"  # Set the default based on the current INTEGRATOR_URL
            fi
            radiolist_options+=("$option" "" "$default_status")
        done

        # Display the radiolist
        choice=$(whiptail --backtitle "$MAIN_TITLE" --title "Integrator URL" --radiolist "$prompt" --ok-button $ok_button --cancel-button $cancel_button 15 50 8 "${radiolist_options[@]}" 3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return 1
        fi

        if [ "$choice" = "other" ]; then
            if ! ask_integrator_url "false"; then
                continue
            else
                return 0
            fi
        elif [ "$choice" = "localor" ]; then
            INTEGRATOR_URL="http://integrator:8080"
            USE_SIGNED_URL=false
            CLIENT_TOKEN="00000032-d366-45e2-844a-50576bab3f72"
            CLIENT_NAME="local.milvue.localor.$(hostname | tr '[:upper:]' '[:lower:]').0"
            ISLOCALOR=true
            return 0
        else
            INTEGRATOR_URL="${urls[$choice]}"
            return 0
        fi
    done
}

#we do the same as ask_version for integrator url
function ask_integrator_url(){
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Back"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi

    initial=$INTEGRATOR_URL
    while true; do
        INTEGRATOR_URL=$(whiptail --backtitle "$MAIN_TITLE" --title "Integrator URL" --inputbox "Enter the integrator URL (aka API URL)" --ok-button $ok_button --cancel-button $cancel_button 8 78 "$INTEGRATOR_URL" 3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            INTEGRATOR_URL=$initial
            return 1
        fi
        if ! validate_url; then
            continue
        else
            return 0
        fi
    done
}

function ask_client_name(){
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Back"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi

    initial=$CLIENT_NAME
    while true; do
        CLIENT_NAME=$(whiptail --backtitle "$MAIN_TITLE" --title "Client name" --inputbox "Enter the client name (eg country.partner.client.site.id)" --ok-button $ok_button --cancel-button $cancel_button 8 78 "$CLIENT_NAME" 3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            CLIENT_NAME=$initial
            return 1
        fi
        if ! validate_client_name; then
            continue
        else
            return 0
        fi
    done
}

#we continue asking for the client token
function ask_client_token(){
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Back"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi

    initial=$CLIENT_TOKEN
    while true; do
        CLIENT_TOKEN=$(whiptail --backtitle "$MAIN_TITLE" --title "Client token" --inputbox "Enter the client token" --ok-button $ok_button --cancel-button $cancel_button 8 78 "$CLIENT_TOKEN" 3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            CLIENT_TOKEN=$initial
            return 1
        fi
        if ! validate_client_token; then
            continue
        else
            return 0
        fi
    done
}

#we continue asking for the PACS AET
function ask_pacs_aet(){
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Back"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi

    initial=$PACS_AET
    while true; do
        PACS_AET=$(whiptail --backtitle "$MAIN_TITLE" --title "PACS AET" --inputbox "Enter the PACS AET" --ok-button $ok_button --cancel-button $cancel_button 8 78 "$PACS_AET" 3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            PACS_AET=$initial
            return 1
        fi
        if [ -z "$PACS_AET" ]; then
            whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "PACS AET can't be empty. Please review settings" 8 50
            continue
        else
            return 0
        fi
    done
}

#we continue asking for the PACS IP
function ask_pacs_ip(){
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Back"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi

    initial=$PACS_IP
    while true; do
        PACS_IP=$(whiptail --backtitle "$MAIN_TITLE" --title "PACS IP" --inputbox "Enter the PACS IP" --ok-button $ok_button --cancel-button $cancel_button 8 78 "$PACS_IP" 3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            PACS_IP=$initial
            return 1
        fi
        if ! validate_ip; then
            continue
        else
            return 0
        fi
    done
}

#we continue asking for the PACS port
function ask_pacs_port(){
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Back"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi

    initial=$PACS_PORT
    while true; do
        PACS_PORT=$(whiptail --backtitle "$MAIN_TITLE" --title "PACS Port" --inputbox "Enter the PACS port" --ok-button $ok_button --cancel-button $cancel_button 8 78 "$PACS_PORT" 3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            PACS_PORT=$initial
            return 1
        fi
        if ! validate_pacs_port; then
            continue
        else
            return 0
        fi
    done
}

function ask_scp_port() {
    initial=$SCP_PORT
    # we loop until the user enters a valid SCP port, we use whiptail to ask input to user
    while true; do
        SCP_PORT=$(whiptail --title "PACSOR" --backtitle "$MAIN_TITLE" --nocancel --inputbox "Enter the SCP port" 8 78 "$SCP_PORT" 3>&1 1>&2 2>&3)
        # we disable the cancel button to force the user to enter a valid port
        if [ $? -ne 0 ]; then
            continue
        fi
        if ! validate_scp_port; then
            continue
        else
            return 0
        fi
    done
}

function ask_milvue_aet() {
    initial=$MILVUE_AET
    # we loop until the user enters a valid Milvue AE title, we use whiptail to ask input to user
    while true; do
        MILVUE_AET=$(whiptail --title "PACSOR" --backtitle "$MAIN_TITLE" --nocancel --inputbox "Enter the Milvue AE title" 8 78 "$MILVUE_AET" 3>&1 1>&2 2>&3)
        # we disable the cancel button to force the user to enter a valid Milvue AE title
        if [ $? -ne 0 ]; then
            continue
        fi
        if ! validate_milvue_aet; then
            continue
        else
            return 0
        fi
    done
}

function ask_debug(){
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Back"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi

    DEBUG=$(whiptail --backtitle "$MAIN_TITLE" --title "Debug mode" --yesno "Enable debug mode?" --ok-button $ok_button --cancel-button $cancel_button 8 78 --defaultno --yes-button "Yes" --no-button "No" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
        DEBUG="Yes"
    else
        DEBUG="No"
    fi
    return 0   
}

#ask if we add a symlink or not. SYMLINK is Yes or No
function ask_symlink(){
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Back"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi

    SYMLINK=$(whiptail --backtitle "$MAIN_TITLE" --title "Symlink mode" --yesno "Enable symlink mode?" --ok-button $ok_button --cancel-button $cancel_button 8 78 --yes-button "Yes" --no-button "No" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
        SYMLINK="Yes"
    else
        SYMLINK="No"
    fi
    return 0
}

#ask for ask_dicom_filter_profile in a predefined single radio list (using whiptail radiolist) of dicom filter profiles:Default,WithSC,WithRF,WithSCRF
function ask_dicom_filter_profile(){
    if [ "$1" = "wizard" ]; then
        wizard="true"
        ok_button="Next"
        cancel_button="Back"
    else
        ok_button="Ok"
        cancel_button="Cancel"
        wizard="false"
    fi

    # Map friendly names to URLs
    declare -A profiles=(
        ["Default"]="Default"
        ["WithSC"]="WithSC"
        ["WithRF"]="WithRF"
        ["WithSCRF"]="WithSCRF"
    )
    
    local options=("Default" "WithSC" "WithRF" "WithSCRF")
    local prompt="Select DICOM filter profile:"
    local default_status
    local choice

    while true; do
        # Setup the options for the radiolist
        local radiolist_options=()
        for option in "${options[@]}"; do
            default_status="OFF"
            if [[ "${profiles[$option]}" == "$SCP_CONFIG_PROFILE" ]]; then
                default_status="ON"  # Set the default based on the current SCP_CONFIG_PROFILE
            fi
            radiolist_options+=("$option" "" "$default_status")
        done

        # Display the radiolist
        choice=$(whiptail --backtitle "$MAIN_TITLE" --title "DICOM filter profile" --radiolist "$prompt" --ok-button $ok_button --cancel-button $cancel_button 15 50 5 "${radiolist_options[@]}" 3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return 1
        fi

        SCP_CONFIG_PROFILE="${profiles[$choice]}"
        return 0
    done
}
