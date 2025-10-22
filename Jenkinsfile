pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'abhigyop'        // Your Docker Hub username
        IMAGE_TAG = "${BUILD_NUMBER}"       // Jenkins build number as image tag
        KUBERNETES_SERVER = 'https://kubernetes.default.svc'  
    }

    stages {
        // Stage 1: Checkout code from GitHub
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/abhiguop/user-management.git',
                    credentialsId: 'github-credentials'
            }
        }

        // Stage 2: Install dependencies and run backend tests
        stage('Install Dependencies & Test Backend') {
            steps {
                dir('backend') {
                    sh 'npm install'
                    sh 'npm test'
                }
            }
        }

        // Stage 3: Install dependencies and run frontend tests
        stage('Install Dependencies & Test Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm test -- --coverage --watchAll=false'
                }
            }
        }

        // Stage 4: Build & push Docker images (parallel for speed)
        stage('Build & Push Docker Images') {
            parallel {
                stage('Backend Image') {
                    steps {
                        script {
                            dir('backend') {
                                def backendImage = docker.build("${DOCKER_REGISTRY}/user-management-backend:${IMAGE_TAG}")
                                docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
                                    backendImage.push("${IMAGE_TAG}")  // push version tag
                                    backendImage.push("latest")       // push latest tag
                                }
                            }
                        }
                    }
                }
                stage('Frontend Image') {
                    steps {
                        script {
                            dir('frontend') {
                                def frontendImage = docker.build("${DOCKER_REGISTRY}/user-management-frontend:${IMAGE_TAG}")
                                docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
                                    frontendImage.push("${IMAGE_TAG}")  // push version tag
                                    frontendImage.push("latest")       // push latest tag
                                }
                            }
                        }
                    }
                }
            }
        }

        // Stage 5: Verify Kubernetes connectivity
        stage('Verify Kubernetes Connectivity') {
            steps {
                script {
                    echo '🔍 Verifying Kubernetes API (In-cluster ServiceAccount)...'
                    sh 'kubectl cluster-info'
                    sh 'kubectl get nodes -o wide'
                }
            }
        }

        // Stage 6: Deploy updated images to Kubernetes
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    sh """
                        sed -i 's|your-registry/user-management-backend:latest|${DOCKER_REGISTRY}/user-management-backend:${IMAGE_TAG}|g' k8s/backend-deployment.yaml
                        sed -i 's|your-registry/user-management-frontend:latest|${DOCKER_REGISTRY}/user-management-frontend:${IMAGE_TAG}|g' k8s/frontend-deployment.yaml
                        kubectl apply -f k8s/
                        kubectl rollout status deployment/backend-deployment
                        kubectl rollout status deployment/frontend-deployment
                    """
                }
            }
        }

        // Stage 7: Verify deployment status
        stage('Verify Deployment') {
            steps {
                script {
                    sh 'kubectl get pods -o wide'
                    sh 'kubectl get services'
                    sh 'kubectl wait --for=condition=ready pod -l app=backend --timeout=300s'
                    sh 'kubectl wait --for=condition=ready pod -l app=frontend --timeout=300s'
                }
            }
        }
    }

    // Post actions
    post {
        success { echo '🎉 Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed!' }
        always { sh 'docker system prune -f' }
    }
}
