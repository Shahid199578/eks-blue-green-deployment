pipeline {
    agent any
    tool {
        maven 'Maven Tool'
    }
    environment {
        IMAGE = "shahid199578/demoapp"
        VERSION = "v1"
        AWS_REGION = "ap-south-1"
        CLUSTER_NAME = "demoapp-cluster"
    }

    stages {
        stage ('Checkout'){
            steps {
                git ''
            }
        }
        stage ('complie'){
            steps {
                sh 'mvn clean package'

            }
        }

        stage ('Run Test') {
            steps {
                sh 'mvn test'
            }
        }
        stage ('Code Scan with Sonar') {
            steps {
                script {
                    withSonarQubeEnv('SonarQube') {
                        sh "mvn sonar:sonar -Dsonar.projectKey=demoapp"
                    }
                }
            }
        }
        stage ('Trivy File Scan') {
            steps {
                sh 'trivy image fs . > trivy-report.txt || true'
            }
        }

        stage ('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE}:${VERSION} ."
            }
        }
        stage ('Trivy image Scan') {
            steps {
                sh 'trivy image ${IMAGE}:${VERSION} > trivy-image-report.txt || true'
            }
        }

        stage ('Push Docker image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh """
                        echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                        docker push ${IMAGE}:${VERSION}
                    """
                }
            }
        }

        stage ('Deploy to EKS') {
            steps {
                script {
                    sh """
                        aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME
                        sed 's|dockerimage|${IMAGE}:${VERSION}|' k8s/green-deployment.yaml | kubectl apply -f -
                    """
                }
            }
        }
        stage ('Switch traffic to Green') {
            steps {
                sh "kubectl patch svc demoapp-service -p '{\"spec\":{\"selector\":{\"app\":\"demoapp\",\"version\":\"green\"}}}'"
            }
        }
    }
}