FROM busybox:latest

COPY vackup /usr/local/bin/vackup

RUN chmod +x /usr/local/bin/vackup

ENTRYPOINT ["vackup"]

CMD ["--help"]