# Puzzle World — integração online

## Estado da entrega

O código do aplicativo e das dez Cloud Functions está integrado. O projeto Firebase `puzzle-world-a7b7d` e o app Android já estão cadastrados; o Firestore está em São Paulo com regras e índices publicados. Functions, Play Games e AdMob ainda dependem da ativação descrita em [ONLINE_ACTIVATION_CHECKLIST.md](ONLINE_ACTIVATION_CHECKLIST.md). Sem configuração, a versão normal mostra **Serviços online em preparação**; nunca cria uma conta fictícia nem concede economia local. Os emuladores permitem validar o fluxo sem um projeto real.

O puzzle, a abertura visual de pacotes, o catálogo, a coleção e o álbum existentes foram reutilizados. O Brasil utiliza as artes existentes de Rio de Janeiro, São Paulo, Brasília e Salvador. Nenhuma carta/moldura foi recriada. Não há moedas, comércio ou transferência.

## Decisões iniciais de balanceamento

Fonte autoritativa: `functions/src/economy.js`.

| Parâmetro | Inicial |
| --- | --- |
| XP Fácil / Médio / Difícil | 25 / 50 / 90 |
| Custo de uma tentativa | 1 vida, cobrada ao iniciar |
| Máximo / regeneração / Rewarded | 5 / 30 minutos / 2 vidas |
| Interstitial | a cada 3 conclusões; 0 desativa |
| Limite de nível | 30; todo XP excedente fica acumulado |
| XP de cada transição de nível L | arredondar(100 + 35 × (L − 1)^1,5) |
| Reset diário | 03:00 UTC, sem horário de verão |
| Exploração | quatro países distintos; primeira dificuldade concluída de cada país |
| Faixas da média | abaixo de 1,5 / abaixo de 2 / abaixo de 2,5 / até 3 |
| Recompensas de marcos | níveis 5, 10, 15, 20, 25 e 30; desativadas |

O tempo da tentativa continua correndo enquanto o jogo está pausado/fechado. A vida é consumida na abertura da tentativa, portanto a derrota ou o abandono não cobra uma segunda vida. Isso impede que fechar o aplicativo evite o custo. Novos modos podem reutilizar a economia, mas precisam implementar seu próprio validador de conclusão no servidor.

Os quatro tipos têm IDs `world_pack`, `explorer_pack`, `tier3_pack`, `tier4_pack`; os dois últimos são apresentados como **Pack 3** e **Pack 4**. A quantidade de cartas e os pesos de raridade preservam o catálogo atual: 4, 5, 6 e 7 cartas. As tabelas de escolha do pacote são 100/0/0/0, 90/10/0/0, 80/18/2/0 e 70/25/4/1. Não há chance de pacote por repetição de fase no caminho online.

World Coin começa em zero e usa `worldCoin.rewardedAdAmount` (1) e `worldCoin.dailyAdLimit` (10) na mesma configuração validada. O saldo e o progresso diário ficam em `users/{uid}`; o reset usa o ciclo diário existente, às 03:00 UTC. Cada crédito gera um documento imutável em `users/{uid}/economyTransactions/{transactionId}` na mesma transação que atualiza saldo e contador. Essa coleção é inacessível diretamente ao cliente pelas Security Rules.

## Desenvolvimento local

Requisitos: Flutter, Java 21 ou compatível com a versão da Firebase CLI, Node 22 (runtime de produção), npm. A máquina desta implementação usa Node 24; o emulador avisa sobre a diferença.

Na raiz:

```powershell
flutter pub get
dart run tools/export_backend_catalog.dart
npm.cmd ci --prefix functions
$env:CI='true'
$env:FIREBASE_CLI_DISABLE_UPDATE_CHECK='true'
$env:FUNCTIONS_DISCOVERY_TIMEOUT='60'
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:start --project demo-puzzle-world --only auth,firestore,functions
```

Em outro terminal, para um emulador Android:

