FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

COPY rideconnect.jar /app/app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]