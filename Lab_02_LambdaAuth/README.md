# Lab 02 – Lambda Auth: CRUD API con Authorizer

API REST multi-risorsa su API Gateway, protetta da un Lambda authorizer TOKEN, con backend CRUD su DynamoDB. Tutto deployato via Terraform su AWS Academy Learner Lab.

---

## Architettura

```
Client
  │
  │  Authorization: Bearer <token>
  ▼
API Gateway (lab02-api)
  │
  ├─► Lambda: simple-authorizer  ──► Allow / Deny
  │         (valida il token)
  │
  └─► Lambda: crud-user  ──► DynamoDB (lab02-users)
        (GET / POST / PUT / DELETE)
```

Ogni richiesta in arrivo viene prima intercettata da `simple-authorizer`. Solo se il token è valido, API Gateway inoltra la chiamata a `crud-user`.

---

## Struttura file

```
Lab_02_LambdaAuth/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars          ← gitignored
├── .gitignore
└── lambda/
    ├── crud_user/
    │   └── handler.py
    └── simple_authorizer/
        └── handler.py
```

---

## Descrizione file

### `variables.tf`

Dichiara le tre variabili di input:

| Variabile     | Tipo   | Default    | Sensibile | Descrizione                                      |
|---------------|--------|------------|-----------|--------------------------------------------------|
| `region`      | string | us-east-1  | no        | Regione AWS di deploy                            |
| `lab_role_arn`| string | —          | no        | ARN del ruolo `LabRole` pre-esistente nel Learner Lab |
| `auth_token`  | string | —          | **sì**    | Token Bearer validato dall'authorizer            |

`lab_role_arn` e `auth_token` non hanno default: Terraform li richiede obbligatoriamente da `terraform.tfvars`, che è escluso dal repository.

---

### `main.tf`

Contiene tutte le risorse AWS, nell'ordine:

**DynamoDB**
- Tabella `lab02-users` con chiave primaria `userId` (stringa), billing `PAY_PER_REQUEST` (nessun costo fisso).

**Lambda packages**
- Due `archive_file` data source che zippano i file Python in `.build/` prima del deploy. Il campo `source_code_hash` garantisce che Terraform aggiorni la Lambda solo se il codice è cambiato.

**Lambda: `crud-user`**
- Runtime Python 3.12, usa `LabRole` come execution role.
- Riceve `TABLE_NAME` come variabile d'ambiente (non hardcoded).

**Lambda: `simple-authorizer`**
- Runtime Python 3.12, usa `LabRole`.
- Riceve `AUTH_TOKEN` come variabile d'ambiente sensibile.

**API Gateway**
- REST API `lab02-api`.
- Authorizer di tipo `TOKEN` collegato a `simple-authorizer`, TTL cache = 0 (utile in fase di test).
- Due `aws_lambda_permission` per autorizzare API Gateway a invocare entrambe le Lambda.
- Risorse: `/users` e `/users/{id}`.
- 5 metodi (list, create, get, update, delete) definiti tramite `for_each` su una mappa locale `routes`, tutti protetti dall'authorizer.
- 5 integrazioni `AWS_PROXY` verso `crud-user`.
- Deployment con trigger di redeployment automatico basato su hash dei metodi e integrazioni.
- Stage `v1`.

---

### `outputs.tf`

| Output                 | Descrizione                                  |
|------------------------|----------------------------------------------|
| `api_base_url`         | URL base dell'API (già con `/users` in coda) |
| `crud_user_arn`        | ARN della Lambda crud-user                   |
| `simple_authorizer_arn`| ARN della Lambda simple-authorizer           |

---

### `terraform.tfvars` *(gitignored)*

File locale con i valori delle variabili obbligatorie. Non viene mai committato.

```hcl
lab_role_arn = "arn:aws:iam::<ACCOUNT_ID>:role/LabRole"
auth_token   = "<SCEGLI_UN_TOKEN_SEGRETO>"
```

L'`ACCOUNT_ID` si trova in alto a destra nella console AWS.

---

### `lambda/crud_user/handler.py`

