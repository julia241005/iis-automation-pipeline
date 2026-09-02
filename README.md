Automação de Provisionamento IIS
Projeto para automatizar o provisionamento de ambientes no IIS utilizando GitHub Actions, Self-hosted Runner e PowerShell.

A automação permite criar e configurar um novo ambiente IIS a partir de um formulário no GitHub Actions, reduzindo etapas manuais e padronizando a configuração dos ambientes.

1. Objetivo

O objetivo deste projeto é automatizar o processo de criação e configuração de ambientes IIS.

O processo manual normalmente envolve várias configurações, como:

Criação do Site no IIS
Criação do Application Pool
Configuração da versão do .NET CLR
Configuração do Managed Pipeline Mode
Configuração da Identity do Application Pool
Criação da pasta física
Configuração do Hostname
Configuração dos Bindings
Configuração de HTTP
Configuração de HTTPS
Associação do certificado
Inicialização do Site e Application Pool

Com a automação, essas informações são fornecidas através de um formulário no GitHub Actions e utilizadas pelos scripts PowerShell.

2. Tecnologias utilizadas
GitHub
GitHub Actions
GitHub Actions Self-hosted Runner
PowerShell
IIS (Internet Information Services)
Microsoft.Web.Administration
WebAdministration
3. Arquitetura

O fluxo da automação funciona da seguinte forma:

GitHub
↓
GitHub Actions
↓
Self-hosted Runner
↓
PowerShell
↓
Servidor Windows
↓
IIS

O workflow é iniciado manualmente pelo GitHub Actions.

O Self-hosted Runner recebe a execução e executa os scripts PowerShell diretamente no servidor configurado.

Os scripts realizam as configurações necessárias no IIS.

4. Estrutura do projeto

iis-automation-pipeline/

├── .github/
│ └── workflows/
│ └── pipeline.yml
│
├── scripts/
│ ├── Provision-IIS.ps1
│ └── Deploy-App.ps1
│
└── README.md

pipeline.yml

Arquivo responsável pela configuração do workflow do GitHub Actions.

Ele disponibiliza o formulário utilizado para informar os parâmetros do ambiente e executa o script de provisionamento.

Provision-IIS.ps1

Script responsável pelo provisionamento do IIS.

Entre as configurações realizadas estão:

criação da pasta física;
criação do Application Pool;
configuração do .NET CLR;
configuração do Pipeline Mode;
configuração da Identity;
criação do Site;
configuração do caminho físico;
configuração dos Bindings;
configuração de HTTP/HTTPS, conforme a implementação do script.
Deploy-App.ps1

Script destinado ao processo de deploy da aplicação.

O script possui etapas relacionadas a:

backup preventivo;
parada do Application Pool;
cópia dos arquivos;
inicialização do Application Pool.
5. Pré-requisitos

Para utilizar a automação, o ambiente deve possuir:

Servidor Windows;
IIS instalado;
PowerShell;
Self-hosted Runner configurado;
permissões necessárias para alterar o IIS;
acesso ao repositório;
conta de serviço autorizada, quando utilizada;
certificado instalado no servidor, quando HTTPS for utilizado;
DNS/Hostname configurado, quando necessário.
6. Como executar a pipeline

A pipeline é executada manualmente através do GitHub Actions.

Passo 1

Acesse o repositório do projeto:

testes-iis/iis-automation-pipeline

Passo 2

No menu do repositório, acesse:

Actions

Passo 3

Selecione o workflow:

CI/CD Pipeline de Infraestrutura - IIS

Passo 4

Clique em:

Run workflow

Passo 5

Selecione a branch que contém a versão desejada do workflow.

Normalmente:

main

Passo 6

Preencha todos os campos apresentados pelo formulário.

Passo 7

Clique novamente em:

Run workflow

A execução será encaminhada para o Self-hosted Runner.

7. Parâmetros do formulário

O formulário do workflow possui os seguintes parâmetros:

Nome do Site no IIS
Nome do App Pool
Caminho Físico
Versão do .NET CLR
Modo do Pipeline
Identidade do App Pool
Hostname
Protocolo
IP do Binding
Nome do certificado HTTPS

Os valores devem ser definidos de acordo com o ambiente que será criado.

8. Nome do Site no IIS

Esse campo define o nome do Site que será criado no IIS.

