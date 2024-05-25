#!/bin/bash

# Checkpoint file
CHECKPOINT_FILE="/tmp/install_checkpoint"

# Function to save a checkpoint
save_checkpoint() {
    echo "$1" > "$CHECKPOINT_FILE"
}

# Function to load the last checkpoint
load_checkpoint() {
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        cat "$CHECKPOINT_FILE"
    else
        echo "0"
    fi
}

# Function to get the latest PHP versions
get_latest_php_versions() {
    curl -s https://www.php.net/downloads | grep -oP 'PHP \K[0-9]+\.[0-9]+' | sort -ur | tail -n 5
}

# Function to get the latest Node.js versions
get_latest_node_versions() {
    curl -s https://nodejs.org/en/about/previous-releases | grep -oP 'v[0-9]+' | sort -rV | uniq | head -n 5 | sed 's/v//'
}

# Function to get the latest Java versions
get_latest_java_versions() {
    curl -s https://www.oracle.com/java/technologies/javase/jdk-relnotes-index.html | grep -oP '(?<=JDK )\d+' | grep -v '22' | head -n 5
}

# Function to get the latest Python versions
get_latest_python_versions() {
    curl -s https://devguide.python.org/versions/ | grep -oP '(?<=<td><p>)[0-9]+\.[0-9]+' | head -n 5
}

# Initialize variables
USERNAME=$(whoami)
USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)

echo "Running script..."
read -p "This script will modify system settings and install multiple packages. Continue? (Y/n) " confirmation

# Set default value if no answer is provided
confirmation=${confirmation:-y}

# Check the user's response
if [[ "$confirmation" != "y" ]]; then
    echo "Aborting installation."
    exit 1
fi

echo "Installation continuing..."

# Load the last checkpoint
checkpoint=$(load_checkpoint)

if [[ "$checkpoint" -le 1 ]]; then
    if ! sudo grep -q "$USERNAME ALL=(ALL) NOPASSWD: ALL" /etc/sudoers.d/$USERNAME; then
        echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee -a' visudo -f /tmp/$USERNAME
        if ! sudo visudo -c -f /tmp/$USERNAME; then
            echo "Sudoers file is invalid. Exiting." >&2
            exit 1
        fi
        sudo mv /tmp/$USERNAME /etc/sudoers.d/$USERNAME
    fi
    save_checkpoint 1
fi

if [[ "$checkpoint" -le 2 ]]; then
    sudo apt-get update -y && sudo apt-get upgrade -y
    save_checkpoint 2
fi

#################
#  Basic tools  #
#################
if [[ "$checkpoint" -le 3 ]]; then
    echo "Installing basic tools..."
    sudo apt-get install -y git curl wget vim zsh tmux htop tree nmap net-tools zip openssh-server \
                            libmcrypt-dev libicu-dev libxml2-dev libxslt1-dev libnss3-tools snapd \
                            libfreetype6-dev libxrender1 libfontconfig1 libfuse2 \
                            libx11-dev libxtst6 libpng-dev zlib1g-dev libjpeg-dev libonig-dev libwebp-dev \
                            libqt5svg5 jpegoptim optipng webp gnupg2 libpq-dev libzip-dev unzip sudo make \
                            xz-utils tk-dev libffi-dev liblzma-dev libncurses5-dev libncursesw5-dev

    sudo systemctl disable apache2
    save_checkpoint 3
fi

###################
# PHP & Composer  #
###################
if [[ "$checkpoint" -le 4 ]]; then
    INSTALLED_PHP_VERSIONS=$(php -v 2>/dev/null | grep -oP '^PHP \K[^\s]+' || echo "none")
    LATEST_PHP_VERSIONS=$(get_latest_php_versions)

    echo "Currently installed PHP versions: $INSTALLED_PHP_VERSIONS"
    echo "Available PHP versions to install:"
    echo "$LATEST_PHP_VERSIONS"
    echo -n "Enter the PHP versions you want to install : "
    read PHP_VERSIONS

    IFS=', ' read -r -a PHP_VERSIONS_ARRAY <<< "$PHP_VERSIONS"

    for PHP_VERSION in "${PHP_VERSIONS_ARRAY[@]}"; do
        if php -v | grep -q "$PHP_VERSION"; then
            echo "PHP $PHP_VERSION is already installed."
        else
            echo "Adding PHP $PHP_VERSION PPA..."
            sudo add-apt-repository ppa:ondrej/php -y
            sudo apt-get update
            sudo apt-get install -y php$PHP_VERSION php${PHP_VERSION}-cli php${PHP_VERSION}-fpm php${PHP_VERSION}-pgsql php${PHP_VERSION}-xml \
                                    php${PHP_VERSION}-mbstring php${PHP_VERSION}-curl php${PHP_VERSION}-zip php${PHP_VERSION}-intl \
                                    php${PHP_VERSION}-gd php${PHP_VERSION}-imagick php${PHP_VERSION}-xdebug php${PHP_VERSION}-ldap \
                                    php${PHP_VERSION}-xsl

            sudo update-alternatives --install /usr/bin/php php /usr/bin/php${PHP_VERSION} 60
            sudo update-alternatives --install /usr/bin/php-config php-config /usr/bin/php-config${PHP_VERSION} 60
            sudo update-alternatives --install /usr/bin/phpize phpize /usr/bin/phpize${PHP_VERSION} 60
        fi
    done

     if ! command -v composer &> /dev/null; then
            curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
            composer --version
        else
            echo "Composer is already installed."
     fi

    save_checkpoint 4
