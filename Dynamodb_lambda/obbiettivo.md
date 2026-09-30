### Dynamodb && Lambda

## Creare una tabella DynamoDB con chiave composta per gestire ordini (customer_id + order_date), inserire dati, eseguire Query e Scan, e integrare con una funzione Lambda CRUD.

Table name: prova01-orders
Partition key: customer_id (String)
Sort key: order_date (String)
Table settings: Default settings (on-demand)

Struttura di un oggetto DynamoDB:

{
  "customer_id": "C001",
  "order_date": "2025-01-15",
  "product": "Laptop",
  "quantity": 1,
  "total": 999.99
}

Campi minimi richiesti per una richiesta GET:

{
  "action": "get",
  "customer_id": "C001",
  "order_date": "2025-01-15"
}

Campi minimi richiesti per una richiesta POST (creazione ordine):

{
  "action": "create",
  "item": {
    "customer_id": "C003",
    "order_date": "2025-04-01",
    "product": "Headset",
    "quantity": 2,
    "total": 129.99
  }
}

Contenuto base tabella:

| customer_id | order_date | product  | quantity | total  |
| ----------- | ---------- | -------- | -------- | ------ |
| C001        | 2025-01-15 | Laptop   | 1        | 999.99 |
| C001        | 2025-02-20 | Mouse    | 2        | 49.98  |
| C001        | 2025-03-10 | Keyboard | 1        | 79.99  |
| C002        | 2025-01-22 | Monitor  | 1        | 349.99 |
| C002        | 2025-03-05 | Webcam   | 1        | 89.99  |

Lambda:
Function name: orders-crud
Runtime: Python 3.12, Role: LabRole
Aggiungi environment variable: TABLE_NAME = prova01-orders

Best practice:
- Non inserire credenziali AWS o dati reali nel repository.
- Gestire valori come nome tabella, nome Lambda e dati iniziali tramite variabili o file esterni.
- Se il JSON rappresenta un dataset reale o sensibile, non deve essere pubblicato in Git.

## per il deploy

### PowerShell

cd "c:/Users/janice.brun/Desktop/Iaac/Dynamodb_lambda"
terraform init
terraform plan
terraform apply

$env:TABLE_NAME = 'prova01-orders'
python .\scripts\insert_orders.py --insert --file .\data\orders.json

### Bash / Git Bash

cd "/c/Users/janice.brun/Desktop/Iaac/Dynamodb_lambda"
terraform init
terraform plan
terraform apply

export TABLE_NAME=prova01-orders
python ./scripts/insert_orders.py --insert --file ./data/orders.json