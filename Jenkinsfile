
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        AWS_REGION     = 'eu-west-1'
        EKS_CLUSTER    = 'devops-assessment'
        ECR_REPOSITORY = '121378764632.dkr.ecr.eu-west-1.amazonaws.com/devops-assessment'
        HELM_RELEASE   = 'devops-assessment'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Tools') {
            steps {
                sh '''
                    set -e
                    aws --version
                    docker --version
                    kubectl version --client
                    helm version
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                    set -e
                    aws sts get-caller-identity

                    aws ecr get-login-password \
                      --region "$AWS_REGION" |
                    docker login \
                      --username AWS \
                      --password-stdin \
                      "$(echo "$ECR_REPOSITORY" | cut -d/ -f1)"
                '''
            }
        }

        stage('Build and Push Image') {
            steps {
                sh '''
                    set -e
                    IMAGE_TAG="$BUILD_NUMBER"

                    docker build \
                      -t "$ECR_REPOSITORY:$IMAGE_TAG" \
                      ./app

                    docker push "$ECR_REPOSITORY:$IMAGE_TAG"
                '''
            }
        }

        stage('Deploy to EKS with Helm') {
            steps {
                sh '''
                    set -e

                    aws eks update-kubeconfig \
                      --name "$EKS_CLUSTER" \
                      --region "$AWS_REGION"

                    helm upgrade --install "$HELM_RELEASE" ./helm \
                      --namespace default \
                      --set image.repository="$ECR_REPOSITORY" \
                      --set image.tag="$BUILD_NUMBER" \
                      --wait \
                      --timeout 5m
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    set -e

                    kubectl get deployments,pods,services \
                      --namespace default

                    kubectl rollout status deployment \
                      --namespace default \
                      --selector="app.kubernetes.io/instance=$HELM_RELEASE" \
                      --timeout=180s
                '''
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Review the stage logs to identify the issue.'
        }
    }
}
