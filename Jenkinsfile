pipeline {
    agent none

    parameters {
        booleanParam(
            name: 'DO_TEST',
            defaultValue: true,
            description: 'Executar testes?'
        )
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'qa', 'prod'],
            defaultValue: 'dev',
            description: 'Ambiente'
        )
    }

    stages {
        stage('Environment Setup') {
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                script {
                    echo "=== Configurando Ambiente ==="
                    echo "Environment: ${params.ENVIRONMENT}"
                    echo "Run Tests: ${params.DO_TEST}"

                    // Verificar Java
                    sh 'java -version'
                    sh 'javac -version'

                    // Configurar opções de teste
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
                // Checkout do código
                checkout scm

                script {
                    // Informações do Git
                    def gitCommit = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()

                    def gitBranch = sh(
                        script: 'git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Branch: ${gitBranch}"
                    echo "Commit: ${gitCommit[0..7]}"

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
                script {
                    echo "=== Building Application ==="

                    // Detectar tipo de build
                    if (fileExists('gradlew')) {
                        echo "Usando Gradle Wrapper"
                        sh "chmod +x gradlew"
                        sh "./gradlew clean build ${env.TEST_OPTIONS ?: ''}"
                    } else if (fileExists('build.gradle')) {
                        echo "Usando Gradle"
                        sh "gradle clean build ${env.TEST_OPTIONS ?: ''}"
                    } else if (fileExists('pom.xml')) {
                        echo "Usando Maven"
                        if (env.TEST_OPTIONS && env.TEST_OPTIONS.contains('-x test')) {
                            sh 'mvn clean compile -DskipTests=true'
                        } else {
                            sh 'mvn clean compile'
                        }
                    } else {
                        error 'Nenhum arquivo de build encontrado (gradlew, build.gradle, pom.xml)'
                    }

                    echo "Build concluído!"
                }
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
                script {
                    echo "=== Running Tests ==="

                    try {
                        if (fileExists('gradlew')) {
                            sh './gradlew test --continue'
                        } else if (fileExists('build.gradle')) {
                            sh 'gradle test --continue'
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
                        // Tentar publicar resultados de teste
                        try {
                            if (fileExists('build/test-results/test/')) {
                                publishTestResults testResultsPattern: 'build/test-results/test/*.xml'
                                echo "Resultados de teste Gradle publicados"
                            } else if (fileExists('target/surefire-reports/')) {
                                publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                                echo "Resultados de teste Maven publicados"
                            } else {
                                echo "Nenhum resultado de teste encontrado"
                            }
                        } catch (Exception e) {
                            echo "Erro publicando resultados de teste: ${e.getMessage()}"
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
                script {
                    echo "=== Packaging Application ==="

                    if (fileExists('gradlew')) {
                        sh './gradlew bootJar'
                    } else if (fileExists('build.gradle')) {
                        sh 'gradle bootJar'
                    } else if (fileExists('pom.xml')) {
                        sh 'mvn package -DskipTests=true'
                    }

                    // Verificar artefatos criados
                    sh '''
                        echo "=== Artefatos Criados ==="
                        if [ -d "build/libs" ]; then
                            find build/libs -name "*.jar" -exec ls -lh {} \\;
                        fi
                        if [ -d "target" ]; then
                            find target -name "*.jar" -exec ls -lh {} \\;
                        fi
                    '''

                    echo "Packaging concluído!"
                }
            }
            post {
                success {
                    script {
                        // Arquivar artefatos
                        try {
                            if (fileExists('build/libs/')) {
                                archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true
                                echo "Artefatos Gradle arquivados"
                            } else if (fileExists('target/')) {
                                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                                echo "Artefatos Maven arquivados"
                            }
                        } catch (Exception e) {
                            echo "Erro arquivando artefatos: ${e.getMessage()}"
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
                script {
                    echo "=== Aprovação para Produção ==="

                    timeout(time: 30, unit: 'MINUTES') {
                        def approver = input(
                            message: 'Deseja prosseguir com deploy em PRODUÇÃO?',
                            ok: 'Aprovar Deploy',
                            submitterParameter: 'APPROVER'
                        )

                        env.APPROVER = approver
                        echo "Deploy aprovado por: ${approver}"
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                expression { params.ENVIRONMENT in ['qa', 'prod'] }
            }
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                script {
                    echo "=== Deploy para ${params.ENVIRONMENT.toUpperCase()} ==="

                    // Informações do deploy
                    echo "Projeto: demo-app"
                    echo "Ambiente: ${params.ENVIRONMENT}"
                    echo "Build: #${env.BUILD_NUMBER}"
                    echo "Branch: ${env.GIT_BRANCH}"
                    echo "Commit: ${env.GIT_COMMIT[0..7]}"

                    if (params.ENVIRONMENT == 'prod') {
                        echo "Aprovado por: ${env.APPROVER}"
                    }

                    // Simulação de deploy
                    sh '''
                        echo "Iniciando deploy..."
                        sleep 2
                        echo "Copiando artefatos..."
                        sleep 1
                        echo "Configurando ambiente..."
                        sleep 1
                        echo "Startando aplicação..."
                        sleep 2
                        echo "Deploy concluído!"
                    '''
                }
            }
        }

        stage('Health Check') {
            when {
                expression { params.ENVIRONMENT in ['qa', 'prod'] }
            }
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                script {
                    echo "=== Health Check ==="

                    // Simulação de health check
                    timeout(time: 3, unit: 'MINUTES') {
                        retry(3) {
                            sh '''
                                echo "Verificando saúde da aplicação..."
                                echo "Tentativa de conexão..."
                                sleep 3
                                echo "Aplicação respondendo!"
                                echo "Health check: OK"
                            '''
                        }
                    }

                    echo "Aplicação saudável em ${params.ENVIRONMENT}!"
                }
            }
        }
    }

    post {
        always {
            node('java21') {
                script {
                    echo "=== Pipeline Cleanup ==="

                    // Limpeza básica
                    sh '''
                        echo "Limpando arquivos temporários..."
                        find . -name "*.tmp" -delete 2>/dev/null || true
                        find . -name "*.log" -delete 2>/dev/null || true
                        echo "Limpeza concluída"
                    '''

                    // Resumo final
                    def duration = currentBuild.durationString.replace(' and counting', '')
                    echo "=== RESUMO FINAL ==="
                    echo "Duração: ${duration}"
                    echo "Status: ${currentBuild.result ?: 'SUCCESS'}"
                    echo "Environment: ${params.ENVIRONMENT}"
                    echo "Build: #${env.BUILD_NUMBER}"
                }
            }
        }

        success {
            script {
                echo "🎉 BUILD SUCESSO!"
                echo "✅ Todas as etapas concluídas com êxito"
                echo "📦 Environment: ${params.ENVIRONMENT}"
                echo "🔗 Build: #${env.BUILD_NUMBER}"
                if (env.GIT_BRANCH) {
                    echo "🌿 Branch: ${env.GIT_BRANCH}"
                }
            }
        }

        failure {
            script {
                echo "❌ BUILD FALHOU!"
                echo "💥 Verifique os logs acima para detalhes"
                echo "📦 Environment: ${params.ENVIRONMENT}"
                echo "🔗 Build: #${env.BUILD_NUMBER}"
                echo "⚠️  Pipeline interrompida devido a erro"
            }
        }

        unstable {
            script {
                echo "⚠️  BUILD INSTÁVEL!"
                echo "🧪 Alguns testes falharam, mas build continuou"
                echo "📦 Environment: ${params.ENVIRONMENT}"
                echo "🔗 Build: #${env.BUILD_NUMBER}"
            }
        }

        aborted {
            script {
                echo "🛑 BUILD CANCELADO!"
                echo "👤 Pipeline interrompida pelo usuário"
                echo "📦 Environment: ${params.ENVIRONMENT}"
                echo "🔗 Build: #${env.BUILD_NUMBER}"
            }
        }
    }
}