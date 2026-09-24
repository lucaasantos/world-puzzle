# Gerador de artes — Codex / ChatGPT

Ferramenta interna do Puzzle World, separada do jogo. **Não exige chave de API.**
A geração usa a ferramenta integrada de imagens do Codex/ChatGPT. A CLI organiza
os lotes, conserva os prompts e importa, valida e converte cada resultado.

## Como usar pelo Codex

Basta pedir nesta tarefa, por exemplo:

- **Gere as próximas 15 artes e deixe para revisão.**
- **Continue o lote anterior.**
- **Gere novamente a carta brazil_sao_paulo.**
- **Aprove e aplique a arte do Rio de Janeiro.**

O agente segue `AGENT_WORKFLOW.md`: prepara a fila, inicia um job, envia somente
o prompt daquela carta à ferramenta integrada e importa o arquivo devolvido.
Não é necessário copiar prompts nem organizar arquivos manualmente no Codex.
Cada imagem usa uma chamada independente; não são enviadas imagens anteriores.

**Limite prático:** um script Python não pode usar sua assinatura do ChatGPT nem
invocar sozinho uma ferramenta do Codex. A etapa de geração precisa de uma sessão
ativa com a ferramenta de imagens disponível. Isso não é um serviço autônomo em
segundo plano. Ao atingir limites de uso ou interromper a sessão, a fila permanece
salva para retomar. O fluxo não usa API paga, cookies, senha ou automação de login.
Os limites reais da ferramenta integrada continuam valendo; não prometemos geração
ilimitada nem capacidade fixa de 15 imagens por sessão.

## Instalação

Python 3.12+, Pillow e Dart do Flutter no PATH. Na pasta da ferramenta:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Se Pillow já estiver instalado, nenhuma instalação adicional é necessária.
`.env` é **opcional**. `.env.example` contém somente `DAILY_GENERATION_LIMIT=0`
(zero desativa o limite diário local; valores positivos definem um limite em UTC) e um exemplo de `DART_EXECUTABLE`. Variáveis de ambiente
antigas de API não ativam chamadas pagas; o provedor HTTP foi removido.

## Comandos para a fila

Na pasta da ferramenta, usando o Python com Pillow instalado:

```powershell
# Preparar uma carta ou um lote (sem gerar imagens pelo terminal)
python cards.py generate --id=brazil_rio_de_janeiro
python cards.py generate --limit=15
python cards.py generate --limit=15 --dry-run

# Consultar pendentes, arte atual, jobs e resumo de um lote
python cards.py list-pending
python cards.py status
python cards.py show --id=brazil_rio_de_janeiro
python cards.py jobs
python cards.py batch --batch=<batchId>

# O Codex executa estes passos ao processar cada job
python cards.py start --job=<jobId>
# Em seguida, chama image_gen com o promptUsed retornado.
python cards.py import --job=<jobId> --file="C:\caminho\imagem-gerada.png"

# Consultar um job em andamento sem iniciar outra tentativa
python cards.py job --job=<jobId>
# Se a geração falhou ou foi perdida: registrar antes de preparar retry
python cards.py fail --job=<jobId> --reason="Geração interrompida sem resultado"
python cards.py retry-failed --limit=15

# Preparar uma nova versão; preserva as artes antigas
python cards.py regenerate --id=brazil_rio_de_janeiro
```

`generate` retorna `batchId` e os jobs selecionados. Repetir a preparação prioriza
os jobs abertos e não duplica trabalhos. Para retomar **exatamente** o mesmo lote,
use `batch --batch=<batchId>` e processe somente seus jobs ainda abertos.
`start` reserva uma tentativa e retorna o prompt e configurações congelados no
momento da preparação. Repetir `start` em um job iniciado é bloqueado.
`import` repetido com o mesmo arquivo é idempotente: não cria outra versão.
Atribuir o mesmo arquivo a duas cartas distintas é bloqueado.

Para imagens criadas fora desta tarefa no ChatGPT, salve/anexe o arquivo e peça
para o Codex importar para a carta correta. Os mesmos jobs podem ser usados,
com `start` antes da importação. Não é necessário fornecer credenciais.

## Revisão e aplicação

```powershell
python cards.py approve --id=brazil_rio_de_janeiro --note="Arte revisada"
python cards.py reject --id=brazil_sao_paulo --note="Rever composição"
python cards.py apply --id=brazil_rio_de_janeiro
# Se já existir um asset diferente, exige substituição explícita e cria backup:
python cards.py apply --id=brazil_rio_de_janeiro --replace
```

A inspeção técnica do Codex não substitui a aprovação manual. Nenhuma arte é
aprovada/aplicada automaticamente. Após apply, execute `flutter pub get` na raiz
e reinicie/reconstrua o jogo para atualizar os assets.

## Arquivos e estados

