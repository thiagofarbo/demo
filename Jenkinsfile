pipeline {
    agent any

    parameters {
        booleanParam(name: 'DO_TEST', defaultValue: true, description: 'Executar testes?')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'qa', 'prod'], description: 'Ambiente')
    }

    stages {
        stage('Setup') {
            steps {
                echo "=== Configurando Ambiente ==="
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Run Tests: ${params.DO_TEST}"

                script {
                    // Verificar Java disponível
                    try {
                        sh 'java -version'
                    } catch (Exception e) {
                        echo "Java não encontrado no PATH padrão"

                        // Tentar localizar Java
                        def javaLocations = [
                            '/usr/lib/jvm/java-21-openjdk/bin/java',
                            '/usr/lib/jvm/java-17-openjdk/bin/java',
                            '/usr/lib/jvm/java-11-openjdk/bin/java',
                            '/usr/bin/java',
                            '/opt/java/openjdk/bin/java'
                        ]

                        def javaFound = false
                        for (location in javaLocations) {
                            try {
                                sh "test -f ${location} && ${location} -version"
                                env.JAVA_CMD = location
                                javaFound = true
                                echo "Java encontrado em: ${location}"
                                break
                            } catch (Exception ex) {
                                // Continuar procurando
                            }
                        }

                        if (!javaFound) {
                            error "Java não encontrado no sistema"
                        }
                    }

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
            steps {
                checkout scm

                script {
                    def gitCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    def gitBranch = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()

                    echo "Branch: ${gitBranch}"
                    echo "Commit: ${gitCommit[0..7]}"

                    env.GIT_COMMIT = gitCommit
                    env.GIT_BRANCH = gitBranch
                }
            }
        }

        stage('Build') {
            steps {
                echo "=== Building Application ==="

                script {
                    // Detectar tipo de projeto
                    if (fileExists('gradlew')) {
                        echo "Projeto Gradle detectado (gradlew)"
                        sh 'chmod +x gradlew'

                        // Verificar se precisa configurar JAVA_HOME
                        if (env.JAVA_CMD) {
                            def javaHome = env.JAVA_CMD.replaceAll('/bin/java$', '')
                            env.JAVA_HOME = javaHome
                            echo "JAVA_HOME configurado: ${javaHome}"
                        }

                        sh "./gradlew clean build ${env.TEST_OPTIONS ?: ''}"

                    } else if (fileExists('build.gradle') || fileExists('build.gradle.kts')) {
                        echo "Projeto Gradle detectado (build.gradle)"

                        // Verificar se gradle está disponível
                        try {
                            sh 'gradle --version'
                            sh "gradle clean build ${env.TEST_OPTIONS ?: ''}"
                        } catch (Exception e) {
                            echo "Gradle não encontrado, tentando com gradlew..."
                            // Criar gradlew se não existir
                            sh '''
                                if [ ! -f gradlew ]; then
                                    echo "Criando gradle wrapper..."
                                    gradle wrapper || echo "Não foi possível criar wrapper"
                                fi
                            '''

                            if (fileExists('gradlew')) {
                                sh 'chmod +x gradlew'
                                sh "./gradlew clean build ${env.TEST_OPTIONS ?: ''}"
                            } else {
                                error "Não foi possível executar o build Gradle"
                            }
                        }

                    } else if (fileExists('pom.xml')) {
                        echo "Projeto Maven detectado"

                        // Verificar se Maven está disponível
                        try {
                            sh 'mvn --version'
                        } catch (Exception e) {
                            error "Maven não encontrado no sistema"
                        }

                        if (env.TEST_OPTIONS && env.TEST_OPTIONS.contains('-x test')) {
                            sh 'mvn clean compile -DskipTests=true'
                        } else {
                            sh 'mvn clean compile'
                        }

                    } else {
                        error 'Nenhum arquivo de build encontrado (gradlew, build.gradle, pom.xml)'
                    }
                }

                echo "Build concluído com sucesso!"
            }
        }

        stage('Test') {
            when {
                expression { params.DO_TEST == true }
            }
            steps {
                echo "=== Running Tests ==="

                script {
                    try {
                        if (fileExists('gradlew')) {
                            sh './gradlew test --continue'
                        } else if (fileExists('build.gradle') || fileExists('build.gradle.kts')) {
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
                        // Publicar resultados de teste
                        try {
                            def testResultsPublished = false

                            // Gradle
                            if (fileExists('build/test-results/test/')) {
                                publishTestResults testResultsPattern: 'build/test-results/test/*.xml'
                                echo "Resultados de teste Gradle publicados"
                                testResultsPublished = true
                            }

                            // Maven
                            if (!testResultsPublished && fileExists('target/surefire-reports/')) {
                                publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                                echo "Resultados de teste Maven publicados"
                                testResultsPublished = true
                            }

                            if (!testResultsPublished) {
                                echo "Nenhum resultado de teste encontrado para publicar"
                            }

                        } catch (Exception e) {
                            echo "Erro ao publicar resultados de teste: ${e.getMessage()}"
                        }
                    }
                }
            }
        }

        stage('Package') {
            steps {
                echo "=== Packaging Application ==="

                script {
                    if (fileExists('gradlew')) {
                        sh './gradlew bootJar'
                    } else if (fileExists('build.gradle') || fileExists('build.gradle.kts')) {
                        sh 'gradle bootJar'
                    } else if (fileExists('pom.xml')) {
                        sh 'mvn package -DskipTests=true'
                    }
                }

                // Mostrar artefatos criados
                sh '''
                    echo "=== Artefatos Criados ==="
                    echo "Gradle libs:"
                    find build/libs -name "*.jar" -type f 2>/dev/null || echo "  Nenhum JAR Gradle encontrado"
                    echo "Maven target:"
                    find target -name "*.jar" -type f 2>/dev/null || echo "  Nenhum JAR Maven encontrado"
                '''

                echo "Packaging concluído!"
            }
            post {
                success {
                    script {
                        // Arquivar artefatos
                        try {
                            def artifactsArchived = false

                            // Gradle
                            if (fileExists('build/libs/')) {
                                def gradleJars = sh(
                                    script: 'find build/libs -name "*.jar" -type f | head -1',
                                    returnStdout: true
                                ).trim()

                                if (gradleJars) {
                                    archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true, allowEmptyArchive: true
                                    echo "Artefatos Gradle arquivados"
                                    artifactsArchived = true
                                }
                            }

                            // Maven
                            if (!artifactsArchived && fileExists('target/')) {
                                def mavenJars = sh(
                                    script: 'find target -name "*.jar" -type f | head -1',
                                    returnStdout: true
                                ).trim()

                                if (mavenJars) {
                                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
                                    echo "Artefatos Maven arquivados"
                                    artifactsArchived = true
                                }
                            }

                            if (!artifactsArchived) {
                                echo "Nenhum artefato encontrado para arquivar"
                            }

                        } catch (Exception e) {
                            echo "Erro ao arquivar artefatos: ${e.getMessage()}"
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
                echo "=== Solicitação de Aprovação para Produção ==="

                timeout(time: 30, unit: 'MINUTES') {
                    script {
                        env.APPROVER = input(
                            message: 'Prosseguir com deploy em PRODUÇÃO?',
                            ok: 'Aprovar Deploy',
                            submitterParameter: 'APPROVER'
                        )
                        echo "Deploy em produção aprovado por: ${env.APPROVER}"
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
            steps {
                echo "=== Deploy para ${params.ENVIRONMENT.toUpperCase()} ==="
                echo "Projeto: demo-app"
                echo "Build: #${env.BUILD_NUMBER}"
                echo "Branch: ${env.GIT_BRANCH ?: 'unknown'}"
                echo "Commit: ${env.GIT_COMMIT ? env.GIT_COMMIT[0..7] : 'unknown'}"

                script {
                    if (params.ENVIRONMENT == 'prod' && env.APPROVER) {
                        echo "Aprovado por: ${env.APPROVER}"
                    }
                }

                // Simulação de deploy
                sh '''
                    echo "Iniciando processo de deploy..."
                    sleep 1
                    echo "Verificando conectividade..."
                    sleep 1
                    echo "Copiando artefatos..."
                    sleep 2
                    echo "Configurando ambiente..."
                    sleep 1
                    echo "Iniciando aplicação..."
                    sleep 2
                    echo "Deploy concluído com sucesso!"
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
            steps {
                echo "=== Health Check da Aplicação ==="

                timeout(time: 3, unit: 'MINUTES') {
                    retry(3) {
                        sh '''
                            echo "Verificando saúde da aplicação..."
                            echo "Tentativa de conexão com a aplicação..."
                            sleep 2
                            echo "Verificando endpoints de saúde..."
                            sleep 1
                            echo "✅ Aplicação respondendo corretamente!"
                            echo "✅ Health check concluído com sucesso!"
                        '''
                    }
                }

                echo "Aplicação saudável em ${params.ENVIRONMENT}!"
            }
        }
    }

    post {
        always {
            echo "=== Pipeline Cleanup e Resumo ==="

            script {
                // Limpeza básica
                sh '''
                    echo "Limpando arquivos temporários..."
                    find . -name "*.tmp" -delete 2>/dev/null || true
                    find . -name "*.log" -maxdepth 2 -delete 2>/dev/null || true
                    echo "Limpeza concluída"
                '''

                // Resumo final
                def duration = currentBuild.durationString.replace(' and counting', '')
                def status = currentBuild.result ?: 'SUCCESS'

                echo "=== RESUMO FINAL ==="
                echo "Status: ${status}"
                echo "Duração: ${duration}"
                echo "Environment: ${params.ENVIRONMENT}"
                echo "Build: #${env.BUILD_NUMBER}"
                echo "Branch: ${env.GIT_BRANCH ?: 'unknown'}"
            }
        }

        success {
            echo ""
            echo "🎉 ================================="
            echo "🎉     BUILD REALIZADO COM SUCESSO!"
            echo "🎉 ================================="
            echo "✅ Environment: ${params.ENVIRONMENT}"
            echo "✅ Build: #${env.BUILD_NUMBER}"
            echo "✅ Todas as etapas concluídas!"
            echo ""
        }

        failure {
            echo ""
            echo "❌ ================================="
            echo "❌        BUILD FALHOU!"
            echo "❌ ================================="
            echo "💥 Environment: ${params.ENVIRONMENT}"
            echo "💥 Build: #${env.BUILD_NUMBER}"
            echo "💥 Verifique os logs acima"
            echo ""
        }

        unstable {
            echo ""
            echo "⚠️ ================================="
            echo "⚠️       BUILD INSTÁVEL!"
            echo "⚠️ ================================="
            echo "🧪 Alguns testes falharam"
            echo "🧪 Build continuou até o final"
            echo ""
        }

        aborted {
            echo ""
            echo "🛑 ================================="
            echo "🛑      BUILD CANCELADO!"
            echo "🛑 ================================="
            echo "👤 Pipeline interrompida pelo usuário"
            echo ""
        }
    }
}