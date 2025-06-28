# Etapa 1: Build da aplicação com Gradle e GraalVM
FROM ghcr.io/graalvm/jdk:22.3.2 AS build

# Instala dependências necessárias para Gradle e native-image
RUN microdnf update -y && \
    microdnf install -y findutils gcc glibc-devel zlib-devel libstdc++-devel gcc-c++ && \
    microdnf clean all && \
    gu install native-image

# Define o diretório de trabalho
WORKDIR /usr/src/app

# Copia os arquivos de configuração do Gradle
COPY build.gradle settings.gradle gradlew ./
COPY gradle ./gradle

# Garante permissões de execução para o Gradle Wrapper
RUN chmod +x ./gradlew

# Baixa as dependências do Gradle (cache para builds mais rápidos)
RUN ./gradlew --no-daemon dependencies

# Copia o código-fonte da aplicação
COPY src ./src

# Constrói a aplicação e gera a imagem nativa com GraalVM
RUN ./gradlew --no-daemon nativeCompile

# Etapa 2: Criação da imagem final
FROM debian:bookworm-slim

# Define o diretório de trabalho
WORKDIR /app

# Copia o executável nativo gerado na etapa de build
COPY --from=build /usr/src/app/build/native/nativeCompile/demo /app/demo

# Expõe a porta padrão (ajuste conforme necessário)
EXPOSE 8080

# Comando para executar a aplicação
CMD ["/app/demo"]