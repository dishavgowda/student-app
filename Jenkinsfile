@Library('my-shared-lib') _

pipeline {
    agent any 

    environment {
        AWS_REGION = "${Constant.AWS_REGION}"
        ACCOUNT_ID = "${Constant.ACCOUNT_ID}"
        ECR_REPO   = "${Constant.ECR_REPO}"
    }

    stages {

        stage('Checkout') {
            steps {
                deleteDir()
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${Constant.GIT_BRANCH}"]],
                    userRemoteConfigs: [[
                        url: Constant.GIT_URL,
                        credentialsId: Constant.GIT_CREDENTIALS_ID
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
                    fileId: Constant.MAVEN_SETTINGS_ID,
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
                    credentialsId: Constant.AWS_CREDENTIALS_ID
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
                    credentialsId: Constant.AWS_CREDENTIALS_ID
                ]]) {
                    sh '''
                    aws ecr describe-repositories --repository-names ${ECR_REPO} --region ${AWS_REGION} || \
                    aws ecr create-repository --repository-name ${ECR_REPO} --region ${AWS_REGION}
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                sh "docker push ${IMAGE_URI}"
            }
        }

        stage('Run Container') {
            steps {
                sh """
                docker rm -f ${Constant.CONTAINER_NAME} || true
                docker run -d -p ${Constant.CONTAINER_PORT_MAPPING} \
                --name ${Constant.CONTAINER_NAME} ${IMAGE_URI}
                """
            }
        }
    }
}
