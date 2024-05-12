#!/bin/bash

# Vérifier si Google Chrome est installé
if ! command -v google-chrome &> /dev/null; then
    echo "Google Chrome n'est pas installé sur ce système. Installez-le d'abord."
    exit 1
fi

# Obtenir la version actuelle de Google Chrome
chrome_version=$(google-chrome --version | cut -d ' ' -f 3)

# Utiliser la version de Chrome pour construire l'URL de téléchargement du chromedriver
# Note: Cette méthode suppose que la structure de l'URL et la disponibilité des versions de chromedriver correspondent exactement aux versions de Chrome.
# Cela peut ne pas toujours être le cas, surtout pour les versions très récentes ou spécifiques de Chrome.
download_url="https://storage.googleapis.com/chrome-for-testing-public/${chrome_version}/linux64/chromedriver-linux64.zip"

# Télécharger le chromedriver depuis l'URL construite
wget "$download_url" -O chromedriver-linux64.zip

if [ $? -eq 0 ]; then
    # Le téléchargement a réussi

    # Supprimer le chromedriver existant s'il existe
    if [ -e /usr/bin/chromedriver ]; then
        sudo rm /usr/bin/chromedriver
    fi

    # Décompresser le chromedriver
    unzip chromedriver-linux64.zip
    cd chromedriver-linux64

    # Déplacer le chromedriver vers /usr/bin/
    sudo mv chromedriver /usr/bin/chromedriver
    sudo chown root:root /usr/bin/chromedriver
    sudo chmod +x /usr/bin/chromedriver

    cd ..

    # Nettoyer les fichiers temporaires
    rm chromedriver-linux64.zip

    rm -rf chromedriver-linux64
else
    echo "Le téléchargement du chromedriver a échoué."
fi