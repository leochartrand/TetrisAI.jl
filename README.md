# TetrisAI

TetrisAI utilise un pipeline de données pour le téléversement/téléchargement des données de jeux à l'aide des services offerts par AWS. En effet à la fin de chaque partie pertinentes (i.e. qui dépasse un certain score désiré), les données de jeux sont téléversées sur un S3 Bucket. Une fois la quantité de données de jeux désirée est créée, les données recueillies peuvent être téléchargées localement pour ensuite créer un dataset pour l'entraînement de l'agent intelligent.

Les étapes de confirguration AWS :

    1. Créer un compte AWS avec un ROOT ACCESS: https://aws.amazon.com/resources/create-account/
    2. Créer un S3 Bucket: https://docs.aws.amazon.com/AmazonS3/latest/userguide/creating-bucket.html
    3. Configurer un API Gateway(pour GET/PUT fichiers dans le Bucket): https://repost.aws/knowledge-center/api-gateway-upload-image-s3
    4. Générer un rôle IAM et créer une paire accesKeyId/secretAccessKey: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html

Pour connecter le projet avec le Bucket AWS S3 où les données de jeux sont acheminées, créer un dossier nommé .aws sur User Home (cd %HOMEPATH% pour WINDOWS, cd ~ pour LINUX/MAC) et copier les fichiers credentials et config se trouvant dans docs/AWS du projet, en remplaçant 'your accessKeyId', 'your secretAccessKey' et 'your region' par les valeurs correspondantes:

    1. cd %HOMEPATH% pour WINDOWS ou cd ~ pour LINUX/MAC
    2. mkdir .aws && cd .aws
    3. Copier le fichier credientials en remplaçant les valeurs 'your accessKeyId' et 'your secretAccessKey'
    4. Copier le fichier config en remplaçant les valeurs 'your region'


La collecte de données de jeux peut se faire selon deux points d'accès différents:

    1. L'interface implémentée en Julia grâce au package GameZero.jl :
       TetrisAI.collect_data()
    2. L'interface implémentée en HTML + Javascript disponible sur navigateur web (code sur la branche javascript-tetris) :
       https://tetrisaitrainer.com/

#### __Documentation TetrisAI__
| Récente |
|:-------:|
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://docs.tetrisaitrainer.com)

