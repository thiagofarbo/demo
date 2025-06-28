pipeline {
    agent any

    tools {
        maven 'Maven' // Nome configurado no Jenkins
        jdk 'JDK'     // Nome configurado no Jenkins
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Repository checked out successfully'
            }
        }

        stage('Clean & Compile') {
            steps {
                echo 'Starting Java Maven build process...'
                sh 'mvn clean compile'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'mvn test'
            }
            post {
                always {
                    // Publicar resultados dos testes
                    publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                echo 'Packaging application...'
                sh 'mvn package'
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo 'Archiving generated files...'
                sh 'ls -la target/*.jar'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }

    post {
        always {
            echo 'Build completed!'
        }
        success {
            echo 'Build completed successfully!'
        }
        failure {
            echo 'Build failed!'
        }
        cleanup {
            deleteDir() // Limpa workspace
        }
    }
}