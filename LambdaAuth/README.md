# Lab 02 – Lambda Auth: CRUD API con Authorizer

API REST su API Gateway, protetta da Lambda authorizer TOKEN, con backend CRUD su DynamoDB. Deploy via Terraform su AWS Academy Learner Lab.

---

## Architettura

```
Client
  │  Authorization: Bearer <token>
  ▼
API Gateway (lab02-api)
  ├─► simple-authorizer  ──► Allow / Deny
  └─► crud-user  ──► DynamoDB (lab02-users)
```

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
    ├── crud_user/handler.py
    └── simple_authorizer/handler.py
```

---

## Variabili (`variables.tf`)

| Variabile     | Default   | Sensibile | Descrizione                        |
|---------------|-----------|-----------|------------------------------------|
| `region`      | us-east-1 | no        | Regione AWS                        |
| `lab_role_arn`| —         | no        | ARN del ruolo `LabRole` del Learner Lab |
| `auth_token`  | —         | **sì**    | Token Bearer validato dall'authorizer |

`lab_role_arn` e `auth_token` sono obbligatori via `terraform.tfvars` (gitignored).

---

## Risorse (`main.tf`)

- **DynamoDB** — tabella `lab02-users`, chiave `userId`, billing `PAY_PER_REQUEST`
- **Lambda `crud-user`** — Python 3.12, riceve `TABLE_NAME` da env
- **Lambda `simple-authorizer`** — Python 3.12, riceve `AUTH_TOKEN` da env
- **API Gateway** — REST API con authorizer TOKEN, risorse `/users` e `/users/{id}`, 5 metodi via `for_each`, integrazioni `AWS_PROXY`, stage `v1`

---

## Lambda `crud_user/handler.py`

| Metodo | Path        | DynamoDB      | Status  |
|--------|-------------|---------------|---------|
| GET    | /users      | `scan`        | 200     |
| GET    | /users/{id} | `get_item`    | 200/404 |
| POST   | /users      | `put_item`    | 201     |
| PUT    | /users/{id} | `put_item`    | 200     |
| DELETE | /users/{id} | `delete_item` | 200     |

Modifiche rispetto al codice originale:
- `lambda_handler` → `handler` (coerente con `main.tf`)
- tabella non più hardcoded: legge `os.environ["TABLE_NAME"]`
- aggiunto handler `PUT` (mancante nell'originale)
- validazione `userId` con regex `^[a-zA-Z0-9\-]{1,64}$` prima di ogni operazione DynamoDB (fix NoSQL Injection)
- whitelist campi in `put_item`: solo `userId`, `name`, `email` con troncamento a 256 caratteri

---

## Lambda `simple_authorizer/handler.py`

Confronta `Authorization` header con `Bearer <AUTH_TOKEN>` e restituisce policy `Allow` o `Deny`.

Modifiche rispetto al codice originale:
- `lambda_handler` → `handler`
- token non più hardcoded: legge `os.environ["AUTH_TOKEN"]`

---

## Output (`outputs.tf`)

| Output                  | Descrizione                     |
|-------------------------|---------------------------------|
| `api_base_url`          | URL base + `/users`             |
| `crud_user_arn`         | ARN Lambda crud-user            |
| `simple_authorizer_arn` | ARN Lambda simple-authorizer    |

---

## Deploy

```bash
# 1. Compila terraform.tfvars
lab_role_arn = "arn:aws:iam::<ACCOUNT_ID>:role/LabRole"
auth_token   = "<TOKEN>"

# 2. Deploy
terraform init && terraform apply

# 3. Cleanup
terraform destroy
```

---

## Test

```bash
BASE_URL=$(terraform output -raw api_base_url)
TOKEN="<TOKEN>"

curl -H "Authorization: Bearer $TOKEN" $BASE_URL
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
     -d '{"userId":"u1","name":"Mario Rossi"}' $BASE_URL
curl -H "Authorization: Bearer $TOKEN" $BASE_URL/u1
curl -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
     -d '{"name":"Mario Bianchi"}' $BASE_URL/u1
curl -X DELETE -H "Authorization: Bearer $TOKEN" $BASE_URL/u1
curl $BASE_URL  # → 403 Forbidden
```

---

## Note di sicurezza

- `auth_token` è `sensitive = true`: non appare nei log di `plan`/`apply`
- `authorizer_result_ttl_in_seconds = 0`: nessuna cache del token, ogni richiesta viene rivalutata
- **DynamoDB PITR disabilitato**: in produzione abilitare con `point_in_time_recovery { enabled = true }`
