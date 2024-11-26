#!/bin/bash

tput reset
tput civis

show_orange() {
    echo -e "\e[33m$1\e[0m"
}

show_blue() {
    echo -e "\e[34m$1\e[0m"
}

show_green() {
    echo -e "\e[32m$1\e[0m"
}

show_red() {
    echo -e "\e[31m$1\e[0m"
}

exit_script() {
    show_red "Скрипт остановлен (Script stopped)"
        echo
        exit 0
}

incorrect_option () {
    echo
    show_red "Неверная опция. Пожалуйста, выберите из тех, что есть."
    echo
    show_red "Invalid option. Please choose from the available options."
    echo
}

process_notification() {
    local message="$1"
    show_orange "$message"
    sleep 1
}

run_commands() {
    local commands="$*"

    if eval "$commands"; then
        sleep 1
        echo
        show_green "Успешно (Success)"
        echo
    else
        sleep 1
        echo
        show_red "Ошибка (Fail)"
        echo
    fi
}

check_rust_version() {
    if command -v rustc &> /dev/null; then
        INSTALLED_RUST_VERSION=$(rustc --version | awk '{print $2}')
        show_orange "Установленная версия Rust: $INSTALLED_RUST_VERSION"
    else
        INSTALLED_RUST_VERSION=""
        show_blue "Rust не установлен (not installed)"
    fi
    echo
}

install_or_update_rust() {
    if [ -z "$INSTALLED_RUST_VERSION" ]; then
        process_notification "Устанавливаем (Installing) Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
        show_green "Rust установлен."
    elif [ "$INSTALLED_RUST_VERSION" != "$LATEST_RUST_VERSION" ]; then
        process_notification "Обновляем (Updating) Rust"
        rustup update
        show_green "Rust обновлён (Updated)."
    else
        show_green "Rust последней версии (Rust allready last version) ($LATEST_RUST_VERSION)."
    fi
    echo
}



print_logo () {
    echo
    show_orange "  _______  .______       __       ___ " && sleep 0.2
    show_orange " |       \ |   _  \     |  |     /   \ " && sleep 0.2
    show_orange " |  .--.  ||  |_)  |    |  |    /  ^  \ " && sleep 0.2
    show_orange " |  |  |  ||      /     |  |   /  /_\  \ " && sleep 0.2
    show_orange " |  '--'  ||  |\  \----.|  |  /  _____  \ " && sleep 0.2
    show_orange " |_______/ | _|  ._____||__| /__/     \__\ " && sleep 0.2
    echo
    sleep 1
}

while true; do
    print_logo
    show_green "------ MAIN MENU ------ "
    echo "1. Подготовка (Preparation)"
    echo "2. Установка (Installation)"
    echo "3. Управление (Operational menu)"
    echo "4. Логи (Logs)"
    echo "5. Удаление (Delete)"
    echo "6. Выход (Exit)"
    echo
    read -p "Выберите опцию (Select option): " option

    case $option in
        1)
            # PREPARATION
            process_notification "Начинаем подготовку (Starting preparation)..."
            run_commands "cd $HOME && sudo apt update && sudo apt upgrade -y && apt install unzip screen"

            process_notification "Проверяем (Cheking) Rust..."
            sleep 2
            install_or_update_rust

            process_notification "Устанавливаем (Installing Ollama)..."
            run_commands "curl -fsSL https://ollama.com/install.sh | sh"
            echo
            show_green "$(ollama --version)"
            echo
            show_green "--- ПОГОТОВКА ЗАЕРШЕНА. PREPARATION COMPLETED ---"
            echo
            ;;
        2)
            # INSTALLATION
            process_notification "Установка (Installation)..."
            echo
            show_blue "YOUR SYSTEM = $(uname -m)"
            echo
            show_orange "1. ARM/aarch64"
            show_orange "2. x86_64"
            echo
            read -p "Выберите опцию (Select option): " option
            case $option in
                1)
                    process_notification "Скачиваем (Downloading)..."
                    run_commands "curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-arm64.zip"
                    ;;
                2)
                    process_notification "Скачиваем (Downloading)..."
                    run_commands "curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip"
                    ;;
            esac
            process_notification "Распаковка (Extracting)..."
            run_commands "unzip dkn-compute-node.zip && rm dkn-compute-node.zip"
            echo
            show_green "--- УСТАНОВЛЕНА. INSTALLED ---"
            echo
            ;;
        3)
            # OPERATIONAL
            while true; do
                show_green "------ OPERATIONAL MENU ------ "
                echo "1. Зaпуск (Start)"
                echo "2. Остановка (Stop)"
                echo "3. Сменить модель (Change model)"
                echo "4. Выход (Exit)"
                echo
                read -p "Выберите опцию (Select option): " option
                echo
                case $option in
                    1)
                        process_notification "Запускаем (Starting)..."
                        sleep 2
                        screen -dmS dria bash -c "cd $HOME/dkn-compute-node && exec ./dkn-compute-launcher" && screen -r dria
                        ;;
                    2)
                        process_notification "Останавливаем (Stopping)..."
                        run_commands "screen -r dria -X quit"
                        ;;
                    3)
                        # CHANGE MODEL
                        process_notification "Останавливаем (Stoping)..."
                        run_commands "screen -r dria -X quit"

                        process_notification "Запускаем (Starting)..."
                        sleep 1
                        screen -dmS dria bash -c "cd $HOME/dkn-compute-node && ./dkn-compute-launcher -pick-models" && screen -r dria
                        ;;
                    4)
                        break
                        ;;
                    *)
                        incorrect_option
                        ;;
                esac
            done
            ;;
        4)
            # LOGS
            process_notification "Подключаемся (Connecting)..." && sleep 2
            cd $HOME && screen -r dria
            ;;
        5)
            # DELETE
            process_notification "Удаление (Deleting)..."
            echo
            while true; do
                read -p "Удалить ноду? Delete node? (yes/no): " option

                case "$option" in
                    yes|y|Y|Yes|YES)
                        process_notification "Останавливаем (Stopping)..."
                        run_commands "screen -r dria -X quit"

                        process_notification "Чистим (Cleaning)..."
                        run_commands "rm -rvf $HOME/dkn-compute-node"

                        show_green "--- НОДА УДАЛЕНА. NODE DELETED. ---"
                        break
                        ;;
                    no|n|N|No|NO)
                        process_notification "Отмена (Cancel)"
                        echo ""
                        break
                        ;;
                    *)
                        incorrect_option
                        ;;
                esac
            done
            ;;
        6)
            exit_script
            ;;
        *)
            incorrect_option
            ;;
    esac
done
jina_e8f229f0d21a462fbe5e2406a853b040u7j_G1zpkdwfuR3_rharXRzq3aoG

llama3.1:latest
