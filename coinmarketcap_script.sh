#!/bin/bash

# Chemin vers le répertoire de stockage des données CoinMarketCap
DATA_DIR="./crypto_data"
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

# URL de l'API CoinMarketCap pour les cryptomonnaies
API_BASE_URL="https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest"
CRYPTO_SYMBOLS=("BTC" "ETH")

# Fonction pour ajouter les données au fichier JSON existant
add_to_json() {
    local symbol=$1
    local data=$2
    local file_path=$3

    # Vérifier si le fichier existe déjà
    if [ -f "$file_path" ]; then
        # Si le fichier existe, ajouter les nouvelles données
        jq ". += [$data]" "$file_path" > temp.json && mv temp.json "$file_path"
    else
        # Si le fichier n'existe pas, créer un nouveau fichier avec les données
        echo "[$data]" > "$file_path"
    fi
}

# Récupérer les données pour chaque cryptomonnaie
for SYMBOL in "${CRYPTO_SYMBOLS[@]}"; do
    # Construction du nom de fichier pour chaque cryptomonnaie (BTC, ETH)
    FILE_NAME="${SYMBOL}_data.json"
    FILE_PATH="${DATA_DIR}/${FILE_NAME}"

    # Récupération des données avec curl
    RESPONSE=$(curl -s "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol=${SYMBOL}&CMC_PRO_API_KEY=2beacd6b-947b-47eb-9456-8ce736cf3a2d")
    
    if [ $? -ne 0 ]; then
        echo "Erreur lors de la collecte des données pour $SYMBOL" >> "${DATA_DIR}/error.log"
        continue
    fi

    # Ajouter un champ "timestamp" à chaque donnée récupérée
    DATA=$(echo "$RESPONSE" | jq --arg timestamp "$TIMESTAMP" '. + {timestamp: $timestamp}')

    # Ajouter les nouvelles données au fichier JSON
    add_to_json "$SYMBOL" "$DATA" "$FILE_PATH"

    echo "Données collectées et ajoutées pour $SYMBOL dans $FILE_PATH"
done

# Mettre à jour la dernière date de mise à jour
echo "$(date --utc +'%Y-%m-%dT%H:%M:%SZ')" > "$LAST_UPDATE_FILE"
