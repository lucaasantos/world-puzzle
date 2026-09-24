# Validação do fluxo Codex/ChatGPT — 15/09/2026

- 12 testes Python passaram: fila, retomada, proteção contra duplicatas,
  importação, falhas, limites, revisão e aplicação em projeto temporário.
- Teste real: uma arte de `brazil_rio_de_janeiro`, gerada com a ferramenta
  integrada image_gen, sem API key e sem chamada HTTP de API pela ferramenta local.
- Lote: `2ede19f254434df497f956ca05349a67`.
- Job: `c4fb3f6ccc004cadbc794af850a95a20`.
- Original preservado em
  `output/originals/c4fb3f6ccc004cadbc794af850a95a20.png`.
- Resultado: `output/generated/brazil_rio_de_janeiro__a0001__c4fb3f6c.webp`.
- Formato WEBP, 1000 × 1024, 241.464 bytes. Inspeção visual da versão final:
  paisagem ilustrada, sem texto, moldura ou UI; assunto e composição preservados.
- Status da carta: `generated`, aguardando revisão do usuário. Não aprovada nem
  aplicada. Lista estática de assets aprovados permanece vazia.
- Resumo real: 1 gerada, 767 pendentes; lote com 1 concluída e 0 falhas.

O prompt exato usado está no job persistente e em `logs/events.jsonl`. Consulte:

```powershell
python cards.py job --job=c4fb3f6ccc004cadbc794af850a95a20
```

Esse registro é um retrato do teste inicial; novas gerações/revisões podem mudar
os estados. Consulte `status` e `batch` para a situação atual.
