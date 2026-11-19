pipeline {
    agent any

    environment {
        IMAGE_NAME     = 'jenkins-flask-lab'
        CONTAINER_NAME = 'jenkins-flask-app'
        APP_PORT       = '8081'
        NETWORK_NAME   = 'jenkins-net'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Source code is available in the workspace.'
            }
        }
        stage('Build') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .'
            }
        }
        stage('Test') {
            steps {
                sh 'docker run --rm ${IMAGE_NAME}:${BUILD_NUMBER} pytest -v'
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                    docker rm -f ${CONTAINER_NAME} || true
                    docker run -d --network ${NETWORK_NAME} --name ${CONTAINER_NAME} \
                        -p ${APP_PORT}:8000 -e APP_VERSION=${BUILD_NUMBER} \
                        ${IMAGE_NAME}:${BUILD_NUMBER}
                '''
            }
        }
        stage('Verify') {
            steps {
                sh 'curl --fail --retry 10 --retry-delay 2 http://${CONTAINER_NAME}:8000/health'
                sh 'curl --fail http://${CONTAINER_NAME}:8000/'
                sh 'curl --fail http://host.docker.internal:${APP_PORT}/health'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check the stage that reported an error.'
        }
    }
}
