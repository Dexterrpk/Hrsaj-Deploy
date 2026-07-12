# HRSAJ Deploy

Automação idempotente de pós-formatação para entregar estações Linux no padrão HRSAJ.
O foco principal é Linux Mint XFCE, mantendo rotinas seguras para outros desktops da família Debian/Ubuntu.

## Instalação pelo Git

```bash
git clone https://github.com/Dexterrpk/Hrsaj-Deploy.git
cd Hrsaj-Deploy
cp config.env.example config.env
nano config.env
bash start.sh
```

Para atualizar uma instalação existente:

```bash
cd ~/Hrsaj-Deploy
git pull --ff-only
bash start.sh
```

Também existe um instalador auxiliar:

```bash
bash install.sh
```

## Proteções obrigatórias

- não altera favoritos, preferências, sessões, extensões ou perfil do Chrome;
- não encerra o Chrome nem remove arquivos `Singleton*`;
- não altera a versão nem os arquivos de configuração de um Weasis já instalado;
- nunca escreve em `~/.weasis`;
- não executa `chown -R` ou `chmod -R` em pastas pessoais;
- não instala automaticamente impressoras DNS-SD, IPP, SMB ou publicadas por outras máquinas;
- não duplica impressoras locais em uma segunda execução;
- verifica o estado real antes de cada mudança e registra o resultado em `/var/lib/hrsaj-deploy/state.tsv`.

## Pacotes homologados

Arquivos `.deb` não ficam versionados no Git. Coloque os pacotes homologados, quando necessários, em:

```text
assets/weasis.deb
assets/anydesk.deb
assets/chrome.deb
```

O Weasis existente é sempre preservado. Em uma máquina recém-formatada, `assets/weasis.deb` é o método recomendado para garantir a versão homologada.

## Configuração local

`config.env` contém dados locais e não é enviado ao GitHub. Use `config.env.example` como modelo.
Nunca publique senhas reais no repositório.

## Execução repetida

O deploy pode ser executado novamente. Os módulos validam usuários, pacotes, atalhos, serviços e filas antes de agir. A auditoria informa o que já estava correto, o que foi alterado e o que exige revisão manual.