- `data/state.sqlite3`: jobs, estados por ID, eventos e tentativas reservadas.
- `output/batches/`: seleção de jobs por lote; seu resumo consulta o estado atual.
- `output/originals/`: cópia do original devolvido pelo Codex/ChatGPT.
- `output/generated/`: WebP otimizado para revisão, com ID, tentativa e versão.
- `output/approved/` e `output/rejected/`: versões revisadas; sem sobrescrita.
- `output/applied-backups/`: asset anterior, manifest e pubspec antes de aplicar.
- `logs/events.jsonl`: histórico exportado do banco, com prompt, arquivo, provedor,
  resultado, erro e tentativa. Modelo/uso ficam nulos quando a ferramenta integrada
  não informa esses dados; não se inventam custos ou contagens de tokens.

Carta: `pending â†’ generating â†’ generated â†’ approved/rejected`.
Nova tentativa: `retry â†’ generating`. Falhas ficam em `failed`.
Job: `queued â†’ running â†’ completed/failed`.
Um job running permanece assim entre comandos/sessões: pode estar aguardando o
resultado da ferramenta. Consulte-o e importe seu resultado; não gere outra imagem
silenciosamente. Se não houver resultado recuperável, registre fail e faça retry.
Falha de importação mantém o job running para corrigir o arquivo sem nova geração.

Limite padrão: 15 selecionadas por execução; 15 inícios por dia UTC neste banco.
Preparar jobs não consome esse contador. Falhas após start contam como tentativa.
O contador local não mede nem altera a cota do Plus/Codex. O resumo de batch mostra
selected, queued, running, completed e failed. CLI retorna 0 ao concluir o comando
ou 1 se houver erro; preparar um lote não significa que suas imagens foram geradas.

Preserve banco e outputs juntos para manter histórico. O bloqueio do sistema
operacional protege cada comando de concorrência. O arquivo workflow.lock pode
permanecer no disco; não representa sozinho uma execução ativa.

## Compatibilidade com o jogo

Fonte única: `lib/data/cards_data.dart`, executada a cada comando pelo exportador
Dart. São 768 cartas em 43 países; nenhuma segunda base de seeds é criada.
`BR-001` é número de catálogo; o ID aceito é `brazil_rio_de_janeiro`.

As artes temporárias são widgets, sem caminho de imagem (`temporaryArtPath=null`).
A carta completa é 5:7; a ilustração ocupa 164 × 168 na largura nominal de 180,
com recorte central por `BoxFit.cover`. A proporção varia nos extremos do layout.
Saída: **WebP 1000 × 1024**, qualidade inicial 86, máximo 650 KB, sem upscale.
O comando `inspect` lê o contrato atual e inspeciona assets já existentes.

`config/prompt.txt` centraliza o prompt; `config/style.json`, o estilo e a saída.
A configuração é congelada em cada job, para uma alteração futura não modificar
uma geração já preparada. As imagens contêm apenas ilustração, sem moldura/UI/texto.

`apply` usa `assets/images/cards/<país>/<raridade>/<id>.webp`, ativa o ID em
`lib/data/approved_card_art.dart` e registra a pasta em `pubspec.yaml` se necessário.
Só assets aprovados e a lista estática chegam ao jogo. Não há dependências novas
Flutter, serviços de geração, credenciais ou interface de IA no aplicativo.
SHA-256 detecta mudanças nos arquivos após gerar/aprovar; substituições exigem
`--replace`, com backup. Em interrupção abrupta durante apply, repetir apply com
a mesma versão conclui a operação; os backups permitem restauração manual.

## Testes

```powershell
python -m unittest discover -s tests -v
# Na raiz do jogo:
flutter test test/data/cards_data_test.dart test/widgets/collectible_card_view_test.dart
flutter test --no-pub tools/card-image-generator/tests/artwork_loading_test.dart
```

Os testes locais não fazem chamadas de geração: usam arquivos existentes e duas
cartas em projeto temporário. Cobrem fila, retomada, prompts independentes,
importação idempotente, configuração congelada, falha parcial, limite persistente,
WebP, revisão, proteção de versões, backup e reexportação do catálogo aplicado.
O teste de lote de 15 somente prepara jobs, sem gerar imagens.

O teste real de uma imagem pelo Codex, os caminhos e o resultado estão em
[VALIDATION.md](VALIDATION.md).

## Alteração para Codex/ChatGPT

Adicionado `src/jobs.py`, testes de fila e `AGENT_WORKFLOW.md`. A CLI agora prepara
jobs e importa arquivos. Removida a implementação HTTP/API de `src/providers.py`;
restou o contrato para adaptadores locais e testes. O histórico antigo é preservado.
A orientação está em `AGENTS.md` na raiz para futuras sessões do Codex.
Nenhuma mudança adicional de layout, mecânica ou dependência do jogo foi necessária.
