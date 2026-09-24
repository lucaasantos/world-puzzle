# Processamento de artes pelo agente

Este procedimento vale para pedidos de geração de cartas neste projeto. Use a
skill imagegen disponível e a ferramenta integrada image_gen. Nenhuma chave é
necessária. Não ofereça API paga como requisito e não use login/cookies do usuário.

## Uma solicitação, um lote

1. Execute `python tools/card-image-generator/cards.py generate --limit=15` na
   raiz. Use o limite pedido pelo usuário; para carta específica, `--id=<id>`.
   Para novo teste inicial, limite a uma ou duas imagens. Para nova versão use
   `regenerate --id=<id>`. Para falhas, `retry-failed`.
2. Guarde o batchId. Ao retomar um lote identificado, use `batch --batch=<batchId>`
   em vez de criar uma seleção nova. Nunca gere o catálogo inteiro por inferência.
3. Para cada job queued do lote, execute `start --job=<jobId>`. O JSON retornado
   traz `promptUsed`. Ele já contém assunto, estilo fixo e parâmetros visuais.
4. Faça **uma chamada independente** a image_gen com esse prompt exato. Não inclua
   histórico, referências, outras cartas ou imagens anteriores. Não passe
   num_last_images_to_include nem referenced_image_paths para arte nova.
5. Assim que a chamada terminar, use o caminho local efetivamente devolvido pela
   ferramenta. Não adivinhe nomes nem escolha o arquivo mais recente de uma pasta.
   Execute `import --job=<jobId> --file=<caminho local>`. O importador preserva o
   original no projeto, valida, converte, comprime e salva na área de revisão.
6. Inspecione a imagem final. Informe problemas visuais sem aprovar silenciosamente.
   Se não houver arquivo local utilizável no resultado, informe a limitação;
   se necessário, peça o arquivo. Não marque como gerada sem a importação.
7. Continue os demais jobs solicitados na sessão ativa. Uma falha individual deve
   ser registrada com `fail --job=<jobId> --reason=<erro sanitizado>`; depois siga
   para os demais. Se houver limite geral da ferramenta, encerre o lote por ora,
   deixando os jobs ainda não iniciados queued. Não tente contornar limites.
8. Exiba o resumo de `batch --batch=<batchId>`, caminhos e previews relevantes.
   Separe concluídos, falhas e itens em fila. Informe que a revisão está pendente.

## Retomada segura

- Não repita image_gen para um job running automaticamente. A geração pode já
  ter terminado. Consulte `job --job=<jobId>` e os resultados da sessão anterior.
- Se o arquivo existir, importe-o. Repetir a importação do mesmo arquivo é seguro.
- Se a chamada falhou ou não há resultado recuperável, registre fail e prepare
  retry. Isso cria outra tentativa e mantém o histórico.
- Jobs completed não precisam gerar novamente. Regeneração precisa decorrer do
  pedido do usuário ou de um ajuste necessário explicitamente relatado.
- A fila e os prompts são persistentes. Não se promete execução com o Codex
  fechado, geração ilimitada ou que a assinatura possa ser usada por um script.

## Identidade visual das cidades

Antes de preparar novas cidades, pesquisar referências confiáveis de cada lugar.
Registrar no prompt do job um cenário local específico, os elementos que o tornam
reconhecível, a paleta motivada pelo ambiente e o enquadramento escolhido. Guardar
as fontes junto ao lote. Comparar as composições do país antes de gerar: variar
altura da câmera, posição do assunto, luz e contexto urbano. Não repetir a fórmula
de flores em primeiro plano, casario amarelo, igreja, lago e vulcão ao fundo.
Manter a técnica de ilustração da coleção, preservando a identidade de cada lugar.
Após gerar, comparar as cidades lado a lado e corrigir repetições evidentes antes
de apresentar o lote. Esta orientação vale para novos lotes; não regenerar artes
já aprovadas sem solicitação do usuário.

## Aprovação e aplicação

`approve/reject --id=<id>` registram a decisão do usuário. Quando ele aprovar e
pedir aplicação (ou já a tiver autorizado), execute `apply --id=<id>`. Não peça a
mesma aprovação novamente. `--replace` corresponde à substituição explícita de
uma arte existente e cria backup. Nunca aprove/aplique só porque passou em teste.

O layout e a mecânica continuam no Flutter. Somente a arte final aprovada pode
entrar em assets. Prompts, originais, arquivos de revisão e ferramentas ficam fora
do bundle. Veja README.md desta pasta para comandos completos e recuperação.
