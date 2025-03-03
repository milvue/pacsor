#!/bin/bash
source ./scripts/menus.deploy.sh
source ./scripts/dialogs.deploy.sh
source ./scripts/validators.deploy.sh

SCRIPT_VERSION="2.0"
MAIN_TITLE="Milvue Gateway Deployment Configuration Tool v$SCRIPT_VERSION"

# Default values
VERSION_NAME="latest"
INTEGRATOR_URL="https://k8s.predict.milvue.com"
USE_SIGNED_URL="true"
SENDER_CALLBACKS_URL="http://storescu:8000"
SCP_PORT="1040"
MILVUE_AET="MILVUE"
SCP_CONFIG_PROFILE="WithSC"
DEBUG="No"
SYMLINK="Yes"
ISLOCALOR=false
HL7_ENABLE="false"
HL7_LANGUAGE="FR"
HL7_INCLUDE_TCR="false"
HL7_TCR_URL="https://k8s.report.milvue.com/report"
HL7_TCR_OUT_FORMAT="PLAIN"

# values to be set
CLIENT_NAME=""
CLIENT_TOKEN=""
PACS_AET=""
PACS_IP=""
PACS_PORT=""
HL7_RECEIVING_APPLICATION=""
HL7_RECEIVING_FACILITY=""
HL7_RIS_IP=""
HL7_RIS_PORT=""

CONFIG_DIR="./scripts"

# save config in order to save all variable in a file that we will be able to load bask. the file name shall be written in CONFIG_DIR and the name of CLIENT_NAME.last.config. if CLIENT_NAME is empty, the file name shall be default.last.config
function save_config(){
    local config_file="$CONFIG_DIR/$CLIENT_NAME.config"
    if [ -z "$CLIENT_NAME" ]; then
        config_file="$CONFIG_DIR/default.config"
    fi

    echo "CLIENT_NAME=$CLIENT_NAME" > $config_file
    echo "CLIENT_TOKEN=$CLIENT_TOKEN" >> $config_file
    echo "VERSION_NAME=$VERSION_NAME" >> $config_file
    echo "INTEGRATOR_URL=$INTEGRATOR_URL" >> $config_file
    echo "USE_SIGNED_URL=$USE_SIGNED_URL" >> $config_file
    echo "SENDER_CALLBACKS_URL=$SENDER_CALLBACKS_URL" >> $config_file
    echo "DEBUG=$DEBUG" >> $config_file
    echo "SYMLINK=$SYMLINK" >> $config_file
    echo "PACS_AET=$PACS_AET" >> $config_file
    echo "PACS_IP=$PACS_IP" >> $config_file
    echo "PACS_PORT=$PACS_PORT" >> $config_file
    echo "SCP_PORT=$SCP_PORT" >> $config_file
    echo "MILVUE_AET=$MILVUE_AET" >> $config_file
    echo "SCP_CONFIG_PROFILE=$SCP_CONFIG_PROFILE" >> $config_file
    echo "ISLOCALOR=$ISLOCALOR" >> $config_file
    echo "HL7_ENABLE=$HL7_ENABLE" >> $config_file
    echo "HL7_LANGUAGE=$HL7_LANGUAGE" >> $config_file
    echo "HL7_INCLUDE_TCR=$HL7_INCLUDE_TCR" >> $config_file
    echo "HL7_TCR_URL=$HL7_TCR_URL" >> $config_file
    echo "HL7_TCR_OUT_FORMAT=$HL7_TCR_OUT_FORMAT" >> $config_file
    echo "HL7_RECEIVING_APPLICATION=$HL7_RECEIVING_APPLICATION" >> $config_file
    echo "HL7_RECEIVING_FACILITY=$HL7_RECEIVING_FACILITY" >> $config_file
    echo "HL7_RIS_IP=$HL7_RIS_IP" >> $config_file
    echo "HL7_RIS_PORT=$HL7_RIS_PORT" >> $config_file
}

