#!/bin/bash

# Vérifier si TAG est défini
if [ -z "$TAG" ]; then
  echo "Erreur : La variable d'environnement TAG n'est pas définie."
  echo "Utilisation : export TAG=rc-beryllium-3; bash pull_and_push_images.sh"
  exit 1
fi

# Nom du registre source et destination
SOURCE_REGISTRY="eu.gcr.io/${REGISTRY_NAME:-milvue-milvue-preprod-428814}/pacsor2"
DESTINATION_REGISTRY="milvue"

# Mapping des images source et destination
declare -A IMAGES=(
  ["storescp"]="pacsor-storescp"
  ["core"]="pacsor-core"
  ["storescu"]="pacsor-storescu"
)

# Fonction pour tirer, taguer et pousser l'image
process_image() {
  local source_image_name=$1
  local destination_image_name=$2
  local tag=$3

  # Tirer l'image depuis le registre source
  docker pull $SOURCE_REGISTRY/$source_image_name:$tag

  # Vérifier si le pull a réussi
  if [ $? -ne 0 ];then
    echo "Erreur : Impossible de tirer l'image $SOURCE_REGISTRY/$source_image_name:$tag."
    exit 1
  fi

  # Taguer l'image avec le nouveau registre et le même tag
  docker tag $SOURCE_REGISTRY/$source_image_name:$tag $DESTINATION_REGISTRY/$destination_image_name:$tag

  # Taguer l'image avec le tag 'latest'
  docker tag $SOURCE_REGISTRY/$source_image_name:$tag $DESTINATION_REGISTRY/$destination_image_name:latest

  # Pousser l'image sur le registre destination (Docker Hub) avec le tag initial
  docker push $DESTINATION_REGISTRY/$destination_image_name:$tag

  # Vérifier si le push a réussi pour le tag initial
  if [ $? -ne 0 ]; then
    echo "Erreur : Impossible de pousser l'image $DESTINATION_REGISTRY/$destination_image_name:$tag."
    exit 1
  fi

  # Pousser l'image sur le registre destination (Docker Hub) avec le tag 'latest'
  docker push $DESTINATION_REGISTRY/$destination_image_name:latest

  # Vérifier si le push a réussi pour le tag 'latest'
  if [ $? -ne 0 ]; then
    echo "Erreur : Impossible de pousser l'image $DESTINATION_REGISTRY/$destination_image_name:latest."
    exit 1
  fi

  echo "Succès : L'image $SOURCE_REGISTRY/$source_image_name:$tag a été tirée, taguée, et poussée en tant que '$DESTINATION_REGISTRY/$destination_image_name:$tag' et 'latest'."
}

# Boucler sur chaque image et traiter
for source_image in "${!IMAGES[@]}"; do
  process_image $source_image ${IMAGES[$source_image]} $TAG
done
