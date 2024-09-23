#!/bin/bash
# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should not be run directly. Please use the parent script."
    whiptail --title "Error" --msgbox "This script should not be run directly. Please use the parent script." 8 78
    exit 1
fi


function validate_version_name()
{
    if [ -z "$VERSION_NAME" ]; then
        whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Version name can't be empty. Please review settings" 8 50
        return 1
    fi
    return 0

    # validate version name format v<major>.<minor>.<patch> or dev.12345678
    if ! [[ "$VERSION_NAME" =~ ^(v[0-9]+\.[0-9]+\.[0-9]+|dev\.[0-9a-fA-F]{8})$ ]]; then
        whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Invalid version name, should use this format v<major>.<minor>.<patch> OR dev.<8-digits-hex>. Please review settings" 12 50
        return 1
    fi
    
    return 0
}

function validate_url()
{
    if [ -z "$INTEGRATOR_URL" ]; then
        whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Integrator URL can't be empty. Please review settings" 8 50
        return 1
    fi
    #validate URL format with this scheme: http(s)://<hostname>:<port>. port is optional, it can be http or https
    if ! [[ "$INTEGRATOR_URL" =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?$ ]]; then
        whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Invalid URL format. Please review settings" 8 50
        return 1
    fi

    return 0
}

# validate client name with scheme countrycode.partnername.clientname.sitename.confid
function validate_client_name()
{
    if [ -z "$CLIENT_NAME" ]; then
        whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Client name can't be empty. Please review settings" 8 50
        return 1
    fi

    if ! [[ "$CLIENT_NAME" =~ ^[a-zA-Z]{2,8}\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+$ ]]; then
        whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Invalid client name format. Please review settings" 8 50
        return 1
    fi

    return 0
}


function validate_client_token()
{
    if [ -z "$CLIENT_TOKEN" ]; then
        whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Client token can't be empty. Please review settings" 8 50
        return 1
    fi

    return 0
}

function validate_ip()
{
    if [ -z "$PACS_IP" ] || ! [[ "$PACS_IP" =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
        whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Invalid IP. Please review settings" 8 50
        return 1
    fi   
    return 0
}

function validate_pacs_port()
{
    if [ -z "$PACS_PORT" ]; then
        whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "PACS port can't be empty. Please review settings" 8 50
        return 1
    fi

    if [ -z "$PACS_PORT" ] || ! [[ "$PACS_PORT" =~ ^[0-9]+$ ]] || [ "$PACS_PORT" -lt 100 ] || [ "$PACS_PORT" -gt 65535 ]; then
        whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Invalid PACS port. Please review settings" 8 50
        return 1
    fi
    return 0
}

function validate_scp_port()
{
    if [ "$PACSOR" = "y" ]; then
        if [ -z "$SCP_PORT" ] || ! [[ "$SCP_PORT" =~ ^[0-9]+$ ]] || [ "$SCP_PORT" -lt 1024 ] || [ "$SCP_PORT" -gt 65535 ]; then
            whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Invalid SCP port. Please review settings" 8 50
            return 1
        fi
    fi
    return 0
}

function validate_milvue_aet()
{
    if [ "$PACSOR" = "y" ]; then
        if [ -z "$MILVUE_AET" ]; then
            whiptail --title "Error" --backtitle "$MAIN_TITLE" --msgbox "Invalid Milvue AET. Please review settings" 8 50
            return 1
        fi
    fi
    return 0
}