fi

#######################
#  Node / yarn / npm  #
#######################
if [[ "$checkpoint" -le 5 ]]; then
    INSTALLED_NODE_VERSIONS=$(nvm ls 2>/dev/null || echo "none")
    LATEST_NODE_VERSIONS=$(get_latest_node_versions)

    echo "Currently installed Node.js versions: $INSTALLED_NODE_VERSIONS"
    echo "Available Node.js versions to install:"
    echo "$LATEST_NODE_VERSIONS"
    echo -n "Enter the Node.js versions you want to install : "
    read NODE_VERSIONS

    IFS=', ' read -r -a NODE_VERSIONS_ARRAY <<< "$NODE_VERSIONS"

    if ! command -v nvm &> /dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    for NODE_VERSION in "${NODE_VERSIONS_ARRAY[@]}"; do
        if nvm ls | grep -q "v$NODE_VERSION"; then
            echo "Node.js $NODE_VERSION is already installed."
        else
            nvm install $NODE_VERSION
        fi
        nvm use $NODE_VERSION
    done

    if ! command -v npx &> /dev/null; then
        npm install -g npx
    else
        echo "npx is already installed."
    fi

    save_checkpoint 5
fi

##########
#  Java  #
##########
if [[ "$checkpoint" -le 6 ]]; then
    INSTALLED_JAVA_VERSIONS=$(update-alternatives --list java | grep -oP 'java-\K[0-9]+' || echo "none")
    LATEST_JAVA_VERSIONS=$(curl -s https://www.oracle.com/java/technologies/javase/jdk-relnotes-index.html | grep -oP '(?<=JDK )\d+' | grep -v '22' | head -n 5)

    echo "Currently installed Java versions: $INSTALLED_JAVA_VERSIONS"
    echo "Available Java versions to install:"
    echo "$LATEST_JAVA_VERSIONS"
    echo -n "Enter the Java versions you want to install : "
    read JAVA_VERSIONS

    IFS=', ' read -r -a JAVA_VERSIONS_ARRAY <<< "$JAVA_VERSIONS"

    for JAVA_VERSION in "${JAVA_VERSIONS_ARRAY[@]}"; do
        if update-alternatives --list java | grep -q "java-$JAVA_VERSION"; then
            echo "Java $JAVA_VERSION is already installed."
        else
            case $JAVA_VERSION in
                8) JAVA_PACKAGE="openjdk-8-jdk" ;;
                11) JAVA_PACKAGE="openjdk-11-jdk" ;;
                17) JAVA_PACKAGE="openjdk-17-jdk" ;;
                20) JAVA_PACKAGE="openjdk-20-jdk" ;;
                21) JAVA_PACKAGE="openjdk-21-jdk" ;;
                18) JAVA_PACKAGE="openjdk-18-jdk" ;;
                19) JAVA_PACKAGE="openjdk-19-jdk" ;;
                *) echo "Invalid choice or unavailable version, exiting."; exit 1 ;;
            esac

            echo "Installing $JAVA_PACKAGE..."
            sudo apt-get install -y $JAVA_PACKAGE
            sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64/bin/java 100
            sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64/bin/javac 100
        fi
    done
    save_checkpoint 6
fi


############
#  Python  #
############
if [[ "$checkpoint" -le 7 ]]; then
    INSTALLED_PYTHON_VERSIONS=$(pyenv versions 2>/dev/null || echo "none")
    LATEST_PYTHON_VERSIONS=$(get_latest_python_versions)

    echo "Currently installed Python versions: $INSTALLED_PYTHON_VERSIONS"
    echo "Available Python versions to install:"
    echo "$LATEST_PYTHON_VERSIONS"
    echo -n "Enter the Python versions you want to install : "
    read PYTHON_VERSIONS

    IFS=', ' read -r -a PYTHON_VERSIONS_ARRAY <<< "$PYTHON_VERSIONS"

    if ! command -v pyenv &> /dev/null; then
        curl https://pyenv.run | bash
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
    fi

    for PYTHON_VERSION in "${PYTHON_VERSIONS_ARRAY[@]}"; do
        if pyenv versions | grep -q "$PYTHON_VERSION"; then
            echo "Python $PYTHON_VERSION is already installed."
        else
            pyenv install $PYTHON_VERSION
        fi
        pyenv global $PYTHON_VERSION
    done

    save_checkpoint 7
