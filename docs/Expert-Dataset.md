# Expert Dataset

In hope to pretrain any agent using supervised learning from real players' moves, we have provided an easy way to collect expert data using the cloud so that anyone can upload and retrieve te played games and experiment with them. This module of the package is by no means complete and requires some additionnal effort.

TetrisAI uses a data generation pipeline in which the games played by experts (humans) can be uploaded or downloaded to a cloud server (here AWS). Indeed, each game that exceeds a score threshold will be uploaded to a S3 Bucket. Once enough data is generated to train your agents, the generated data can then be downloaded locally to create/filter a dataset to train your intelligent agent.

Here are some suggested steps to setup AWS:

    1. Create an AWS account with ROOT ACCESS: https://aws.amazon.com/resources/create-account/
    2. Create a S3 Bucket: https://docs.aws.amazon.com/AmazonS3/latest/userguide/creating-bucket.html
    3. Configure an API Gateway (for the REST API that can retrieve the files in the Bucket): https://repost.aws/knowledge-center/api-gateway-upload-image-s3
    4. Generate an IAM role and create an accesKeyId/secretAccessKey pair.

To connect the project with the AWS S3 Bucket where the data is sent to, create a folder named .aws on the User Home (~/.aws for Linux and %HOMEPATH%/.aws for Windows) and copie the *credentials* and *config* files located in the ./docs/AWS/ directory in the TetrisAI repository. You should replace and fill in the fields to put your AWS credentials there so that the connection can be made properly.

    1. cd ~ (cd %HOMEPATH% for Windows)
    2. mkdir .aws && cd .aws
    3. Copy the file *credentials* into that new directory and replace the fields with your own access keys.
    4. Copy the file *config* into the same directory and replace the values marked 'your region'.

The game data collection can be achieved from two different access points:

    1. The TetrisAI game interface implemented in Julia: TetrisAI.collect_data()
    2. The Tetris web game interface that was implemented to collect Tetris data games at larger scale than having to run the TetrisAI app because games are uploaded directly from the website