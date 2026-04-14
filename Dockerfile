FROM tomcat:10-jdk17

COPY sample-webapp.war /usr/local/tomcat/webapps/studentapp.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
