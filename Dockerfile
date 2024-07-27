
# syntax=docker/dockerfile:1

ARG DOTNETVERSION=8.0
ARG TARGETARCH
ARG BUILDPLATFORM
ARG TARGETPLATFORM

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:$DOTNETVERSION-alpine AS build

COPY . /source
WORKDIR /source

# This is the project name, used to build the application.
# Change this to match the name of your project.
ARG PROJECT=dwt

# Build the application.
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM / $TARGETARCH"
RUN dotnet restore -a ${TARGETARCH} ${PROJECT}.csproj
RUN dotnet publish ${PROJECT}.csproj -a ${TARGETARCH} --no-restore -o /app

################################################################################

# If you need to enable globalization and time zones:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/enable-globalization.md

FROM mcr.microsoft.com/dotnet/aspnet:$DOTNETVERSION-alpine AS final
WORKDIR /app

COPY --from=build /app ./
COPY ./config ./config
COPY ./data ./data

# Create a non-privileged user that the app will run under.
# See https://docs.docker.com/go/dockerfile-user-best-practices/
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser

# Default port for dotnet application
EXPOSE 8080

# Change this to match the name of your project.
ENTRYPOINT ["dotnet", "dwt.dll"]