#now we search for all config files wich end by .config in the CONFIG_DIR directory. if we find more than one file, we ask user if he wan't to load a specific file by using a radio list. If cancel or user anwser no then we exit 1. If user select a file, we load the content to set env vars.
function load_config(){
    # Find all .config files in the CONFIG_DIR
    local config_files=($(ls $CONFIG_DIR/*.config 2>/dev/null))
    if [ ${#config_files[@]} -eq 0 ]; then
        return 1
    fi

    local menu_options=()
    
    # Prepare menu options array for whiptail
    local index=0
    for file in "${config_files[@]}"; do
        menu_options+=("$index" "$(basename "$file")")
        ((index++))
    done

    # Add the option for creating a new configuration
    menu_options+=("" "")
    menu_options+=("n" "New Configuration")

    # Display menu to user
    local choice
    choice=$(whiptail --title "Select a configuration file" --menu "Choose a configuration file to load or create a new one" 20 78 11 "${menu_options[@]}" 3>&1 1>&2 2>&3)
    local exit_status=$?

    # Check if user canceled the menu
    if [ $exit_status -ne 0 ]; then
        whiptail --title "Info" --msgbox "Wizard cancelled." 8 78
        exit  # User canceled the menu
    fi

    # Handle selection of new configuration
    if [[ "$choice" = "n" || -z "$choice" ]]; then
        return 1  # Indicate that a new configuration process should start
    fi

    local config_file="${config_files[$choice]}"
    if [ -z "$config_file" ]; then
        whiptail --title "Error" --msgbox "Invalid selection." 8 78
        return 1
    fi

    # Source the selected configuration file
    if ! source "$config_file"; then
        whiptail --title "Error" --msgbox "Failed to load $config_file" 8 78
        return 1
    fi

    return 0
}

function create_deploy(){

    # Replace '.' with '-' in CLIENT_NAME and assign to CLIENT_CLEAN_NAME
    CLIENT_CLEAN_NAME=$(echo $CLIENT_NAME | sed 's/\./-/g')

    #Export the variables
    export CLIENT_NAME CLIENT_TOKEN VERSION_NAME CLIENT_CLEAN_NAME INTEGRATOR_URL USE_SIGNED_URL SENDER_CALLBACKS_URL SCP_PORT MILVUE_AET PACS_AET PACS_IP PACS_PORT SCP_CONFIG_PROFILE HL7_LANGUAGE HL7_INCLUDE_TCR HL7_TCR_URL HL7_TCR_OUT_FORMAT HL7_RECEIVING_APPLICATION HL7_RECEIVING_FACILITY HL7_RIS_IP HL7_RIS_PORT

    # Create env-files directory if it does not exist
    mkdir -p env-files

    # Generate the .env file
    cp templates/.env.pacsor.template env-files/.env.$CLIENT_NAME
    if [ "$HL7_ENABLE" = "true" ]; then
        echo "# HL7 Section" >> env-files/.env.$CLIENT_NAME
        cat templates/.env.hl7.template >> env-files/.env.$CLIENT_NAME
        SENDER_CALLBACKS_URL=${SENDER_CALLBACKS_URL},http://hl7:8000
    fi

    envsubst < env-files/.env.$CLIENT_NAME > env-files/.env.$CLIENT_NAME.tmp
    mv env-files/.env.$CLIENT_NAME.tmp env-files/.env.$CLIENT_NAME

    echo "Environment file created."

    # Generate the compose.yaml file
    cp templates/compose.yaml.template compose.yaml

    # Activate localor mode if needed
    if [ "$ISLOCALOR" = "true" ]; then
        sed -i 's/#- override\/compose.localor.pacsor.yaml/- override\/compose.localor.pacsor.yaml/' compose.yaml
    fi

    # Activate the HL7 module if needed
    if [ "$HL7_ENABLE" = "true" ]; then
        sed -i 's/#- pacsor\/compose.hl7.yaml/- pacsor\/compose.hl7.yaml/' compose.yaml
    fi

    # Activate the debug mode if needed
    if [ "$DEBUG" = "Yes" ]; then
        sed -i 's/#- override\/compose.debug.pacsor.yaml/- override\/compose.debug.pacsor.yaml/' compose.yaml
    fi

    echo "Compose file created."

    # Create a symbolic link if needed
    if [ "$SYMLINK" = "Yes" ]; then
        ln -sf env-files/.env.$CLIENT_NAME .env
        echo "Symbolic link created."
    else
        echo "No symbolic link created."
    fi

    return 0
}

function save_and_exit(){
    save_config
    clear
    create_deploy
    exit
}




function main(){
    if ! load_config; then
        if startwizard; then
            main_menu
        fi
    else
        main_menu
    fi
}

#call the main function
main