Gestisce le 5 operazioni CRUD sulla tabella DynamoDB:

| Metodo HTTP | Path        | Operazione DynamoDB  | Risposta  |
|-------------|-------------|----------------------|-----------|
| GET         | /users      | `scan`               | 200 + lista|
| GET         | /users/{id} | `get_item`           | 200 / 404 |
| POST        | /users      | `put_item`           | 201       |
| PUT         | /users/{id} | `put_item`           | 200       |
| DELETE      | /users/{id} | `delete_item`        | 200       |

Il nome della tabella viene letto da `os.environ["TABLE_NAME"]`, iniettato da Terraform.

---

### `lambda/simple_authorizer/handler.py`

Lambda authorizer di tipo TOKEN per API Gateway. Confronta il valore dell'header `Authorization` con `Bearer <AUTH_TOKEN>`:

- **Match** → restituisce una policy IAM con `Effect: Allow`
- **No match** → restituisce una policy IAM con `Effect: Deny`

API Gateway esegue o blocca la richiesta in base all'effetto ricevuto.

---

### `.gitignore`

Esclude dal repository:
- `terraform.tfvars` e `*.tfvars` — contengono segreti e ARN specifici dell'ambiente
- `.terraform/` — provider binari scaricati localmente
- `terraform.tfstate` e backup — contengono lo stato dell'infrastruttura (può includere valori sensibili)
- `.build/` — artefatti ZIP delle Lambda generati da Terraform
- `__pycache__/` e `*.pyc` — cache Python

---

## Workflow di deploy

```
1. terraform init
      │
      └─► scarica provider AWS, crea .terraform/

2. Compila terraform.tfvars
      │
      └─► inserisci lab_role_arn e auth_token

3. terraform plan
      │
      └─► anteprima delle risorse che verranno create

4. terraform apply
      │
      ├─► crea tabella DynamoDB lab02-users
      ├─► zippa i due handler Python in .build/
      ├─► crea Lambda crud-user e simple-authorizer
      ├─► crea API Gateway con authorizer, risorse, metodi, integrazioni
      └─► stampa gli output (api_base_url, ARN)

5. Test (vedi sezione sotto)

6. terraform destroy
      └─► rimuove tutte le risorse create
```

---

## Test dell'API

Sostituisci `<BASE_URL>` con il valore di `api_base_url` e `<TOKEN>` con il valore scelto in `terraform.tfvars`.

```bash
# Lista tutti gli utenti
curl -H "Authorization: Bearer <TOKEN>" <BASE_URL>

# Crea un utente
curl -X POST \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"userId":"u1","name":"Mario Rossi"}' \
  <BASE_URL>

# Leggi un utente
curl -H "Authorization: Bearer <TOKEN>" <BASE_URL>/u1

# Aggiorna un utente
curl -X PUT \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"name":"Mario Bianchi"}' \
  <BASE_URL>/u1

# Elimina un utente
curl -X DELETE -H "Authorization: Bearer <TOKEN>" <BASE_URL>/u1

# Richiesta senza token → 403 Forbidden
curl <BASE_URL>
```

---

## Note di sicurezza

- `auth_token` è marcato `sensitive = true` in Terraform: non appare nell'output di `plan` e `apply`.
- Il token viaggia in chiaro su HTTPS — sufficiente per un lab, in produzione valutare Cognito o JWT firmati.
- La Lambda authorizer ha `authorizer_result_ttl_in_seconds = 0`: nessuna cache, ogni richiesta viene rivalutata. In produzione aumentare il TTL per ridurre le invocazioni.
- Il code review ha rilevato due categorie di finding da tenere presenti in un contesto produttivo:
  - **NoSQL Injection** (`handler.py` righe 29-46): `userId` e il body della richiesta vengono passati direttamente a DynamoDB senza validazione esplicita del tipo. In produzione aggiungere validazione e sanitizzazione dell'input.
  - **DynamoDB PITR disabilitato** (`main.tf`): il Point-In-Time Recovery non è attivo. In produzione abilitarlo con `point_in_time_recovery { enabled = true }`.
