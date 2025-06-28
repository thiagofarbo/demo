// Exemplo de como ficaria no seu Jenkinsfile após configurar:

pipeline {
    agent any

    tools {
        maven 'maven-3.6.3'      // Nome que você deu na configuração
        jdk 'OpenJDK-21'       // Nome que você deu na configuração
    }

    stages {
        stage('Build') {
            steps {
                // Agora Maven e Java estão disponíveis
                sh 'java -version'
                sh 'mvn -version'
                sh 'mvn clean compile'
            }
        }
    }
}

// OU se você não configurou tools, pode usar diretamente:

pipeline {
    agent any

    environment {
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk'
        MAVEN_HOME = '/usr/share/maven'
        PATH = "${MAVEN_HOME}/bin:${JAVA_HOME}/bin:${env.PATH}"
    }

    stages {
        stage('Build') {
            steps {
                sh 'java -version'
                sh 'mvn clean compile'
            }
        }
    }
}