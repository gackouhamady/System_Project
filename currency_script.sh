#!/bin/bash

# Chemin vers le répertoire de stockage des données CurrencyLayer
DATA_DIR="./currency_data"
# Fichier de suivi pour la dernière mise à jour
LAST_UPDATE_FILE="${DATA_DIR}/last_update.txt"

# Vérification et création du dossier si nécessaire
if [ ! -d "$DATA_DIR" ]; then
    echo "Le dossier $DATA_DIR n'existe pas. Création en cours..."
    mkdir -p "$DATA_DIR"
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la création du dossier $DATA_DIR. Vérifiez les permissions."
        exit 1
    fi
fi

# Vérifier si le fichier de dernière mise à jour existe
if [ ! -f "$LAST_UPDATE_FILE" ]; then
    # Si le fichier n'existe pas, l'initialiser à une date ancienne
    echo "1970-01-01T00:00:00Z" > "$LAST_UPDATE_FILE"
fi

# Lire la dernière mise à jour
LAST_UPDATE=$(cat "$LAST_UPDATE_FILE")

# Ajouter un timestamp pour la collecte actuelle
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# URL de l'API CurrencyLayer
API_URL="http://api.currencylayer.com/live"
API_KEY="6425345f5166104ee3fe84df22164985"
CURRENCIES="USD,EUR,CNY"

# Fichier JSON pour stocker les taux de change
FILE_PATH="${DATA_DIR}/currency_rates.json"

# Récupération des données avec curl
RESPONSE=$(curl -s "${API_URL}?access_key=${API_KEY}&currencies=${CURRENCIES}")
if [ $? -ne 0 ]; then
    echo "Erreur lors de la collecte des données depuis l'API CurrencyLayer" >> "${DATA_DIR}/error.log"
    exit 1
fi

# Ajouter un champ "timestamp" à la réponse JSON
DATA=$(echo "$RESPONSE" | jq --arg timestamp "$TIMESTAMP" '. + {timestamp: $timestamp}')

# Ajouter les nouvelles données au fichier JSON
if [ -f "$FILE_PATH" ]; then
    jq ". += [$DATA]" "$FILE_PATH" > temp.json && mv temp.json "$FILE_PATH"
else
    echo "[$DATA]" > "$FILE_PATH"
fi

echo "Données collectées et ajoutées dans $FILE_PATH"

# Mettre à jour la dernière date de mise à jour
echo "$(date --utc +'%Y-%m-%dT%H:%M:%SZ')" > "$LAST_UPDATE_FILE"
