@Library('my-shared-library@main')

pipeline {
    agent { node { label 'java21' } }
    stages {
        stage('Build') {
            steps {
                script {
                    gitCheckout()
                    javaBuild()
                    javaTest()
                    javaPackage()
                }
            }
        }
    }
}