Exemplo:

Remaza (Adesao)

Para um ambiente de teste, deve ser utilizado um nome que não exista no servidor.

Exemplo:

Remaza (Teste2)

Antes de executar a pipeline, verifique se o nome já não está sendo utilizado.

9. Nome do App Pool

Esse campo define o nome do Application Pool.

O nome deve seguir o padrão de nomenclatura utilizado pela infraestrutura.

Exemplo:

App_Remaza_Adesao

Para um ambiente de teste:

App_Remaza_Teste2

A nomenclatura do Application Pool deve ser diferente do nome do Site quando esse for o padrão adotado pela empresa.

Exemplo:

Site: Remaza (Adesao)

Application Pool: App_Remaza_Adesao

10. Como descobrir o nome correto do App Pool

Para utilizar um ambiente existente como referência:

Abra o IIS.
Acesse Application Pools.
Localize o Application Pool da aplicação.
Verifique o padrão de nomenclatura utilizado.

O novo Application Pool deve seguir o padrão definido para aquele tipo de aplicação.

11. Caminho Físico

O Caminho Físico define a pasta onde os arquivos da aplicação serão armazenados.

Exemplo:

D:\Remaza-Adesao

Para um ambiente de teste:

D:\Remaza-Teste2

Cada ambiente deve possuir seu próprio diretório para evitar conflito entre aplicações.

12. Como descobrir o Caminho Físico

No IIS:

Sites → Site de referência → Basic Settings...

Verifique o campo:

Physical path

Esse caminho serve como referência para entender o padrão utilizado no servidor.

Para o novo ambiente, deve ser utilizado um caminho próprio.

13. Versão do .NET CLR

O formulário possui as seguintes opções:

v4.0
v2.0
No Managed Code

A opção correta depende da aplicação.

Para consultar a configuração de um ambiente existente:

IIS → Application Pools → App Pool → Advanced Settings

Verifique:

.NET CLR Version

Utilize a configuração do ambiente de referência.

Não escolha a versão apenas pelo nome da aplicação.

14. Modo do Pipeline

As opções disponíveis são:

Integrated
Classic

Para descobrir o valor correto, consulte o Application Pool de referência.

No IIS:

Application Pools → App Pool → Advanced Settings

Verifique:

Managed Pipeline Mode

O novo ambiente deve seguir a configuração utilizada pela aplicação.

15. Identidade do App Pool

A Identity define qual conta será utilizada pelo Application Pool para executar a aplicação.

As opções disponíveis no formulário são:

REMAZAWEB\WebTrusted
ApplicationPoolIdentity

A opção correta deve ser definida de acordo com a aplicação e com o padrão da infraestrutura.

Exemplo:

REMAZAWEB\WebTrusted

Essa conta é uma conta de serviço.

Segurança

Credenciais de contas de serviço são informações sensíveis.

Nunca coloque senhas diretamente:

no código;
no arquivo .ps1;
no pipeline.yml;
no README;
em commits;
em logs.

Quando a automação precisar de uma credencial, ela deve ser armazenada utilizando o mecanismo seguro definido pela empresa e pelo GitHub Actions.

16. Hostname

O Hostname é o endereço utilizado para acessar a aplicação.

Exemplo:

devadesao.remaza.com.br

Antes de utilizar um hostname, confirme:

hostname correto;
ambiente correto;
DNS configurado;
se o hostname já está sendo utilizado por outro Site.

Não reutilize o hostname de outro ambiente.

17. Como descobrir o Hostname

No IIS:

Sites → Site de referência → Bindings...

Na tela de Bindings, consulte:

Host name

O hostname do novo ambiente deve ser o endereço definido para ele.

O hostname de um ambiente existente deve ser utilizado apenas como referência.

18. Protocolo

O formulário possui:

HTTP
HTTPS
HTTP + HTTPS
HTTP

Configura o Binding HTTP.

Normalmente utiliza a porta 80.

Quando o protocolo escolhido for somente HTTP, o certificado HTTPS não será utilizado.

HTTPS

Configura o Binding HTTPS.

Normalmente utiliza a porta 443.

Nesse caso, o certificado informado deverá estar disponível no servidor.

HTTP + HTTPS

Configura os dois protocolos.

Nesse cenário, o Site terá os bindings HTTP e HTTPS.

