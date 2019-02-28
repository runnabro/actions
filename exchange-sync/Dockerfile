FROM alpine

LABEL name="auto-pull-request"
LABEL version="1.0.0"
LABEL repository="http://github.com/repetitive/actions"
LABEL homepage="http://github.com/repetitive/actions"

LABEL maintainer="Anton Podviaznikov <anton@podviaznikov.com>"
LABEL com.github.actions.name="GitHub Action for automatically sync GitHub repo and Anypoint Exchnage"
LABEL com.github.actions.description="Sync assets from GitHub to Anypoint Exchange"
LABEL com.github.actions.icon="code"
LABEL com.github.actions.color="purple"
COPY LICENSE README.md /

RUN apk --no-cache add jq bash curl zip

COPY "entrypoint.sh" "/entrypoint.sh"
ENTRYPOINT ["/entrypoint.sh"]