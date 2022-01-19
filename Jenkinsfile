pipeline {
    agent any

    stages {
        stage("Packer_Build") {
            steps{
                sh '''
                    aws s3 cp s3://sergo.manifest/Packer/manifest.json ./manifest.json
                    terraform init
                    terraform apply -auto-approve -no-color
                '''
            }
        }
    }
}