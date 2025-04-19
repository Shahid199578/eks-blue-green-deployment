pipeline {
    agent any
    tools {
        maven 'Maven-Tool'
    }
    environment {
        IMAGE = "shahid199578/demoapp"
        VERSION = "Green"
        AWS_REGION = "ap-south-1"
        CLUSTER_NAME = "demoapp-cluster"
    }
    stages{
        stage('Checkout') {
            steps {
                git 'https://github.com/Shahid199578/eks-blue-green-deployment.git'
            }
        }
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Run Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Code Scan with SonarQube') {
            steps {
                script {
                    withSonarQubeEnv('SonarQube') {
                        sh "mvn sonar:sonar -Dsonar.projectKey=demoapp"
                    }
                }
            }
        }
        stage('trivy File Scan') {
            steps {
                sh 'trivy fs . > trivy-file-report || true'
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                   sh "docker build -t ${IMAGE}:${VERSION} ."
                }
            }
        }
        stage('trivy  Docker image Scan') {
            steps {
                sh 'trivy image ${IMAGE}:${VERSION} > trivy-image-report || true'
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh """
                            echo $PASSWORD | docker login -u $USERNAME --password-stdin
                            docker push $IMAGE:$VERSION
                        """
                    }
                }
            }
        }
                stage('Deploy to EKS') {
            steps {
                script {
                        sh """
                        aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME
                        sed 's|dockerimage|${IMAGE}:${VERSION}|' k8s/green-deployment.yaml | kubectl apply -f -
                        """
                    }
                }
            }
            stage('switch Traffic to Green') {
            steps {
                sh "kubectl patch svc demoapp-service -p '{\"spec\":{\"selector\":{\"app\":\"demoapp\",\"version\":\"green\"}}}'"
            }
        }
    }
}