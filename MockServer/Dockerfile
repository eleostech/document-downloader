FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app

COPY MockServer/MockServer.sln ./
COPY MockServer/MockServer/MockServer.csproj ./MockServer/
RUN dotnet restore

COPY MockServer/MockServer/ ./MockServer/
WORKDIR /app/MockServer
RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY --from=build /app/MockServer/out .

EXPOSE 80
ENTRYPOINT ["dotnet", "MockServer.dll"]
