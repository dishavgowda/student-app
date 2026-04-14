FROM tomcat:10-jdk17

RUN rm -rf /usr/local/tomcat/webapps/*
COPY target/*.war /usr/local/tomcat/webapps/studentapp.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
