pipeline {
    agent any
    
    environment {
        // Define your credentials IDs here as they exist in Jenkins
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        KUBECONFIG_CREDENTIALS_ID = 'k3s-kubeconfig'
    }

    stages {
        // ==========================================
        // TEST STAGES
        // ==========================================
        stage('Test AI Vision Service') {
            when {
                anyOf {
                    changeset "services/ai-vision-service/**/*"
                    changeset "libs/shared-core/**/*"
                }
            }
            steps {
                sh '''
                python3.12 -m venv venv-ai
                . venv-ai/bin/activate
                pip install ./libs/shared-core
                pip install -e ./services/ai-vision-service
                pip install pytest httpx
                pytest services/ai-vision-service/tests
                '''
            }
        }
        
        stage('Test Attendance Service') {
            when {
                anyOf {
                    changeset "services/attendance-service/**/*"
                    changeset "libs/shared-core/**/*"
                }
            }
            steps {
                sh '''
                python3.12 -m venv venv-attendance
                . venv-attendance/bin/activate
                pip install ./libs/shared-core
                pip install -e ./services/attendance-service
                pip install pytest httpx
                pytest services/attendance-service/tests
                '''
            }
        }

        stage('Test Scheduling Service') {
            when {
                anyOf {
                    changeset "services/scheduling-service/**/*"
                    changeset "libs/shared-core/**/*"
                }
            }
            steps {
                sh '''
                python3.12 -m venv venv-scheduling
                . venv-scheduling/bin/activate
                pip install ./libs/shared-core
                pip install -e ./services/scheduling-service
                pip install pytest httpx
                pytest services/scheduling-service/tests
                '''
            }
        }

        // ==========================================
        // BUILD AND PUSH STAGES
        // ==========================================
        stage('Build & Push AI Vision Service') {
            when {
                anyOf {
                    changeset "services/ai-vision-service/**/*"
                    changeset "libs/shared-core/**/*"
                }
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS_ID}", passwordVariable: 'DOCKERHUB_TOKEN', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                        sh "echo \$DOCKERHUB_TOKEN | docker login -u \$DOCKERHUB_USERNAME --password-stdin"
                        
                        def app = docker.build("${DOCKERHUB_USERNAME}/ai-vision-service:${env.GIT_COMMIT}", "-f services/ai-vision-service/Dockerfile .")
                        app.push()
                        app.push("latest")
                    }
                }
            }
        }
        
        stage('Build & Push Attendance Service') {
            when {
                anyOf {
                    changeset "services/attendance-service/**/*"
                    changeset "libs/shared-core/**/*"
                }
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS_ID}", passwordVariable: 'DOCKERHUB_TOKEN', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                        sh "echo \$DOCKERHUB_TOKEN | docker login -u \$DOCKERHUB_USERNAME --password-stdin"
                        
                        def app = docker.build("${DOCKERHUB_USERNAME}/attendance-service:${env.GIT_COMMIT}", "-f services/attendance-service/Dockerfile .")
                        app.push()
                        app.push("latest")
                    }
                }
            }
        }

        stage('Build & Push Scheduling Service') {
            when {
                anyOf {
                    changeset "services/scheduling-service/**/*"
                    changeset "libs/shared-core/**/*"
                }
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS_ID}", passwordVariable: 'DOCKERHUB_TOKEN', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                        sh "echo \$DOCKERHUB_TOKEN | docker login -u \$DOCKERHUB_USERNAME --password-stdin"
                        
                        def app = docker.build("${DOCKERHUB_USERNAME}/scheduling-service:${env.GIT_COMMIT}", "-f services/scheduling-service/Dockerfile .")
                        app.push()
                        app.push("latest")
                    }
                }
            }
        }

        // ==========================================
        // DEPLOYMENT STAGE
        // ==========================================
        stage('Deploy to K3s Cluster') {
            when {
                branch 'main' // Ensure deployments only happen from the main branch
            }
            steps {
                withKubeConfig([credentialsId: "${KUBECONFIG_CREDENTIALS_ID}"]) {
                    withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS_ID}", passwordVariable: 'DOCKERHUB_TOKEN', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                        sh '''
                        # Replace DockerHub username placeholder with actual username
                        sed -i "s|DOCKERHUB_USERNAME_PLACEHOLDER|${DOCKERHUB_USERNAME}|g" k8s/*.yaml
                        
                        # Apply Kubernetes manifests
                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f k8s/configmap.yaml
                        kubectl apply -f k8s/scheduling-service.yaml
                        kubectl apply -f k8s/attendance-service.yaml
                        kubectl apply -f k8s/ai-vision-service.yaml
                        kubectl apply -f k8s/traefik-middleware.yaml
                        kubectl apply -f k8s/ingress.yaml
                        
                        # Restart Deployments to fetch new images
                        kubectl rollout restart deployment/scheduling-service -n smart-attendance
                        kubectl rollout restart deployment/attendance-service -n smart-attendance
                        kubectl rollout restart deployment/ai-vision-service -n smart-attendance
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up workspace after build to save disk space
            cleanWs()
        }
    }
}
