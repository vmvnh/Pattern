FROM openjdk
ARG JAR_FILE=target/pattern-1.0-SNAPSHOT.jar
WORKDIR /java
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","app.jar"]