```powershell
flutter run --dart-define=FIREBASE_EMULATOR=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

Em aparelho físico, use o IP acessível do computador e configure os emuladores para escutar na rede de desenvolvimento. O login anônimo só existe nesse modo debug e é rejeitado pelas Functions de produção. Não há botão para conceder XP, cartas ou pacotes online. O modo de emuladores é bloqueado em release.

Testes:

```powershell
flutter analyze lib test
flutter test
npm.cmd test --prefix functions
node functions/node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --project demo-puzzle-world --only auth,firestore,functions "npm.cmd run test:emulator --prefix functions"
flutter build apk --debug
```

O teste de integração usa um projeto `demo-`, usuários temporários e acesso administrativo apenas para fixtures de puzzle/tempo. Verifica as funções reais por HTTP, regras de leitura/escrita, concorrência, limites de vida, duplicatas, colagem e resgate de dias anteriores. Nunca execute fixtures em um projeto de produção.

## Conectar os serviços reais

1. Criar um projeto Firebase e registrar Android com o applicationId existente `com.puzzlejourney.puzzle_journey`. Adicionar os certificados SHA de teste e de distribuição corretos. Criar Firestore e habilitar Authentication, Analytics, Remote Config e App Check. Configurar o projeto para permitir publicação de Cloud Functions.
2. No Google Play Console, configurar Play Games Services para o mesmo projeto. Criar a credencial Android e a credencial de servidor de jogo. Habilitar o provedor Play Games no Firebase Authentication com o OAuth Web Client ID correspondente. O segredo OAuth fica no console, nunca no aplicativo. Adicionar testadores antes de disponibilizar o jogo.
3. Copiar `config/firebase.example.json` para `config/firebase.local.json` e preencher os valores públicos do app Firebase e `PLAY_GAMES_WEB_CLIENT_ID`. O app inicializa Firebase explicitamente com essas opções. Configuração nativa gerada pelo FlutterFire pode ser acrescentada conforme necessário para recursos específicos de Analytics/distribuição.
4. Definir `PLAY_GAMES_PROJECT_ID` nas propriedades Gradle locais (ID numérico do jogo). O valor padrão `0` mantém login desabilitado. O canal Android obtém um server auth code pelo SDK Play Games v2; o Flutter troca esse código por credencial Firebase. Nenhum Play Games ID vira chave de dados.
5. Registrar App Check com Play Integrity. Em desenvolvimento com Firebase real, registrar o token de debug no console. As callable Functions exigem App Check em produção. Para iOS, há interface independente `PlayerIdentityProvider` e preparação App Attest; o provedor de autenticação iOS ainda precisa ser implementado quando a plataforma for adicionada.
6. Publicar as regras e as Functions no projeto escolhido, explicitamente:

```powershell
node functions/node_modules/firebase-tools/lib/bin/firebase.js login
node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy --project SEU_PROJECT_ID --only firestore:rules,firestore:indexes,functions
flutter build apk --debug --dart-define-from-file=config/firebase.local.json
```

As regras, os índices e as dez Functions já foram publicados no projeto real. Antes de distribuição, substituir a assinatura Android de debug pela assinatura de release do proprietário.

## Anúncios

Criar o aplicativo e as unidades no AdMob. Definir `ADMOB_APP_ID` no Gradle e preencher `ADMOB_ANDROID_REWARDED_ID` / `ADMOB_ANDROID_INTERSTITIAL_ID` no JSON de build. IDs oficiais de teste só são o default em debug; IDs ausentes em release deixam a unidade indisponível. A configuração iOS tem os equivalentes `ADMOB_IOS_REWARDED_ID` e `ADMOB_IOS_INTERSTITIAL_ID`.

Configurar SSV da unidade rewarded para a URL publicada de `admobReward`. Criar `functions/.env.<projectId>` a partir do exemplo, substituindo `<projectId>` pelo ID real, com `ADMOB_REWARDED_UNIT_IDS` contendo os identificadores exatos enviados no parâmetro `ad_unit` pelo AdMob. Publicar novamente a função após configurar o ambiente. Lista vazia rejeita todas as recompensas.

O cliente pede um ticket tipado, passa Firebase UID e ticket em `ServerSideVerificationOptions`, e apresenta o anúncio disponível. Somente o callback SSV com assinatura ECDSA válida, unidade permitida, ticket correspondente, timestamp válido e transaction ID inédito concede vidas ou World Coins. Cliques, falhas e fechamento antecipado não concedem economia. Para World Coin, `claimRewardedWorldCoin` apenas consulta a confirmação SSV em produção; no emulador ela conclui a mesma transação para permitir o teste end-to-end sem uma unidade real. Se a confirmação demorar, a sincronização autoritativa recupera o saldo. Test ads não comprovam o caminho SSV real; fazer o teste final numa unidade configurada antes de publicar.

Interstitial é pré-carregado durante a partida e só é solicitado após o resultado persistido. Sem anúncio pronto, a transição segue; há timeout para callbacks ausentes.

## Remote Config e consistência

Criar no **template de servidor** o parâmetro JSON `economy_json`, com o objeto completo de `defaults` em `functions/src/economy.js`. O backend valida limites, chaves e soma das probabilidades; valores inválidos/indisponíveis mantêm o último objeto validado ou os defaults. O cache dura cinco minutos. `packOdds` usa um mapa com chaves `0` a `3`, cada uma contendo os quatro pesos: Firestore não aceita arrays diretamente dentro de arrays.

XP e regras da tentativa ficam congelados no início; regras da exploração ficam congeladas no primeiro país daquele ciclo. A UI usa a configuração retornada pelo backend. O SDK cliente de Remote Config é inicializado com fallback, mas seus valores nunca autorizam economia. A frequência dos anúncios também vem do objeto validado do servidor.

Alterar o horário de reset após lançamento exige planejamento/migração de ciclos: não troque a fronteira no meio de um dia ativo. A política inicial é fixa em 03:00 UTC. Um dia concluído, mas não resgatado por queda de conexão, permanece resgatável pelo seu ID original. Ele não ocupa a recompensa do dia seguinte.

## Dados e segurança

- `users/{firebaseUid}`: perfil resumido, XP total, vidas/âncora temporal e contadores.
- `profiles/{uid}`: nickname, avatar e campos vazios para futuras conquistas, badges e moldura.
- `nicknames/{normalizedName}`: reserva atômica; nunca consultada diretamente pelo cliente.
- `users/{uid}/attempts/{requestId}`: desafio emitido pelo servidor, configuração e resultado durável.
- `users/{uid}/progress/{levelId}`: melhores resultados validados.
- `users/{uid}/dailyExploration/{dailyId}`: mapa de no máximo quatro países, dificuldade e resgate.
- `users/{uid}/rewards/daily_{dailyId}` e `level_{level}`: recibos idempotentes.
- `users/{uid}/packs/{instanceId}`: pacote individual, estado de abertura e resultado imutável.
- `users/{uid}/collection/{cardId}`: quantidade **disponível** e `pastedInAlbum`. Total possuído é quantidade disponível + uma unidade se colada.
- `users/{uid}/album/{cardId}`: registro da colagem. Duplicatas restantes nunca são excluídas.
- `users/{uid}/adTickets/{ticket}` e `adTransactions/{transactionId}`: idempotência de Rewarded.
- `users/{uid}`: também guarda `worldCoins` e `worldCoinRewardAds` (`cycleId` e `earnedToday`); contas antigas são normalizadas para zero na sincronização.
- `users/{uid}/economyTransactions/{transactionId}`: ledger privado e server-only de World Coin, preparado para novos tipos de transação.

Security Rules negam toda escrita direta nesses dados e permitem somente leituras autorizadas da própria conta. As Functions usam transações. O servidor gera o tabuleiro e reexecuta os movimentos; rejeita sequência ilegal, resultado não resolvido, tentativa encerrada, expirada ou fora dos limites. Uma conta tem somente uma tentativa ativa; abrir outra invalida a anterior atomicamente. Isso impede um simples callback de vitória forjado, mas não impede bots que resolvem puzzles legalmente. App Check é uma camada adicional, não substitui as regras e validações.

Inventários ficam em documentos separados, lidos em páginas de 250. O histórico não fica em arrays gigantes no documento do jogador. Com crescimento de usuários/histórico, evoluir sincronização incremental e política de retenção preservando os recibos de idempotência.

## Recuperação e dados antigos

O diário local de movimentos, pedido de início e abertura pendente é separado por UID. O relógio local só apresenta contagens regressivas usando uma âncora recebida do servidor e um cronômetro monotônico. Ele não concede regeneração nem faz reset. Durante queda de conexão, o tabuleiro e a sequência permanecem; a conclusão pode ser reenviada com a mesma identidade.

O arquivo de progresso anterior continua preservado em `puzzle_journey_progress_v1`; o app online utiliza `puzzle_world_online_preferences_v1` para preferências. Cartas/XP/pacotes locais não são importados automaticamente, pois a versão anterior permitia concessão local de debug. Uma eventual migração de inventário antigo requer uma política administrativa de validação; não existe importação de saldo declarada pelo cliente.

## Referências utilizadas

- [Firebase Authentication com Play Games](https://firebase.google.com/docs/auth/android/play-games)
- [Play Games v2: acesso ao servidor](https://developer.android.com/games/pgs/android/server-access)
- [Firebase callable Functions](https://firebase.google.com/docs/functions/callable)
- [Remote Config no servidor](https://firebase.google.com/docs/remote-config/server)
- [AdMob Flutter: verificação de recompensas no servidor](https://developers.google.com/admob/flutter/ssv)
- [Compatibilidade Kotlin 2.3](https://kotlinlang.org/docs/whatsnew23.html)
