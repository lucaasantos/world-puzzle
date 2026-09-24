# Verificação da integração online — 16/09/2026

## Validação após alterações do Antigravity — 17/09/2026, 16:51

- Revisadas as alterações recentes em `home_screen.dart`, `player_screens.dart` e `game_screen.dart`; esta pasta não possui histórico Git para comparação exata.
- `flutter analyze lib test`: sem problemas.
- Quatro testes focados aprovados: novo painel/atalhos da home; home, perfil e exploração em tela pequena; movimentos ortogonais; troca de peça com espaço vazio.
- APK debug compilada com a configuração Firebase local e instalada com preservação dos dados no Moto G9 Power.
- Quinta verificação: abertura real concluída na nova tela principal, perfil `lucas`, nível 1 e energia 5. Captura em `build/device-validation-home.png`. Não foram encontrados erros Flutter, estouros de layout ou rejeição do App Check nos registros do processo nesta abertura.
- Nenhuma correção de código necessária nesta rodada. Partidas completas, anúncios e operações de inventário não foram exercitados no aparelho.

## Verificação no Moto G9 Power — 17/09/2026

A versão debug instalada autenticou no Firebase, mas a inicialização terminou em “Conexão necessária”. Os registros mostraram rejeição 403 do App Check (`App attestation failed`), mesmo com rede validada pelo Android. A lista de tokens de desenvolvimento do aplicativo estava vazia. O token gerado pelo próprio aparelho foi cadastrado no App Check com o nome “Moto G9 Power - desenvolvimento Lucas”; o valor secreto não é registrado neste documento. A exigência de App Check do backend foi mantida.

Depois de reiniciar, o aplicativo abriu o cadastro de perfil. O nickname `lucas`, escolhido pelo proprietário, foi criado e a tela inicial exibiu nível 1, 0/100 XP e 5/5 vidas. Partidas e operações de inventário ainda não foram verificadas nesta rodada.

A tela de abertura agora distingue erros de conexão de falhas de acesso e exibe a mensagem correspondente. Três testes focados cobrem `unauthenticated`, `permission-denied` e `unavailable`, incluindo recuperação pelo botão de nova tentativa; todos passaram. APK debug recompilada com a configuração Firebase local.

- `flutter analyze lib test`: sem problemas.
- `flutter test`: 50 testes aprovados, incluindo os 45 testes anteriores e cinco novos testes da integração/telas.
- `npm test --prefix functions`: seis testes de domínio aprovados (níveis, vidas, fronteira UTC, 81 combinações de dificuldades, probabilidades, movimentos e assinatura SSV).
- Firebase Emulator Suite, projeto `demo-puzzle-world`: teste integrado aprovado com autenticação, nickname único, regras, acesso entre contas, conclusão concorrente, resgate concorrente, abertura concorrente, duplicatas, colagem, regeneração e resgate de ciclo anterior.
- Compilação Android debug concluída. Kotlin foi atualizado para 2.3.10 e a configuração de compilação foi adaptada à versão exigida pelo Firebase Authentication atual.

Os testes integrados exercitam as Functions reais por HTTP, com Firestore e Authentication locais. Fixtures administrativas criam tabuleiros próximos da solução para o teste; o cliente normal não tem permissão de escrever esses dados.

Os resultados acima são da implementação inicial. Depois, as regras e os índices foram publicados no Firestore real em São Paulo; as Functions ainda não foram publicadas. Login Play Games real, Play Integrity, recebimento SSV real, entrega de Analytics e Remote Config publicado dependem da configuração das contas externas. iOS tem a interface de autenticação preparada, mas não um provedor funcional nesta etapa. A APK sem parâmetros mostra serviços online em preparação.

Nas próximas tarefas, a validação será limitada a até cinco testes focados, conforme solicitado pelo proprietário; a validação complementar será feita por ele no celular real.

Após configurar as credenciais reais do Play Games: APK debug recompilada com `--dart-define-from-file=config/firebase.local.json` e os cinco testes de `test/screens/online_flow_test.dart` aprovados. Login real, App Check no aparelho e economia do backend não foram validados por esses testes.

Na publicação de 17/09/2026, Cloud Build identificou `picomatch@4.0.7` ausente no lockfile. O lockfile foi sincronizado com npm 10.9.9, e `npm ci --dry-run` com essa versão passou. Foi configurado `disallowLegacyRuntimeConfig: true`, pois o backend usa Remote Config e não depende do antigo Runtime Config. Não reexecutar `npm install` com uma versão diferente sem verificar a compatibilidade do lockfile com o Cloud Build.

Publicação concluída das dez Functions em 17/09/2026. Duas verificações HTTP reais passaram após corrigir o acesso de transporte Cloud Run que havia ficado incompleto na primeira criação: callable sem credenciais retorna 401 JSON e SSV sem assinatura retorna 403 do código da função. Nenhum fluxo autenticado no aparelho foi validado nessa etapa.

A análise da raiz inteira também encontra avisos antigos nos backups da ferramenta de artes (cópias de pubspec sem assets ao lado). A verificação do aplicativo foi delimitada a `lib` e `test`; os backups não foram alterados.

A auditoria npm identificou avisos moderados em dependências transitivas da ferramenta/SDK (`gaxios`/`uuid` no relatório de produção), sem avisos altos ou críticos nessa árvore. As dependências diretas foram atualizadas e fixadas no lockfile. A chamada observada em gaxios usa UUID v4; o aviso se refere a operações com buffers em outras variantes. Reavaliar versões upstream antes da publicação.

O diário de uma partida é preservado em quedas de conexão; reenviar uma conclusão continua sujeito ao tempo, movimentos e validade da tentativa verificados pelo servidor. Progresso local antigo permanece preservado, sem importação automática de inventário para a conta online.
