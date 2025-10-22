pipeline {
    agent {
        docker {
            image 'abhigyop/jenkins-agent:latest'
            args '-u root:root' // run as root to access docker & install dependencies
        }
    }

    environment {
        DOCKER_REGISTRY = 'abhigyop'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Verify Environment') {
            steps {
                sh 'node -v'
                sh 'npm -v'
                sh 'docker --version'
                sh 'git --version'
            }
        }

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/abhiguop/user-management.git',
                    credentialsId: 'github-credentials'
            }
        }

        stage('Install Dependencies & Test Backend') {
            steps {
                dir('backend') {
                    sh 'npm install'
                    sh 'npm test'
                }
            }
        }

        stage('Install Dependencies & Test Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm test -- --coverage --watchAll=false'
                }
            }
        }

        stage('Build & Push Docker Images') {
            parallel {
                stage('Backend Image') {
                    steps {
                        dir('backend') {
                            script {
                                def backendImage = docker.build("${DOCKER_REGISTRY}/user-management-backend:${IMAGE_TAG}")
                                docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
                                    backendImage.push("${IMAGE_TAG}")
                                    backendImage.push("latest")
                                }
                            }
                        }
                    }
                }
                stage('Frontend Image') {
                    steps {
                        dir('frontend') {
                            script {
                                def frontendImage = docker.build("${DOCKER_REGISTRY}/user-management-frontend:${IMAGE_TAG}")
                                docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
                                    frontendImage.push("${IMAGE_TAG}")
                                    frontendImage.push("latest")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        success { echo '🎉 Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed!' }
        always { sh 'docker system prune -f || true' }
    }
}
