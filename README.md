# Puzzle World

Jogo mobile de sliding puzzles feito em Flutter e Dart, com economia online no Firebase. Android é a primeira plataforma; modelos e serviços permitem adicionar autenticação iOS futuramente.

**A configuração externa ainda precisa ser criada.** Consulte [o guia de Firebase, Play Games, AdMob e emuladores](docs/FIREBASE_SETUP.md). Sem configuração, o aplicativo mostra a tela de preparação dos serviços e não libera uma economia local fictícia.

## Executar

```bash
flutter pub get
flutter run
```

Para gerar um APK de desenvolvimento:

```bash
flutter build apk --debug
```

## Conteúdo e expansão

Os temas ficam configurados em `lib/data/themes_data.dart`: Japão, Egito, Grécia e Brasil. O Brasil reutiliza artes existentes das cartas. Para adicionar uma coleção:

1. crie `assets/images/themes/<id>/`;
2. adicione quatro puzzles quadrados (`<id>_01.webp` até `<id>_04.webp`) e um wallpaper WebP;
3. inclua a pasta no `pubspec.yaml`;
4. adicione um `GameTheme` à configuração central.

As referências de imagens não ficam espalhadas pelas telas. Cada `PuzzleLevel` define tamanho da grade, vidas e limites de tempo, movimentos e estrelas, então o número e a dificuldade das fases são configuráveis. O tema Japão usa `japan_01.webp` também como imagem de capa.

## Álbum e pacotes

Definições de cartas e pacotes continuam no catálogo existente. O script `dart run tools/export_backend_catalog.dart` exporta os mesmos IDs para as Functions; rode-o quando mudar o catálogo. Quantidades, duplicatas, álbum e pacotes online são autoritativos no Firestore.

Concluir uma partida concede XP validado. A Exploração Diária exige quatro países distintos e entrega exatamente um pacote por ciclo. As dificuldades melhoram a tabela de probabilidades desse pacote. Sorteios e abertura econômica ocorrem no backend; a animação existente apresenta o resultado.

Ferramentas de concessão local de debug permanecem apenas para testes do caminho legado e ficam bloqueadas em qualquer conta online, inclusive em debug.

## Serviços

- Conta: Firebase UID, Play Games v2 no Android, onboarding de nickname único e avatar.
- Economia: Cloud Functions, transações Firestore, regras restritivas e App Check.
- Partida em andamento: diário de movimentos por UID em `SharedPreferences`; conclusão revalidada pelo backend.
- XP, nível, vidas e exploração: configuração central com Remote Config de servidor e defaults seguros.
- Wallpaper: adaptador isolado em `WallpaperService`, usando MediaStore no Android.
- Anúncios: Rewarded com SSV e Interstitial configurável; IDs de teste somente como default em debug.
- Áudio: pontos de integração silenciosos até a inclusão de arquivos licenciados.
- Vibração: serviço isolado e controlado pelas configurações.

Antes de publicar, substitua os IDs de teste do AdMob e configure assinatura/release no Android.

## Testes

```bash
flutter analyze lib test
flutter test
npm test --prefix functions
```

A suíte cobre engine, pontuação, progressão, álbum, persistência, abertura visual, telas online, validação de configuração, XP, reset UTC, combinações de exploração e assinaturas SSV. O guia descreve também o teste integrado com Firebase Emulator Suite para permissões e idempotência concorrente.
# Ferramenta interna de artes das cartas

Geração independente, revisão manual e aplicação de WebP: consulte
[tools/card-image-generator/README.md](tools/card-image-generator/README.md).
A ferramenta não participa da execução do jogo nem adiciona dependências Flutter.
