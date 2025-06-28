// Jenkinsfile sem Shared Library - Funcional
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
            description: 'Ambiente para deploy'
        )
    }

    environment {
        PROJECT_NAME = 'demo-app'
        BUILD_TYPE = 'gradle'
        JAVA_OPTS = '-Xmx1024m'
    }

    stages {
        stage('Setup') {
            agent {
                node {
                    label 'java21'
                }
            }
            steps {
                script {
                    echo "=== Configurando ambiente ${params.ENVIRONMENT} ==="

                    // Validação do Java
                    sh 'java -version'
                    sh 'echo "Java Version: $(java -version 2>&1 | head -n 1)"'

                    // Configuração de variáveis
                    if (params.DO_TEST) {
                        env.TEST_OPTIONS = ''
                    } else {
                        env.TEST_OPTIONS = '-x test'
                    }

                    echo "Environment: ${params.ENVIRONMENT}"
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
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'https://github.com/thiagofarbo/demo.git']]
                ])

                script {
                    // Informações do Git
                    env.GIT_COMMIT = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()

                    env.GIT_BRANCH = sh(
                        script: 'git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()

                    echo "Branch: ${env.GIT_BRANCH}"
                    echo "Commit: ${env.GIT_COMMIT}"
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
                    echo "=== Build da aplicação ==="

                    if (fileExists('gradlew')) {
                        sh "./gradlew clean build ${env.TEST_OPTIONS}"
                    } else if (fileExists('build.gradle')) {
                        sh "gradle clean build ${env.TEST_OPTIONS}"
                    } else if (fileExists('pom.xml')) {
                        if (env.TEST_OPTIONS.contains('-x test')) {
                            sh 'mvn clean compile -DskipTests'
                        } else {
                            sh 'mvn clean compile'
                        }
                    } else {
                        error 'Nenhum arquivo de build encontrado (gradlew, build.gradle, pom.xml)'
                    }
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
                    echo "=== Executando testes ==="

                    try {
                        if (fileExists('gradlew')) {
                            sh './gradlew test'
                        } else if (fileExists('build.gradle')) {
                            sh 'gradle test'
                        } else if (fileExists('pom.xml')) {
                            sh 'mvn test'
                        }
                    } catch (Exception e) {
                        echo "Erro nos testes: ${e.getMessage()}"
                        throw e
                    }
                }
            }
            post {
                always {
                    script {
                        // Publicar resultados de teste
                        if (fileExists('build/test-results/test/*.xml')) {
                            publishTestResults(
                                testResultsPattern: 'build/test-results/test/*.xml',
                                allowEmptyResults: true
                            )
                        } else if (fileExists('target/surefire-reports/*.xml')) {
                            publishTestResults(
                                testResultsPattern: 'target/surefire-reports/*.xml',
                                allowEmptyResults: true
                            )
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
                    echo "=== Empacotando aplicação ==="

                    if (fileExists('gradlew')) {
                        sh './gradlew bootJar'
                    } else if (fileExists('build.gradle')) {
                        sh 'gradle bootJar'
                    } else if (fileExists('pom.xml')) {
                        sh 'mvn package -DskipTests'
                    }

                    // Verificar se artefatos foram criados
                    script {
                        def gradleJars = sh(
                            script: 'find build/libs -name "*.jar" -type f 2>/dev/null || echo ""',
                            returnStdout: true
                        ).trim()

                        def mavenJars = sh(
                            script: 'find target -name "*.jar" -type f 2>/dev/null || echo ""',
                            returnStdout: true
                        ).trim()

                        if (gradleJars) {
                            echo "Artefatos Gradle encontrados: ${gradleJars}"
                        } else if (mavenJars) {
                            echo "Artefatos Maven encontrados: ${mavenJars}"
                        } else {
                            echo "Aviso: Nenhum JAR encontrado"
                        }
                    }
                }
            }
            post {
                success {
                    script {
                        // Arquivar artefatos
                        def artifactsFound = false

                        if (fileExists('build/libs/')) {
                            try {
                                archiveArtifacts(
                                    artifacts: 'build/libs/*.jar',
                                    fingerprint: true,
                                    allowEmptyArchive: true
                                )
                                artifactsFound = true
                            } catch (Exception e) {
                                echo "Erro arquivando artefatos Gradle: ${e.getMessage()}"
                            }
                        }

                        if (!artifactsFound && fileExists('target/')) {
                            try {
                                archiveArtifacts(
                                    artifacts: 'target/*.jar',
                                    fingerprint: true,
                                    allowEmptyArchive: true
                                )
                            } catch (Exception e) {
                                echo "Erro arquivando artefatos Maven: ${e.getMessage()}"
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy Approval') {
            when {
                expression { params.ENVIRONMENT == 'prod' }
            }
            agent none
            steps {
                script {
                    echo "=== Solicitando aprovação para PRODUÇÃO ==="

                    timeout(time: 30, unit: 'MINUTES') {
                        env.APPROVER = input(
                            message: 'Deseja prosseguir com o deploy em PRODUÇÃO?',
                            ok: 'Aprovar Deploy',
                            submitterParameter: 'APPROVER'
                        )
                    }

                    echo "Deploy aprovado por: ${env.APPROVER}"
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
                    echo "=== Deploy para ${params.ENVIRONMENT} ==="

                    // Simulação de deploy - substitua pelos seus comandos reais
                    switch(params.ENVIRONMENT) {
                    case 'qa':
                            sh '''
                                echo "Fazendo deploy para QA..."
                                echo "Projeto: demo-app"
                                echo "Ambiente: qa"
                                # Aqui você colocaria seus comandos reais de deploy
                            '''
                            break

                        case 'prod':
                            sh '''
                                echo "Fazendo deploy para PRODUÇÃO..."
                                echo "Projeto: demo-app"
                                echo "Ambiente: prod"
                                echo "Aprovado por: ${APPROVER}"
                                # Aqui você colocaria seus comandos reais de deploy
                            '''
                            break
                    }
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
                    echo "=== Verificação de saúde ==="

                    // Simulação de health check
                    timeout(time: 5, unit: 'MINUTES') {
                        retry(3) {
                            sh '''
                                echo "Verificando saúde da aplicação..."
                                echo "Ambiente: ${ENVIRONMENT}"
                                # Substitua por verificação real, ex:
                                # curl -f http://app-url/health || exit 1
                                sleep 2
                                echo "Aplicação saudável!"
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            node('java21') {
                script {
                    echo "=== Limpeza final ==="

                    // Limpeza básica
                    sh '''
                        # Limpeza de arquivos temporários
                        find . -name "*.tmp" -delete 2>/dev/null || true
                        find . -name "*.log" -delete 2>/dev/null || true
                    '''

                    def duration = currentBuild.durationString.replace(' and counting', '')
                    echo "Pipeline finalizada em ${duration}"
                }
            }
        }

        success {
            script {
                echo "✅ BUILD SUCESSO!"
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Build: #${env.BUILD_NUMBER}"
                echo "Branch: ${env.GIT_BRANCH}"
                echo "Commit: ${env.GIT_COMMIT}"
            }
        }

        failure {
            script {
                echo "❌ BUILD FALHOU!"
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Build: #${env.BUILD_NUMBER}"
                echo "Verifique os logs acima para detalhes do erro"
            }
        }

        aborted {
            script {
                echo "⚠️ BUILD CANCELADO!"
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Build: #${env.BUILD_NUMBER}"
            }
        }
    }
}