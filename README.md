# Automação de Provisionamento IIS

Projeto para automatizar o provisionamento de ambientes no IIS utilizando GitHub Actions, Self-hosted Runner e PowerShell.

A automação permite criar e configurar um novo ambiente IIS a partir de um formulário no GitHub Actions, reduzindo etapas manuais e padronizando a configuração dos ambientes.

---

## 1. Objetivo

O objetivo deste projeto é automatizar o processo de criação de ambientes IIS.

O processo manual normalmente envolve várias configurações, como:

- Criação do Site no IIS
- Criação do Application Pool
- Configuração da versão do .NET CLR
- Configuração do Managed Pipeline Mode
- Configuração da Identity do Application Pool
- Criação da pasta física
- Configuração do Hostname
- Configuração dos Bindings
- Configuração de HTTP
- Configuração de HTTPS
- Associação do certificado
- Inicialização do Site e Application Pool

Com a automação, essas informações são fornecidas através de um formulário no GitHub Actions e utilizadas pelo script PowerShell.

---

## 2. Tecnologias utilizadas

- GitHub
- GitHub Actions
- GitHub Actions Self-hosted Runner
- PowerShell
- IIS (Internet Information Services)
- Microsoft.Web.Administration
- WebAdministration

---

## 3. Arquitetura

O fluxo da automação funciona da seguinte forma:

```text
GitHub
   |
   v
GitHub Actions
   |
   v
Self-hosted Runner
   |
   v
PowerShell
   |
   v
Servidor Windows
   |
   v
IIS
