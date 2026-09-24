# Firebase — projeto vinculado

- Projeto: `puzzle-world-a7b7d`.
- App Android cadastrado: `Puzzle World`.
- Package: `com.puzzlejourney.puzzle_journey`.
- Firebase App ID: `1:188944842485:android:a070f48d46c83dd0bd8fbc`.
- Configuração baixada em `android/app/google-services.json` e incorporada a `config/firebase.local.json` (inicialização explícita existente).
- `.firebaserc` aponta para o projeto real. Os comandos de emulador continuam exigindo `--project demo-puzzle-world`.

A API Cloud Firestore foi ativada e o banco `(default)` foi criado em 16/09/2026, na edição Standard e modo nativo. As Security Rules do jogo foram compiladas e publicadas com sucesso: leituras restritas à própria conta e escritas econômicas diretas negadas.

Região corrigida e confirmada: `southamerica-east1` (São Paulo). Após confirmar que o banco anterior estava vazio e receber autorização do proprietário, o banco em `nam5` foi excluído e recriado em São Paulo em 16/09/2026. Não havia dados para migrar. As regras e os índices foram publicados novamente com sucesso. `firebase.json` registra explicitamente a localização para evitar criação em uma região implícita.

Os certificados SHA-1 e SHA-256 da assinatura Android de debug também foram cadastrados e confirmados. As dez Functions foram publicadas e confirmadas ACTIVE em São Paulo em 17/09/2026. App Check está registrado; o token de debug do aparelho e o AdMob permanecem pendentes.

O backend da economia já está publicado. O fluxo completo ainda precisa ser validado no aparelho com o token de debug do App Check registrado.

O proprietário ativou o Blaze, e a API Cloud Billing confirmou `billingEnabled: true`. Publicação concluída. A limpeza de imagens de compilação foi configurada para um dia. Consulte [a lista de ativação](ONLINE_ACTIVATION_CHECKLIST.md) para as dependências restantes.

A identidade OAuth foi criada no Google Auth Platform: nome Puzzle World, público externo em modo de testes e contato de suporte do proprietário. Os clientes OAuth Android e servidor foram criados e vinculados no Play Games. A tela de consentimento ainda não foi publicada; revisar escopos e usuários de teste antes de validar login real.

Firebase Authentication inicializado pelo console em 16/09/2026. O provedor Play Games foi salvo e confirmado como ativado. O segredo foi enviado somente ao formulário do provedor Firebase, sem ser gravado no código ou na APK. A APK debug foi recompilada com sucesso, incluindo o projeto real, ID Play Games e Web Client ID. O fluxo completo ainda depende do token de debug do App Check e do teste no aparelho.

Puzzle World cadastrado no Google Play Console como jogo gratuito, idioma pt-BR, pacote `com.puzzlejourney.puzzle_journey`. ID do app no console: `4975410656901525132`. Cadastro concluído com as declarações autorizadas pelo proprietário; nenhuma versão foi enviada ou publicada. O projeto Play Games foi criado no mesmo Google Cloud `puzzle-world-a7b7d`, com ID `188944842485`, após o aceite autorizado dos termos. Esse ID foi configurado no Android. A conta do proprietário já consta como testadora do Play Games.

Clientes OAuth públicos:
- Android debug: `188944842485-1eq07lq2r0f97upd8m0695v47e802mem.apps.googleusercontent.com`.
- Servidor: `188944842485-rgoadr2rag3dvvv6ab1mqc5pdukoipv9.apps.googleusercontent.com`.

A conta do proprietário também foi adicionada e confirmada como usuária de teste OAuth (1 usuário de teste). O projeto permanece em testes.

App Check registrado com Play Integrity, SHA-256 de debug e duração de token de uma hora, após aceite autorizado dos termos. O console confirmou o status Registrado. Token de debug do aparelho e certificado de distribuição permanecem pendentes; nenhum aparelho foi detectado pelo ADB nesta verificação.

Após uma primeira criação incompleta, o acesso HTTP dos dez serviços Cloud Run foi corrigido para o padrão das funções Firebase callable/HTTP. Isso permite chegar ao código; Auth e App Check continuam exigidos pelas callables, e o callback de anúncios exige SSV. Verificação real: `syncPlayer` sem credenciais retornou 401 JSON `UNAUTHENTICATED`; `admobReward` sem assinatura retornou 403 `Reward verification failed`. Nenhum usuário, saldo ou recompensa foi criado por essas verificações.

URL SSV para configuração futura no AdMob: `https://admobreward-6vai3wxcja-rj.a.run.app`. A lista de unidades autorizadas permanece vazia até configurar anúncios reais.
