FROM python:3.5
RUN apt-get update && apt-get install virtualenv --no-install-recommends -y
RUN rm -rf /var/lib/apt/lists/*
RUN virtualenv -p python3.5 --always-copy /src/