19. IP do Binding

Define o endereço IP utilizado pelo Binding do IIS.

Exemplo:

172.19.10.10

Esse valor é apenas um exemplo.

Antes de executar a pipeline, confirme qual IP deve ser utilizado no servidor de destino.

Não utilize um IP sem confirmação.

20. Como descobrir o IP

O IP deve ser confirmado no servidor de destino e de acordo com o padrão utilizado pela infraestrutura.

Também pode ser utilizado um Site existente como referência.

No IIS:

Sites → Site de referência → Bindings...

Verifique:

IP Address

O novo ambiente deve utilizar o IP definido para ele.

21. Nome do certificado HTTPS

Esse campo é utilizado para a configuração de HTTPS.

Exemplo:

*.remaza.com.br

O certificado deve estar instalado no servidor onde o IIS está sendo configurado.

Quando a infraestrutura já mantém os certificados instalados no servidor, a pipeline não precisa realizar o download do certificado.

Nesse cenário, o script deve localizar o certificado existente e associá-lo ao Binding HTTPS.

22. Como verificar o certificado

No servidor Windows, os certificados podem ser consultados através de:

certlm.msc

Depois acesse:

Certificados → Computador Local → Pessoal → Certificados

Verifique se o certificado necessário está instalado.

Exemplo:

*.remaza.com.br

Para utilização pelo IIS, o certificado precisa estar disponível corretamente e possuir a chave privada necessária.

23. Como descobrir os parâmetros antes de executar

Os parâmetros não devem ser preenchidos por tentativa.

A melhor referência é um ambiente existente da mesma aplicação ou de uma aplicação equivalente.

Site

IIS → Sites → Site de referência

Verifique:

nome;
Physical Path;
Application Pool;
Bindings.
Application Pool

IIS → Application Pools → App Pool de referência

Em Advanced Settings, verifique:

.NET CLR Version;
Managed Pipeline Mode;
Identity.
Bindings

Em:

Site → Bindings...

Verifique:

protocolo;
IP;
porta;
hostname;
certificado;
SNI, quando utilizado.
Certificado

No servidor:

certlm.msc

Verifique se o certificado utilizado pelo ambiente está instalado.

24. Exemplo de preenchimento

Exemplo para um ambiente de teste:

Nome do Site:

Remaza (Teste2)

Nome do App Pool:

App_Remaza_Teste2

Caminho Físico:

D:\Remaza-Teste2

Versão do .NET CLR:

v4.0

Modo do Pipeline:

Integrated

Identidade do App Pool:

REMAZAWEB\WebTrusted

Hostname:

hostname definido pela infraestrutura

Protocolo:

HTTP

IP do Binding:

IP definido para o servidor

Nome do certificado HTTPS:

*.remaza.com.br

O Hostname e o IP devem ser confirmados antes da execução.

25. Exemplo de configuração HTTPS

Quando o ambiente utilizar HTTPS, o formulário deverá ser preenchido com o protocolo correspondente.

Exemplo:

Protocolo:

HTTPS

ou:

HTTP + HTTPS

Exemplo de Binding HTTPS:

Type: HTTPS

IP: 172.19.10.10

Port: 443

Hostname: devadesao.remaza.com.br

Certificate: *.remaza.com.br

Quando o padrão da infraestrutura utilizar SNI, essa configuração também deverá ser considerada no provisionamento.

26. Validação após a execução

Depois que a pipeline terminar com sucesso, o ambiente deve ser validado diretamente no IIS.

Site

Verifique:

IIS → Sites → Novo Site

Confirme:

nome;
status;
caminho físico;
Application Pool.
Application Pool

Verifique:

IIS → Application Pools → Novo App Pool

Confirme:

nome;
status;
.NET CLR;
Managed Pipeline Mode;
Identity.
Bindings

No Site:

Bindings...

Confirme:

protocolo;
IP;
porta;
hostname;
certificado, quando HTTPS;
SNI, quando utilizado.
27. Resultado esperado

Depois do provisionamento, deve existir um Site e um Application Pool correspondentes ao novo ambiente.

Exemplo:

Sites → Remaza (Teste2)

Application Pools → App_Remaza_Teste2

O Site deve estar associado ao Application Pool correto:

Remaza (Teste2) → App_Remaza_Teste2

28. Checklist de validação

