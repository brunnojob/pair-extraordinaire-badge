# Git Collaboration Audit

Auditoria de histórico Git, autores, trailers de coautoria, mudanças de arquivos e colaboração associada a alterações substantivas.

## Executar

Requisitos: Python 3.11+ e Git.

```sh
python main.py . --limit 200 > resultado.json
```

## Funcionamento

Leitura do histórico existente. Trailers inválidos são apresentados no relatório. Arquivos de automação de badges e logs artificiais são excluídos da contagem de mudanças substantivas.

## Persistência de resultados

O arquivo de operações está em [vercel-home-telemetry-api.vercel.app](https://vercel-home-telemetry-api.vercel.app/laboratory.html?project=pair-extraordinaire-badge). As migrações Supabase estão no [repositório da API](https://github.com/brunnojob/vercel-home-telemetry-api/tree/main/supabase/migrations).

```sh
python cloud/sync.py enqueue resultado.json --project pair-extraordinaire-badge
python cloud/sync.py sync
```

Defina `BRUNNODEV_ACCESS_TOKEN` com sua sessão. A fila SQLite conserva os relatórios até confirmação do servidor; o mesmo conteúdo não gera registros duplicados. Tokens não são gravados no código.
