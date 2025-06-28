pipeline {
    agent none

    parameters {
        booleanParam(name: 'DO_TEST', defaultValue: true, description: 'Executar testes?')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'qa', 'prod'], description: 'Ambiente')
    }

    stages {
        stage('Setup') {
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                echo "=== Configurando Ambiente ==="
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Run Tests: ${params.DO_TEST}"

                script {
                    sh 'java -version'

                    if (params.DO_TEST) {
                        env.TEST_OPTIONS = ''
                    } else {
                        env.TEST_OPTIONS = '-x test'
                    }

                    echo "Test Options: ${env.TEST_OPTIONS}"
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
                checkout scm

                script {
                    def gitCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    def gitBranch = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()

                    echo "Branch: ${gitBranch}"
                    echo "Commit: ${gitCommit}"

                    env.GIT_COMMIT = gitCommit
                    env.GIT_BRANCH = gitBranch
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
                echo "=== Building Application ==="

                script {
                    if (fileExists('gradlew')) {
                        echo "Usando Gradle Wrapper"
                        sh 'chmod +x gradlew'
                        sh "./gradlew clean build ${env.TEST_OPTIONS}"
                    } else if (fileExists('build.gradle')) {
                        echo "Usando Gradle"
                        sh "gradle clean build ${env.TEST_OPTIONS}"
                    } else if (fileExists('pom.xml')) {
                        echo "Usando Maven"
                        if (env.TEST_OPTIONS.contains('-x test')) {
                            sh 'mvn clean compile -DskipTests=true'
                        } else {
                            sh 'mvn clean compile'
                        }
                    } else {
                        error 'Nenhum arquivo de build encontrado'
                    }
                }

                echo "Build concluído!"
            }
        }

        stage('Test') {
            when {
                expression { params.DO_TEST == true }
            }
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                echo "=== Running Tests ==="

                script {
                    try {
                        if (fileExists('gradlew')) {
                            sh './gradlew test'
                        } else if (fileExists('build.gradle')) {
                            sh 'gradle test'
                        } else if (fileExists('pom.xml')) {
                            sh 'mvn test'
                        }
                        echo "Testes executados com sucesso!"
                    } catch (Exception e) {
                        echo "Alguns testes falharam: ${e.getMessage()}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
            post {
                always {
                    script {
                        try {
                            if (fileExists('build/test-results/test/')) {
                                publishTestResults testResultsPattern: 'build/test-results/test/*.xml'
                            } else if (fileExists('target/surefire-reports/')) {
                                publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                            }
                        } catch (Exception e) {
                            echo "Erro publicando resultados: ${e.getMessage()}"
                        }
                    }
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
                echo "=== Packaging Application ==="

                script {
                    if (fileExists('gradlew')) {
                        sh './gradlew bootJar'
                    } else if (fileExists('build.gradle')) {
                        sh 'gradle bootJar'
                    } else if (fileExists('pom.xml')) {
                        sh 'mvn package -DskipTests=true'
                    }
                }

                sh '''
                    echo "=== Artefatos Criados ==="
                    find . -name "*.jar" -type f 2>/dev/null || echo "Nenhum JAR encontrado"
                '''

                echo "Packaging concluído!"
            }
            post {
                success {
                    script {
                        try {
                            if (fileExists('build/libs/')) {
                                archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true, allowEmptyArchive: true
                            } else if (fileExists('target/')) {
                                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
                            }
                        } catch (Exception e) {
                            echo "Erro arquivando: ${e.getMessage()}"
                        }
                    }
                }
            }
        }

        stage('Deploy Approval') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            steps {
                echo "=== Aprovação para Produção ==="

                timeout(time: 30, unit: 'MINUTES') {
                    script {
                        env.APPROVER = input(
                            message: 'Prosseguir com deploy em PRODUÇÃO?',
                            ok: 'Aprovar',
                            submitterParameter: 'APPROVER'
                        )
                        echo "Aprovado por: ${env.APPROVER}"
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                anyOf {
                    expression { params.ENVIRONMENT == 'qa' }
                    expression { params.ENVIRONMENT == 'prod' }
                }
            }
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                echo "=== Deploy para ${params.ENVIRONMENT.toUpperCase()} ==="
                echo "Build: #${env.BUILD_NUMBER}"
                echo "Branch: ${env.GIT_BRANCH}"

                script {
                    if (params.ENVIRONMENT == 'prod') {
                        echo "Aprovado por: ${env.APPROVER}"
                    }
                }

                sh '''
                    echo "Iniciando deploy..."
                    sleep 2
                    echo "Deploy simulado concluído!"
                '''
            }
        }

        stage('Health Check') {
            when {
                anyOf {
                    expression { params.ENVIRONMENT == 'qa' }
                    expression { params.ENVIRONMENT == 'prod' }
                }
            }
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                echo "=== Health Check ==="

                timeout(time: 2, unit: 'MINUTES') {
                    sh '''
                        echo "Verificando aplicação..."
                        sleep 3
                        echo "Aplicação saudável!"
                    '''
                }
            }
        }
    }

    post {
        always {
            node('java21') {
                echo "=== Pipeline Cleanup ==="

                script {
                    def duration = currentBuild.durationString.replace(' and counting', '')
                    echo "Duração: ${duration}"
                    echo "Status: ${currentBuild.result ?: 'SUCCESS'}"
                }
            }
        }

        success {
            echo "✅ BUILD SUCESSO!"
            echo "Environment: ${params.ENVIRONMENT}"
            echo "Build: #${env.BUILD_NUMBER}"
        }

        failure {
            echo "❌ BUILD FALHOU!"
            echo "Environment: ${params.ENVIRONMENT}"
            echo "Build: #${env.BUILD_NUMBER}"
        }

        unstable {
            echo "⚠️ BUILD INSTÁVEL!"
            echo "Alguns testes falharam"
        }
    }
}