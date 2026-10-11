# CS.Coder Project Hub

[English](README.md) | **Português (Brasil)**

O CS.Coder Project Hub é uma extensão para a Welcome Page do Delphi 11, 12 e 13. Ele
acrescenta um painel onde você guarda atalhos para os seus projetos, organizados em
categorias e grupos que você mesmo define, com ícones, pesquisa e ordenação manual.

O Delphi já oferece acesso prático aos projetos recentes. O Hub não substitui esse
recurso. Ele o complementa com uma camada adicional de organização: uma coleção arrumada
pelos seus critérios (por cliente, por sistema, por área de trabalho), que só muda quando
você muda.

Gratuito e de código aberto sob a [licença MIT](LICENSE), da
[CS.Coder](https://www.cscoder.com.br).

![CS.Coder Project Hub na Welcome Page do Delphi, ao lado do painel Open Recent](docs/images/welcome-page.png)

*O Hub, à esquerda, ao lado do painel Open Recent do próprio Delphi. Os nomes de projetos
e as pastas das capturas são exemplos.*

## Visão geral

- **Organizado do seu jeito.** Categorias contêm grupos, grupos contêm atalhos de projetos.
- **Reconhecível de relance.** Um ícone opcional para cada categoria e grupo.
- **Fácil de achar.** Pesquisa pelo nome do projeto ou pelo caminho.
- **Na sua ordem.** Arraste e solte, ou ordene um grupo por nome.
- **Portátil.** Exporte toda a organização para um arquivo JSON e importe em outro lugar.
- **Parte da IDE.** Fica na Welcome Page e acompanha os temas claro e escuro.
- **No seu idioma.** Português, inglês, espanhol, alemão e francês, escolhido
  automaticamente pelo idioma do Windows.
- **Nunca começa vazio.** Na primeira abertura ele já traz os seus favoritos e os projetos
  recentes do Delphi, prontos para você organizar.
- **Seguro para o seu trabalho.** O Hub guarda apenas atalhos. Ele nunca apaga nem move
  arquivos de projeto.

## Instalação

### Versões compatíveis

| Delphi | IDE de 32 bits | IDE de 64 bits |
|---|---|---|
| 11 Alexandria | Sim | Não se aplica |
| 12 Athens | Sim | Sim |
| 13 Florence | Sim | Sim |

Os pacotes são compilados com o Delphi 11.3, 12.3 e 13.1. Um único download atende a
todas as versões.

### Passo a passo

1. **Baixe.** Abra a [página de Releases](https://github.com/cscoder69/delphi-project-hub/releases),
   escolha a versão mais recente e, em **Assets**, baixe o arquivo chamado
   `CSCoderHubProjetos-<versão>.zip`. Não escolha "Source code": esse não traz o
   instalador.
2. **Extraia.** Descompacte o arquivo inteiro em uma pasta à sua escolha. O `Install.bat`
   precisa dos outros arquivos que vêm com ele.
3. **Feche o Delphi.** Feche todas as janelas do Delphi. O instalador para com um aviso se
   o Delphi estiver aberto, porque a IDE regrava a lista de pacotes ao fechar.
4. **Execute o `Install.bat`.** Dê um duplo clique. Ele não pede administrador e instala
   para o usuário atual do Windows, em todos os Delphi compatíveis que encontrar. Mostra
   uma linha por Delphi, por exemplo `[OK] Delphi 12 (32-bit, 64-bit)`.
5. **Abra o Delphi** e vá para a Welcome Page.

### Como localizar o painel

Na IDE, o painel aparece com o nome original, **"CS.Coder - Hub de Projetos"**.

Se ele não estiver na Welcome Page depois da instalação:

1. Clique em **Edit Layout**, no canto inferior esquerdo da Welcome Page. Abre-se o
   Welcome Page Layout Editor.
2. Localize "CS.Coder - Hub de Projetos" em **Available Plugins** e posicione no layout,
   onde preferir.
3. Clique em **Save**.

![Welcome Page Layout Editor com o Hub posicionado no layout](docs/images/layout-editor.png)

*O editor de layout depois de o painel ter sido posicionado. Um painel que ainda não está
no layout aparece em Available Plugins.*

### Como conferir cada etapa

São três situações diferentes, e ajuda saber em qual delas você está:

| Etapa | Como saber |
|---|---|
| Instalação concluída | O `Install.bat` mostrou `[OK]` para o seu Delphi. Os pacotes estão em `%LOCALAPPDATA%\CSCoder\Hub\bin`. |
| Painel disponível | O Delphi carregou o pacote: **Component > Install Packages** mostra, marcado, o item "CS.Coder - Hub de Projetos (https://www.cscoder.com.br)", e o Welcome Page Layout Editor oferece o painel. |
| Painel visível | O painel foi posicionado no layout da Welcome Page. |

### Atualização

Baixe o zip mais novo, feche o Delphi e execute o `Install.bat` dele. A sua lista é
mantida.

## Principais funcionalidades

### Categorias, grupos e ícones

A estrutura tem dois níveis. Uma **categoria** contém **grupos**, e um **grupo** contém
atalhos de projetos. A categoria é opcional: um grupo pode ficar solto no nível de cima.

Use os níveis para o que fizer sentido no seu trabalho: clientes, empresas, sistemas,
áreas, estudos. Os atalhos apontam para arquivos `.dproj`, `.groupproj` e `.dpr`.

![O painel do Hub, com duas categorias e seus grupos](docs/images/panel.png)

Toda categoria ou grupo pode ter um ícone. Escolha um dos 56 da biblioteca, desenhados na
cor de texto do tema da IDE, ou carregue uma imagem sua (PNG, ICO, JPG, BMP ou GIF). O
ícone é opcional, e a linha sem ícone mantém a aparência de sempre.

Cada categoria e grupo pode ser recolhido, e um botão no cabeçalho recolhe ou expande
tudo.

### Pesquisa por nome e por caminho

Digite na caixa de pesquisa do cabeçalho do painel. A lista passa a mostrar só os projetos
cujo nome ou caminho completo contém o que você digitou, junto com os grupos deles.
Maiúsculas e minúsculas não fazem diferença.

![Pesquisa por "loja" no Hub](docs/images/search.png)

No exemplo acima, digitar `loja` deixa só os dois grupos cujos projetos têm esse texto no
nome ou na pasta.

Pesquisar pelo caminho ajuda quando você lembra onde o projeto está, mas não como ele se
chama. Digitar parte do nome de uma pasta, como `Clientes\ERP`, traz todos os projetos
guardados nela.

### A sua ordem

Arraste e solte projetos, grupos e categorias, ou use as setas que aparecem na linha sob o
mouse. Os projetos de um grupo ficam em ordem alfabética até você mover um deles. Daí em
diante aquele grupo mantém a sua ordem, e **Ordenar por nome**, no menu do grupo, volta ao
alfabético.

### Exportar e importar

O botão da engrenagem tem **Exportar configuração...**, **Importar e mesclar...** e
**Importar e substituir tudo...**. Eles levam a sua organização para outra versão do
Delphi ou para outro computador. Veja em [Gerenciamento dos dados](#gerenciamento-dos-dados)
o que o arquivo contém.

### Cinco idiomas, escolhidos automaticamente

A interface está disponível em português, inglês, espanhol, alemão e francês.

Você não precisa configurar nada. O painel lê o idioma de exibição do Windows e usa esse
idioma. Se o Windows estiver em um idioma que não é um desses cinco, o painel usa o inglês.

Para escolher você mesmo, abra o botão da engrenagem e selecione em **Idioma**. A primeira
opção ali, **Automático (Windows)**, volta a seguir o Windows. A escolha vale só para o
painel e não muda o idioma da IDE.

### Uma primeira abertura útil

O painel não começa vazio. Na primeira vez em que abre em uma versão do Delphi, ainda sem
lista, ele lê o que o Delphi já sabe e cria até dois grupos:

- **Favoritos**, com todos os projetos que você marcou como favoritos no Delphi. Se o
  Delphi não tiver favoritos, esse grupo não é criado.
- **Recentes**, com até dez dos projetos que o Delphi lista como recentes, do mais novo
  para o mais antigo, sem repetir os que já estão em Favoritos.

Projetos cujo arquivo não existe mais ficam de fora.

A partir daí você já pode abri-los e começar a organizar: renomear os grupos, arrastar os
projetos para as suas categorias e grupos, ou excluí-los. São grupos comuns.

Isso acontece uma única vez. Depois que existe uma lista, o Hub não lê mais os favoritos
nem os projetos recentes do Delphi, e as listas do próprio Delphi nunca são alteradas.

### Integração com a IDE

- **Temas.** Toda cor vem do tema da IDE, então o painel acompanha os modos claro e escuro
  e é redesenhado quando você troca.
- **Abrir um projeto.** Dê um duplo clique no atalho, ou use **Abrir** no menu dele. O
  mesmo menu tem **Abrir pasta no Explorer**.
- **Duas IDEs ao mesmo tempo.** Duas janelas da mesma versão do Delphi dividem uma lista.
  Antes de gravar uma alteração, o Hub relê o arquivo, para uma janela não sobrescrever o
  que a outra fez. O botão **Atualizar** mostra as alterações da outra janela.

## Capturas de tela

| Escolhendo um ícone | Menus do projeto e do grupo |
|---|---|
| ![Janela de escolha de ícone, com a biblioteca](docs/images/icon-picker.png) | ![Menu de um projeto](docs/images/project-menu.png)<br>![Menu de um grupo](docs/images/group-menu.png) |

## Seus projetos permanecem intactos

O Hub trabalha com atalhos, que são referências a arquivos de projeto que já existem. Ele
não é dono dos seus projetos e não administra as pastas deles.

- **Remover atalho** tira o item da lista. O arquivo do projeto continua onde está. A
  janela de confirmação avisa isso antes de você confirmar.
- **Excluir um grupo ou uma categoria** remove atalhos da lista, nunca arquivos de projeto.
- **Mover um atalho** para outro grupo ou categoria muda apenas a lista. Nada se move no
  disco.
- **Exportar** guarda a sua organização. Não é um backup do seu código-fonte.
- **Desinstalar o Hub** remove a extensão. Não mexe nos seus projetos.

O Hub grava apenas os próprios arquivos: a lista, a cópia de segurança dela, as imagens de
ícone que você carregou e a configuração de idioma. O código-fonte não tem nenhuma chamada
que apague, mova ou renomeie outro arquivo, e você pode conferir isso em `CSCoderHub/src/`.

## Gerenciamento dos dados

### Onde a lista fica

A lista é um arquivo JSON no seu computador:

```
%LOCALAPPDATA%\CSCoder\Hub\D11\projects.json
%LOCALAPPDATA%\CSCoder\Hub\D12\projects.json
%LOCALAPPDATA%\CSCoder\Hub\D13\projects.json
```

- Cada versão do Delphi tem a sua lista. As IDEs de 32 e de 64 bits da mesma versão
  compartilham a mesma.
- Toda vez que a lista é gravada, a versão anterior fica guardada como `projects.json.bak`.
- As imagens de ícone que você carregou ficam em uma pasta `icons`, ao lado da lista.
- O Hub não usa a rede. Nada é coletado nem enviado a lugar nenhum.

### Exportar

**Botão da engrenagem > Exportar configuração...** grava um arquivo JSON com:

- as suas categorias e os seus grupos, com a ordem e o estado recolhido;
- cada atalho, com o nome e o caminho completo do arquivo de projeto;
- o ícone escolhido para cada categoria e grupo;
- as imagens de ícone que você carregou, embutidas no arquivo.

O arquivo guarda a organização e os caminhos. Ele não guarda os projetos em si.

### Importar

- **Importar e mesclar...** acrescenta o que falta e deixa o resto como está. Categoria ou
  grupo que já existe mantém o ícone que tem, e projeto que já tem atalho não ganha um
  segundo.
- **Importar e substituir tudo...** pede confirmação e então troca a lista inteira pela do
  arquivo. A lista que você tinha fica guardada como `projects.json.bak`.

Um arquivo sem nenhuma categoria e nenhum grupo é recusado, e a sua lista fica como está.

### Levar para outro computador

Os atalhos guardam caminhos completos. Em outro computador, os projetos precisam estar nos
mesmos locais. Um atalho cujo arquivo não é encontrado continua na lista, marcado como
`[arquivo ausente]`, até você removê-lo ou adicionar o projeto de novo a partir do novo
local.

## Desinstalação

Feche o Delphi antes. O desinstalador, como o instalador, para se o Delphi estiver aberto.

### Remover a extensão e manter a sua lista

```
Uninstall.bat
```

Remove o Hub de todas as versões do Delphi e apaga os pacotes instalados. A sua lista, a
cópia de segurança e as suas imagens de ícone são mantidas, então instalar de novo traz
tudo de volta.

### Remover a extensão e os dados

```
Uninstall.bat /data
```

> [!WARNING]
> Este comando apaga também a lista de todas as versões do Delphi, as cópias de segurança,
> as imagens de ícone que você carregou e a configuração de idioma. Não há como desfazer,
> a menos que você tenha uma cópia exportada. Para guardar uma, abra o Delphi **antes de
> desinstalar** e use **Botão da engrenagem > Exportar configuração...** em cada versão do
> Delphi cuja lista você quer manter.

Nenhum dos dois comandos mexe nos seus projetos.

## Compilar a partir do código

`CSCoderHub/build.bat [11|12|13|all]` compila os pacotes com os compiladores de linha de
comando de cada Delphi. Ajuste os três caminhos de instalação no início do arquivo para a
sua máquina. `CSCoderHub/package.bat` compila tudo e também monta `CSCoderHub/dist/`.

Não há `.dproj`. Há um `.dpk` por versão do Delphi, e todos usam as mesmas units. Para
carregar um pacote que você compilou, use **Component > Install Packages > Add** e escolha
o `.bpl` de `CSCoderHub/bin/` (IDE de 32 bits) ou de `CSCoderHub/bin/Win64/` (IDE de 64
bits).

O formato do arquivo de dados e as limitações conhecidas estão na referência técnica,
[CSCoderHub/README.md](CSCoderHub/README.md), em inglês.

## Estrutura do repositório

- `CSCoderHub/src/`: os fontes da extensão (units `CSCoder.Hub.*`)
- `CSCoderHub/packages/`: um `.dpk` por versão do Delphi e o recurso de versão compartilhado
- `CSCoderHub/installer/`: os scripts de instalar e desinstalar que vão no zip
- `CSCoderHub/installer-readme/`: os arquivos de texto que vão no zip
- `CSCoderHub/dist/`: pacotes prontos
- `docs/images/`: imagens desta página

## Como foi feito

O autor trabalha profissionalmente com Delphi há muitos anos, desenvolvendo aplicações
desktop, mobile e web, incluindo soluções com UniGUI. Lidar com muitos sistemas e clientes
ao mesmo tempo trouxe uma necessidade prática: um lugar na Welcome Page para guardar os
atalhos dos projetos arrumados de um jeito pessoal.

O CS.Coder Project Hub é essa necessidade transformada em ferramenta e compartilhada com a
comunidade. Ele foi desenvolvido com o Claude Code, assistente de programação da
Anthropic, usado como recurso de produtividade. Os requisitos, as decisões de produto, o
visual, os testes dentro da IDE e a aprovação de cada tela são do autor. A maior parte do
código foi escrita pelo assistente e conferida com programas de teste antes de cada
entrega.

A primeira versão foi da ideia ao repositório público em menos de 24 horas, em outubro de
2026. Isso diz algo sobre o que essas ferramentas tornam possível. Não é apresentado como
medida de qualidade: o projeto é aberto justamente para que qualquer pessoa leia o código,
experimente e aponte o que pode melhorar.

## Contribuições e suporte

- **Problemas e sugestões:** abra uma
  [issue](https://github.com/cscoder69/delphi-project-hub/issues).
- **Contribuições:** pull requests são bem-vindos. Para uma mudança maior, abra uma issue
  antes, para combinarmos o caminho.
- **Contato:** contato@cscoder.com.br

## Licença e créditos

Distribuído sob a [licença MIT](LICENSE). Copyright (c) 2026 CS.Coder.

"Delphi" e "RAD Studio" são marcas da Embarcadero Technologies, Inc. O CS.Coder Project Hub
é um projeto independente. Não tem vínculo com a Embarcadero, não é mantido por ela nem
conta com o seu endosso.
