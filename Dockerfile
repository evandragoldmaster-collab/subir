# Etapa de build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY CamCook.csproj ./
RUN dotnet restore

COPY . .
RUN dotnet publish -c Release -o /app

# Etapa final (runtime)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

COPY --from=build /app .

EXPOSE 80
EXPOSE 5024

ENTRYPOINT ["dotnet", "CamCook.dll"]
