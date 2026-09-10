Automação de Provisionamento IIS

Projeto para automatizar o provisionamento de ambientes no IIS utilizando GitHub Actions, Self-hosted Runner e PowerShell.

A automação permite criar e configurar um novo ambiente IIS a partir de um formulário no GitHub Actions, reduzindo etapas manuais e padronizando a configuração dos ambientes com suporte a re-execuções seguras (idempotência).

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

Com a automação, essas informações são fornecidas através de um formulário no GitHub Actions e utilizadas pelos scripts PowerShell atualizados para a versão V2.

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
GitHub → GitHub Actions → Self-hosted Runner → PowerShell → Servidor Windows → IIS

O workflow é iniciado manualmente pelo GitHub Actions.

O Self-hosted Runner recebe a execução e executa os scripts PowerShell diretamente no servidor configurado.

Os scripts realizam as configurações necessárias no IIS de forma idempotente.

4. Estrutura do projeto
Plaintext
iis-automation-pipeline/
├── .github/
│   └── workflows/
│       └── pipeline.yml
├── scripts/
│   ├── Provision-IIS-V2.ps1
│   └── Deploy-App.ps1
└── README.md
pipeline.yml
Arquivo responsável pela configuração do workflow do GitHub Actions. Ele disponibiliza o formulário utilizado para informar os parâmetros do ambiente e executa o script de provisionamento.

Provision-IIS-V2.ps1
Script avançado responsável pelo provisionamento do IIS com lógica idempotente. Ele valida a existência prévia de pastas, Application Pools e Sites para reutilizá-los e atualizá-los de forma segura, prevenindo erros de duplicidade. Entre as configurações realizadas estão:

verificação e criação da pasta física;

validação e criação do Application Pool;

configuração do .NET CLR;

configuração do Pipeline Mode;

configuração da Identity;

criação e vínculo do Site;

configuração dos Bindings com suporte a SNI;

busca inteligente de certificados HTTPS via -match com validação de chave privada.

Deploy-App.ps1
Script destinado ao processo de deploy da aplicação, contendo etapas de backup preventivo, parada do Application Pool, cópia dos arquivos e inicialização do Application Pool.

5. Pré-requisitos
Para utilizar a automação, o ambiente deve possuir:

Servidor Windows;

IIS instalado;

PowerShell;

Self-hosted Runner configurado;

Permissões necessárias para alterar o IIS;

Acesso ao repositório;

Conta de serviço autorizada, quando utilizada;

Certificado instalado no servidor, quando HTTPS for utilizado;

DNS/Hostname configurado, quando necessário.

6. Como executar a pipeline
A pipeline é executada manualmente através do GitHub Actions.

Passo 1: Acesse o repositório do projeto testes-iis/iis-automation-pipeline.

Passo 2: No menu do repositório, acesse Actions.

Passo 3: Selecione o workflow CI/CD Pipeline de Infraestrutura - IIS.

Passo 4: Clique em Run workflow.

Passo 5: Selecione a branch desejada (normalmente main).

Passo 6: Preencha todos os campos apresentados pelo formulário.

Passo 7: Clique novamente em Run workflow. A execução será encaminhada para o Self-hosted Runner.

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
Esse campo define o nome do Site que será criado no IIS (Exemplo: Remaza (Adesao)). Para um ambiente de teste, deve ser utilizado um nome que não exista no servidor (Exemplo: Remaza (Teste2)). Antes de executar a pipeline, verifique se o nome já não está sendo utilizado.

9. Nome do App Pool
Define o nome do Application Pool seguindo o padrão de nomenclatura da infraestrutura (Exemplo: App_Remaza_Adesao ou App_Remaza_Teste2).

10. Como descobrir o nome correto do App Pool
Para utilizar um ambiente existente como referência: abra o IIS, acesse Application Pools, localize o Application Pool da aplicação e verifique o padrão de nomenclatura utilizado.

11. Caminho Físico
Define a pasta onde os arquivos da aplicação serão armazenados (Exemplo: D:\Remaza-Adesao ou D:\Remaza-Teste2). Cada ambiente deve possuir seu próprio diretório para evitar conflito entre aplicações.

12. Como descobrir o Caminho Físico
No IIS, navegue até Sites → Site de referência → Basic Settings... e verifique o campo Physical path.

13. Versão do .NET CLR
As opções disponíveis são v4.0, v2.0 ou No Managed Code. Consulte o Application Pool de referência em Advanced Settings para confirmar a versão correta.

14. Modo do Pipeline
As opções disponíveis são Integrated ou Classic. Consulte o Application Pool de referência no IIS para alinhar com o padrão da aplicação.

15. Identidade do App Pool
Define qual conta será utilizada pelo Application Pool para executar a aplicação (Exemplo: REMAZAWEB\WebTrusted ou ApplicationPoolIdentity). Credenciais de contas de serviço são informações sensíveis e nunca devem ser expostas em código, arquivos de configuração ou logs.

16. Hostname
O Hostname é o endereço utilizado para acessar a aplicação (Exemplo: devadesao.remaza.com.br). Confirme se o DNS está configurado e se o endereço não está em uso por outro site.

