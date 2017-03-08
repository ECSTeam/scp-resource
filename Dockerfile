FROM alpine:latest

ADD scripts/ /opt/resource/

RUN apk add --update --no-cache \
	bash \
	jq \
	openssh-client