Após a execução, confirme:

 Site criado
 Application Pool criado
 Nome do Application Pool segue o padrão
 Site associado ao Application Pool correto
 Pasta física criada
 Caminho físico correto
 .NET CLR correto
 Managed Pipeline Mode correto
 Identity correta
 Hostname correto
 IP correto
 Binding HTTP correto
 Binding HTTPS correto, quando necessário
 Certificado associado, quando HTTPS
 Site iniciado
 Application Pool iniciado
29. Troubleshooting
Pipeline ficou Enqueued

Se o workflow ficar aguardando execução, verifique o Self-hosted Runner.

O Runner precisa estar Online e disponível para executar o job.

Erro ao configurar a Identity

Se aparecer erro relacionado à conta:

REMAZAWEB\WebTrusted

verifique com a equipe responsável pela infraestrutura como essa conta é administrada e como a credencial deve ser fornecida ao IIS.

Não coloque a senha diretamente no código.

Application Pool criado com nome incorreto

Verifique o campo Nome do App Pool.

Ele deve seguir o padrão utilizado pela infraestrutura.

Exemplo:

App_Remaza_Adesao

Evite utilizar o mesmo nome do Site quando o padrão da infraestrutura exigir a utilização do prefixo App_.

Certificado não encontrado

Verifique:

Se o certificado está instalado no servidor.
Se o nome informado está correto.
Se o certificado possui chave privada.
Se o certificado está no armazenamento correto.
Se o hostname corresponde ao certificado.
Site criado, mas não abre

Verifique:

Site
Application Pool
Physical Path
Binding
Hostname
DNS
Porta
Firewall
Certificado

Também confirme se o Site e o Application Pool estão iniciados.

30. Segurança

Nunca armazenar no repositório:

Senhas
Tokens
Chaves privadas
Certificados .pfx
Credenciais de contas de serviço

Também não registrar informações sensíveis nos logs da pipeline.

As credenciais devem utilizar os mecanismos seguros definidos pela empresa.

31. Boas práticas
Testar primeiro em ambiente de desenvolvimento.
Não utilizar nomes de Sites existentes.
Não reutilizar Hostnames.
Seguir o padrão de nomenclatura dos Application Pools.
Consultar um ambiente existente antes de preencher os parâmetros.
Não armazenar credenciais no código.
Validar o resultado no IIS após a execução.
Fazer alterações pequenas e testar cada mudança.
Manter a documentação atualizada.
Registrar alterações importantes no Git.
32. Fluxo completo
Identificar a aplicação.
Consultar um ambiente de referência.
Identificar os parâmetros.
Abrir o GitHub Actions.
Selecionar o workflow.
Clicar em Run workflow.
Preencher os parâmetros.
Executar a pipeline.
O Self-hosted Runner executa o PowerShell.
O IIS é provisionado.
Validar Site, App Pool e Bindings.
Ambiente provisionado.
33. Manutenção do projeto

As alterações nos scripts devem ser realizadas no repositório e versionadas através do Git.

Fluxo recomendado:

Alterar código
↓
Testar
↓
git status
↓
git add
↓
git commit
↓
git push
↓
GitHub Actions
↓
Validar no servidor

Antes de executar alterações em ambientes reais, recomenda-se realizar testes em ambiente de desenvolvimento.

34. Responsabilidade do operador

Antes de executar uma nova criação de ambiente, confirme:

 Nome do Site
 Nome do Application Pool
 Caminho físico
 Versão do .NET
 Managed Pipeline Mode
 Identity
 Hostname
 Protocolo
 IP
 Certificado, quando HTTPS
 DNS, quando necessário
 Permissões necessárias

Após a execução:

 Site criado
 Application Pool criado
 Application Pool correto associado ao Site
 Pasta criada
 Binding correto
 HTTPS configurado, quando necessário
 Certificado associado, quando necessário
 Site iniciado
 Application Pool iniciado
35. Objetivo final

A automação busca tornar o processo de criação de ambientes IIS mais:

padronizado;
automatizado;
rápido;
rastreável;
seguro.

O processo passa a ser:

Parâmetros
↓
Pipeline
↓
Script PowerShell
↓
IIS
↓
Ambiente provisionado

O operador fornece os parâmetros, a pipeline executa os scripts e o ambiente é configurado no servidor.
