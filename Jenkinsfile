pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'https://github.com/thiagofarbo/demo.git']]
                ])
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
//         stage('Deploy') {
//             steps {
//                 // Add your deployment steps here, e.g., using SCP, SSH, Docker, etc.
//                 sh 'scp build/libs/*.jar user@server:/path/to/deploy'
//             }
//         }
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