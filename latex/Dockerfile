FROM alpine:latest

RUN apk add make texlive-full texlive-dev texlive-luatex texlive-xetex git

# Add a beamer theme
RUN cd /tmp && \
    git clone https://github.com/matze/mtheme && \
    cd mtheme && \
    make sty install 

WORKDIR /files
ENTRYPOINT ["sh", "-c", "exec /usr/bin/latexmk -pdf $1"]