fi

#############
#  Symfony  #
#############
if [[ "$checkpoint" -le 8 ]]; then
    if ! command -v symfony &> /dev/null; then
        echo "Installing Symfony CLI..."
        curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash
        sudo apt install symfony-cli
    fi
    save_checkpoint 8
fi

###############
#  oh-my-zsh  #
###############
if [[ "$checkpoint" -le 9 ]]; then
    if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
        echo "Installing brew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        echo "Installing oh-my-zsh..."
        echo "Before proceeding with the installation of Powerlevel10k, please download and install the following fonts to ensure correct theme display:"
        echo "1. MesloLGS NF Regular: https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
        echo "2. MesloLGS NF Bold: https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
        echo "3. MesloLGS NF Italic: https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
        echo "4. MesloLGS NF Bold Italic: https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"

        echo "Please open these links in a web browser and download each font file. Then install the fonts by double-clicking the downloaded files or adding them to your system's font manager."

        read -p "Press [Enter] once the fonts are installed to continue with the installation of Powerlevel10k."

        ZSH="$USER_HOME/.oh-my-zsh" sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" --unattended

        # Clone Powerlevel10k theme
        if [ ! -d "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
            echo "Cloning Powerlevel10k..."
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k
        else
            echo "Powerlevel10k already cloned."
        fi

        # Clone zsh-autosuggestions plugin
        if [ ! -d "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
            echo "Cloning zsh-autosuggestions..."
            git clone https://github.com/zsh-users/zsh-autosuggestions $USER_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
        else
            echo "zsh-autosuggestions already cloned."
        fi

        # Clone zsh-syntax-highlighting plugin
        if [ ! -d "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
            echo "Cloning zsh-syntax-highlighting..."
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $USER_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
        else
            echo "zsh-syntax-highlighting already cloned."
        fi

        echo "Creating backup for .zshrc..."
        sudo cp $USER_HOME/.zshrc $USER_HOME/.zshrc.backup
        sudo cp -f ./.zshrc $USER_HOME/.zshrc

        echo "Oh-my-zsh installed. Please restart your terminal to apply changes."
    fi
    save_checkpoint 9
fi

###############
#  Workspace  #
###############
if [[ "$checkpoint" -le 10 ]]; then
    if [ ! -d "$USER_HOME/dev" ]; then
        echo "Creating workspace directory..."
        sudo mkdir -p $USER_HOME/dev
        sudo chmod -R 777 $USER_HOME/dev
    fi

    if [ ! -d "/opt/jetbrains-toolbox" ]; then
        wget https://download.jetbrains.com/toolbox/jetbrains-toolbox-2.3.1.31116.tar.gz
        sudo tar -xzf jetbrains-toolbox-2.3.1.31116.tar.gz -C /opt
        sudo mv /opt/jetbrains-toolbox-2.3.1.31116 /opt/jetbrains-toolbox
        sudo ln -sf /opt/jetbrains-toolbox/jetbrains-toolbox /usr/local/bin/jetbrains
        sudo rm jetbrains-toolbox-2.3.1.31116.tar.gz
    fi
    save_checkpoint 10
fi

######################
#  Chrome & firefox  #
######################
if [[ "$checkpoint" -le 11 ]]; then
    if ! command -v google-chrome &> /dev/null; then
        echo "Installing Chrome and Firefox..."
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo dpkg -i google-chrome-stable_current_amd64.deb
        sudo apt-get install -f
        sudo rm google-chrome-stable_current_amd64.deb

        CHROMEVERSION=$(google-chrome --version)
        CHROMEDRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/$CHROMEVERSION/linux64/chromedriver-linux64.zip"
        wget $CHROMEDRIVER_URL

        tar -xzf chromedriver-linux64.zip
        sudo mv chromedriver /usr/local/bin/

        echo chromedriver --version
    fi

    if ! command -v firefox &> /dev/null; then
        sudo snap install firefox
    fi

    sudo cp -f ./updateChromeDriver.sh /usr/local/bin/updateChromeDriver.sh
    sudo chmod 777 /usr/local/bin/updateChromeDriver.sh
    echo 'DPkg::Post-Invoke {"/usr/local/bin/updateChromeDriver.sh";};' | sudo tee /etc/apt/apt.conf.d/99runscript > /dev/null
    save_checkpoint 11
fi

#################
#  Platform sh  #
#################
if [[ "$checkpoint" -le 12 ]]; then
    if ! command -v platform &> /dev/null; then
        echo "Installing Platform.sh CLI"
        curl -fsSL https://raw.githubusercontent.com/platformsh/cli/main/installer.sh | bash
    fi

    sudo apt-get update -y && sudo apt-get upgrade -y

    echo "Linux dependency installation script complete."
    save_checkpoint 12
fi

# Cleanup checkpoint file after successful execution
rm -f "$CHECKPOINT_FILE"

sudo apt autoremove -y

zsh
