# Pendências para disponibilizar o Puzzle World online

Projeto: `puzzle-world-a7b7d`. Atualizado em 17/09/2026.

## Já feito

- Aplicativo Android cadastrado no Firebase.
- Configuração pública do Firebase salva no projeto.
- Certificados SHA-1 e SHA-256 de debug registrados.
- Firestore Standard em São Paulo (`southamerica-east1`), com regras e índices publicados.
- Firebase Authentication com provedor Play Games ativado; credenciais Android/servidor criadas e vinculadas no Play Games.
- Puzzle World cadastrado no Play Console como jogo gratuito em pt-BR; nenhuma versão publicada.
- Código das Functions, regras, XP, vidas, perfil, exploração, coleção e álbum implementado e testado localmente.
- Nenhuma importação de inventário local sem validação administrativa.

## Próximos passos, na ordem

1. **Faturamento do Firebase — concluído.** O proprietário ativou o Blaze e a API confirmou `billingEnabled: true`. Functions publicadas. Acompanhar consumo no console.
2. **Play Games.** Projeto, credenciais e provedor Firebase configurados; IDs públicos incorporados à APK. A conta do proprietário já é testadora do Play Games. Revisar escopos e usuários de teste OAuth e validar login no aparelho. Publicação OAuth/Play Games e certificado de distribuição ficam para o lançamento.
3. **App Check.** App Android registrado com Play Integrity e SHA-256 de debug. Cadastrar o token de debug gerado no aparelho para os primeiros testes. As Functions exigem App Check em produção. Adicionar o certificado de distribuição antes do lançamento.
4. **Backend publicado.** Dez Functions ACTIVE em `southamerica-east1`. Verificações reais confirmaram rejeição de chamada sem autenticação e recompensa sem assinatura. Falta testar login → perfil → quatro países → pacote → coleção → álbum no aparelho, após registrar seu token App Check.
5. **AdMob.** Criar app e unidades rewarded/interstitial; informar os IDs e configurar a URL SSV de `admobReward` e a lista de unidades autorizadas no backend. Validar recompensas assinadas reais de energia e World Coin. O botão/callback local não concede economia sozinho.
6. **Remote Config e Analytics.** Publicar `economy_json` no template de servidor caso deseje mudar os defaults; confirmar os eventos no Firebase. A ausência de Remote Config publicado mantém os defaults e não deve impedir a economia.
7. **APK de teste conectado.** Finalizar a configuração nativa Firebase/Play Games/AdMob e gerar uma nova APK com `config/firebase.local.json`. A APK anterior não inclui automaticamente valores adicionados depois da compilação. Validar num Android físico; antes de distribuição, configurar assinatura de release e certificados da Play Store.

O principal trabalho restante é a configuração dos serviços e os testes reais. Não é necessário reconstruir o puzzle, catálogo, pacotes, coleção ou álbum.

Referências:

- [Publicação de Cloud Functions e plano Blaze](https://firebase.google.com/docs/functions/get-started)
- [Autenticação Play Games com Firebase](https://firebase.google.com/docs/auth/android/play-games)
- [Verificação SSV do AdMob](https://developers.google.com/admob/flutter/ssv)
