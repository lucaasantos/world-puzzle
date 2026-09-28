# Puzzle World — desempenho e segurança da economia

## Arquitetura implementada

### Conclusão de partida

Ao concluir uma fase, o cliente calcula imediatamente a apresentação de estrelas,
recorde, XP, progresso do país, Exploração Diária e Pó Estelar a partir do último
estado confirmado. A tela de vitória abre sem aguardar rede e sem diálogo de
salvamento. Esses valores são apenas uma projeção de interface.

A operação `MATCH_RESULT` é persistida em `SharedPreferences` por UID com
`operationId` (o mesmo ID imutável da tentativa/partida), payload, horário local
informativo, número de tentativas, estado e próxima tentativa. O cliente chama
`submitMatchResult` em segundo plano. Falhas transitórias mantêm a operação na
fila e usam retentativa com backoff; uma resposta já processada é devolvida pelo
servidor e remove a operação. Rejeições definitivas ficam marcadas como `failed`
e não são repetidas silenciosamente.

`submitMatchResult` executa em uma única transação a validação da solução e a
atualização de XP, melhor resultado, Exploração Diária, progresso semanal, Pó
Estelar, recompensas de nível e recibo de auditoria. `finishAttempt` permanece
publicada como alias compatível com APKs anteriores.

### Pacotes

O toque em **ABRIR** desabilita a ação e inicia imediatamente a animação. A
callable `openPack` roda em paralelo; se ainda não houver resposta na etapa de
revelação, a tela mantém somente um indicador sutil. Uma rejeição restaura a
embalagem e não desconta nada localmente.

Cada abertura usa um `openingId` aleatório persistido antes da chamada. A
transação lê o pacote individual e `users/{uid}/packOpenings/{openingId}`,
valida propriedade, sorteia usando o catálogo/pesos do backend, grava inventário,
consome o pacote e salva o resultado original. Repetir o mesmo `openingId` ou o
mesmo pacote nunca concede cartas novamente. A resposta contém IDs leves; nome,
imagem e apresentação continuam nos assets locais.

### Economia e regras

- `users/{uid}` (World Coins, XP, vidas e Pó Estelar), `collection`, `packs`,
  `packOpenings`, `rewards`, `weeklyStarProgress`, `adTickets` e o ledger são
  escritos somente pelo Admin SDK.
- Rewarded Ads usam ticket e transaction ID únicos, callback SSV assinado e
  limite diário de 10 validado pelo servidor. O callback do APK não concede moeda.
- `economyTransactions` registra World Coin, `MATCH_RESULT` e `PACK_OPEN` com
  horário do servidor da Function. A coleção não pode ser lida pelo jogador.
- A hora do aparelho só participa da apresentação e do agendamento local de
  retentativa; ciclos, limites e concessões usam o relógio do backend.
- As regras do Firestore negam toda escrita do cliente nos dados econômicos e
  também negam acesso a coleções não listadas.

## Regiões e latência

Firestore e Functions estão configurados em `southamerica-east1`. As callable do
cliente usam explicitamente a mesma região, portanto não há chamada cruzada entre
regiões no fluxo de jogo. Nenhuma migração regional foi feita. Firebase Auth,
App Check e AdMob são serviços globais/gerenciados.

O Admin SDK, Firestore, catálogo e configuração de Function são inicializados no
escopo do módulo e reutilizados entre invocações. Não foi habilitado
`minInstances`: isso evita novo custo fixo, mas uma primeira chamada após período
ocioso ainda pode sofrer cold start. Se métricas reais mostrarem impacto, avaliar
`minInstances` apenas para `openPack` e `submitMatchResult`, ciente da cobrança.

## Configuração manual antes da produção

1. No Firebase Console, registrar o app Android no App Check com **Play Integrity**
   e vincular o projeto correto do Google Play.
2. Registrar no App Check os tokens de debug usados por desenvolvedores. Builds
   debug usam `AndroidDebugProvider`; emuladores Firebase não exigem App Check;
   release usa `AndroidPlayIntegrityProvider`.
3. Depois de validar telemetria, habilitar enforcement de App Check para
   Firestore e demais serviços protegidos. As callable já exigem token fora do
   emulador.
4. Configurar SHA-256 da chave de assinatura de produção no Firebase/Play e
   publicar o app por uma faixa do Play Console para validar tokens reais.
5. Publicar primeiro as Functions (incluindo `submitMatchResult`) e as regras;
   só então distribuir o novo APK. Não há credencial nova no repositório.

## Compatibilidade, migração e custo

Não há migração obrigatória. Documentos atuais de pacote continuam válidos;
`openingId`, `packOpenings` e novos recibos aparecem apenas em operações futuras.
Tentativas já concluídas continuam respondendo pelo resultado gravado. Contas
existentes continuam normalizadas pela sincronização atual.

O custo incremental é de uma escrita de ledger por partida, duas escritas de
idempotência/auditoria por abertura (`packOpenings` e ledger) e leituras
transacionais correspondentes. A consolidação da conclusão mantém uma única
callable e evita as cinco chamadas sequenciais que existiriam se cada progresso
fosse salvo separadamente. A fila local não gera custo enquanto offline e usa
backoff limitado a cinco minutos.
