FROM openjdk
ARG JAR_FILE=target/spring-boot-docker.jar
WORKDIR /java
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","app.jar"]