17. Como descobrir o Hostname
No IIS, acesse Sites → Site de referência → Bindings... e consulte o campo Host name.

18. Protocolo
O formulário suporta:

HTTP: Configura o Binding HTTP (geralmente porta 80).

HTTPS: Configura o Binding HTTPS (geralmente porta 443), exigindo certificado disponível no servidor.

HTTP + HTTPS: Configura ambos os protocolos simultaneamente.

19. IP do Binding
Define o endereço IP utilizado pelo Binding do IIS (Exemplo: 172.19.10.10). Confirme o IP adequado junto à infraestrutura de redes antes de executar.

20. Como descobrir o IP
Consulte o IP no servidor de destino ou utilize um Site existente como referência acessando Sites → Site de referência → Bindings... e verificando o campo IP Address.

21. Nome do certificado HTTPS
Utilizado para a configuração de HTTPS (Exemplo: *.remaza.com.br). O script V2 realiza uma busca flexível por correspondência (-match) e valida obrigatoriamente se o certificado localizado no repositório do Windows (Cert:\LocalMachine\My) possui chave privada ativa e suporte a SNI configurado.

22. Como verificar o certificado
No servidor Windows, abra certlm.msc e navegue até Certificados → Computador Local → Pessoal → Certificados para confirmar a instalação e presença da chave privada.

23. Como descobrir os parâmetros antes de executar
Consulte sempre um ambiente existente da mesma aplicação para mapear com precisão o nome, Physical Path, Application Pool, Bindings, .NET CLR Version, Managed Pipeline Mode e Identity.

24. Exemplo de preenchimento
Exemplo para um ambiente de teste:

Nome do Site: Remaza (Teste2)

Nome do App Pool: App_Remaza_Teste2

Caminho Físico: D:\Remaza-Teste2

Versão do .NET CLR: v4.0

Modo do Pipeline: Integrated

Identidade do App Pool: REMAZAWEB\WebTrusted

Hostname: devadesao.remaza.com.br

Protocolo: HTTP

IP do Binding: IP definido para o servidor

25. Exemplo de configuração HTTPS
Quando o ambiente utilizar HTTPS, certifique-se de preencher o protocolo correspondente. O script V2 cuidará do vínculo seguro e do suporte a SNI (Server Name Indication) conforme o padrão da infraestrutura.

26. Validação após a execução
Após a conclusão da pipeline, valide diretamente no IIS:

Site: Verifique se o novo site está criado, iniciado e associado ao caminho físico e Application Pool corretos.

Application Pool: Confirme o status, versão do .NET, modo de pipeline e identidade.

Bindings: Confira protocolo, IP, porta, hostname e certificado HTTPS/SNI.

27. Resultado esperado
Deve existir um Site e um Application Pool devidamente vinculados e ativos no IIS (Exemplo: Site Remaza (Teste2) associado ao Application Pool App_Remaza_Teste2).

28. Checklist de validação
[ ] Site criado

[ ] Application Pool criado

[ ] Nomenclatura correta do App Pool

[ ] Site associado ao App Pool correto

[ ] Pasta física criada e estruturada

[ ] Parâmetros .NET CLR e Pipeline corretos

[ ] Identidade e Hostname configurados

[ ] Bindings HTTP/HTTPS validados

[ ] Certificado associado com chave privada

[ ] Site e Application Pool iniciados

29. Troubleshooting
Pipeline Enqueued: Verifique se o Self-hosted Runner está Online e disponível.

Erro ao configurar a Identity: Valide a conta de serviço junto à equipe de infraestrutura sem expor senhas no código.

Certificado não encontrado: Confirme a instalação em certlm.msc, a presença da chave privada e a exatidão do nome informado.

Re-execuções e Idempotência: Graças à lógica V2, caso o recurso já exista em DEV/HML, o script reutiliza o objeto e atualiza as configurações sem falhas abruptas.

30. Segurança
Nunca armazene no repositório senhas, tokens, chaves privadas, arquivos .pfx ou credenciais de contas de serviço. Utilize os mecanismos seguros fornecidos pelo GitHub Actions.

31. Boas práticas
Testar primeiro em ambiente de desenvolvimento.

Utilizar a idempotência da V2 para re-execuções seguras.

Consultar um ambiente existente antes de preencher os parâmetros.

Não armazenar credenciais no código-fonte.

Validar o resultado no IIS após cada execução.

32. Fluxo completo
Identificar parâmetros de referência → Acessar GitHub Actions → Preencher formulário → Executar pipeline → Script PowerShell V2 (Idempotente) → Provisionamento no IIS → Validação final.

33. Manutenção do projeto
Alterações nos scripts devem ser versionadas via Git (git add, git commit, git push), testadas em ambiente de desenvolvimento e promovidas gradualmente para os demais ambientes.

34. Responsabilidade do operador
O operador deve garantir a veracidade de todos os parâmetros preenchidos no formulário (nomes, IPs, caminhos e certificados) antes de disparar o workflow para os servidores de homologação ou produção.

35. Objetivo final
Tornar a criação de ambientes IIS um processo padronizado, automatizado, rápido, rastreável e seguro por meio de infraestrutura como código com PowerShell e GitHub Actions.
