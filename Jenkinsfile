pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        ACCOUNT_ID = "042608219765"
        ECR_REPO = "devops/sample-app"
    }

    stages {

        stage('Checkout') {
            steps {
                deleteDir() 
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/dishavgowda/student-app.git',
                        credentialsId: 'github_token'
                    ]]
                ])
            }
        }

        stage('Read Version from pom.xml') {
            steps {
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    env.VERSION = pom.version
                    env.IMAGE_URI = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${VERSION}"
                }
            }
        }

        stage('Build WAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Archive WAR') {
            steps {
                archiveArtifacts artifacts: '**/target/*.war', fingerprint: true
            }
        }

        stage('Deploy to Artifactory') {
            steps {
                configFileProvider([configFile(
                    fileId: '769a2761-858b-4e3c-9f22-f67b7cca93a6',
                    variable: 'MAVEN_SETTINGS'
                )]) {
                    sh 'mvn deploy -s $MAVEN_SETTINGS'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${ECR_REPO}:${VERSION} .
                docker tag ${ECR_REPO}:${VERSION} ${IMAGE_URI}
                """
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials'
                ]]) {
                    sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

       stage('Create ECR Repo if Not Exists') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws_credentials'
                ]]) {
                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
        
                    aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} || \
                    aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION}
                    '''
                }
            }
        }
        stage('Push to ECR') {
            steps {
                sh """
                docker push ${IMAGE_URI}
                """
            }
        }

        stage('Run Container') {
            steps {
                sh """
                docker rm -f student-app || true
                docker run -d -p 8082:8080 --name student-app ${IMAGE_URI}
                """
            }
        }
    }
}






