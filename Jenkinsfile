pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-repo/spring-boot-app.git'
            }
        }
        stage('Build') {
            steps {
                sh './gradlew clean build' // Use 'mvn clean install' if using Maven
            }
        }
        stage('Test') {
            steps {
                sh './gradlew test' // Use 'mvn test' if using Maven
            }
        }
        stage('Package') {
            steps {
                sh './gradlew bootJar' // Use 'mvn package' if using Maven
            }
        }
        stage('Deploy') {
            steps {
                // Add your deployment steps here, e.g., using SCP, SSH, Docker, etc.
                sh 'scp build/libs/*.jar user@server:/path/to/deploy'
            }
        }
    }

    post {
        success {
            echo 'Build and Deploy succeeded!'
        }
        failure {
            echo 'Build or Deploy failed!'
        }
    }
}