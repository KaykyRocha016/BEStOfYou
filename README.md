# GymLog

GymLog e um aplicativo Flutter para registrar e acompanhar treinos de musculacao com armazenamento local em SQLite.

## Requisitos da Avaliacao 3

- Lista principal exibindo os treinos cadastrados.
- Cada treino possui pelo menos 3 informacoes.
- Tela para cadastrar um novo treino.
- Tela para exibir os detalhes de um treino selecionado.
- Confirmacao antes de excluir um treino.
- Persistencia local com SQLite.

## Dependencias usadas

- `sqflite`
- `sqflite_common_ffi`
- `path`
- `intl`

## Como rodar

Com o Flutter instalado em `C:\flutter`, rode:

```powershell
cd C:\Users\kayky\OneDrive\Documentos\BEStOfYou
& C:\flutter\bin\flutter.bat create .
& C:\flutter\bin\flutter.bat pub get
& C:\flutter\bin\flutter.bat run
```

Se o `flutter create .` perguntar sobre sobrescrever arquivos, mantenha os arquivos atuais do projeto, principalmente `lib/main.dart`, `pubspec.yaml`, `analysis_options.yaml` e `README.md`.

No FlutLab, execute no emulador Android. O preview web nao e indicado para este projeto porque a proposta exige SQLite local com `sqflite`.
