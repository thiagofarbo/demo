// Jenkinsfile - Pipeline sem ferramentas pré-configuradas
@Library('my-shared-library@main') _

pipeline {
    agent none

    environment {
        MAVEN_OPTS = '-Xmx512m'
    }

    stages {
        stage('Setup Environment') {
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                script {
                    // Valida ambiente Java 21 no nó
                    validateJavaEnvironment()
                }
            }
        }

        stage('Checkout') {
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                script {
                    gitCheckout()
                }
            }
        }

        stage('Build') {
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                script {
                    javaBuild([
                        buildTool: 'maven',
                        goals: 'clean compile'
                    ])
                }
            }
        }

        stage('Test') {
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                script {
                    javaTest([
                        goals: 'test',
                        publishResults: true
                    ])
                }
            }
            post {
                always {
                    publishTestResults(
                        testResultsPattern: 'target/surefire-reports/*.xml',
                        allowEmptyResults: true
                    )
                }
            }
        }

        stage('Package') {
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                script {
                    javaPackage([
                        goals: 'package -DskipTests'
                    ])
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar',
                                   fingerprint: true,
                                   allowEmptyArchive: true
                }
            }
        }
    }

    post {
        always {
            node('java21') {
                script {
                    cleanupBuild()
                }
            }
        }
        success {
            script {
                sendNotification([
                    status: 'SUCCESS',
                    message: "Build ${env.BUILD_NUMBER} concluído com sucesso!"
                ])
            }
        }
        failure {
            script {
                sendNotification([
                    status: 'FAILURE',
                    message: "Build ${env.BUILD_NUMBER} falhou!"
                ])
            }
        }
    }
}