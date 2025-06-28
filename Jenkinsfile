#!/bin/bash
echo "Starting Java Maven build process..."

# Limpar e baixar dependências
mvn clean compile

# Executar testes
mvn test

# Gerar JAR/WAR
mvn package

echo "Build completed successfully!"
echo "Generated files:"
ls -la target/*.jar"