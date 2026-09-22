# Lab 01 – EC2 Basics

## Configurazione istanza

| Parametro        | Valore                          | Motivazione                                                  |
|------------------|---------------------------------|--------------------------------------------------------------|
| Name             | demo-web-01                     | Identificazione coerente con il Demo 01                      |
| AMI              | Amazon Linux 2023 (Free tier)   | Immagine AWS ufficiale, aggiornata, supportata nel Learner Lab |
| Instance type    | t3.micro                        | Sufficiente per basso traffico, sotto il limite .large del lab |
| Key pair         | demo-key (RSA, .pem)            | Necessaria per accesso SSH                                   |
| Security Group   | demo-sg-web                     | Regole minime: SSH da My IP, HTTP da 0.0.0.0/0               |
| Storage          | 8 GiB, gp3                      | Default, nessun costo aggiuntivo                             |

## Security Group – regole inbound

| Tipo | Porta | Sorgente     |
|------|-------|--------------|
| SSH  | 22    | `var.my_ip`  |
| HTTP | 80    | 0.0.0.0/0    |

## Utilizzo

```bash
# 1. Inizializza
terraform init

# 2. Applica passando le variabili obbligatorie
terraform apply \
  -var="ami_id=<ami-xxxxxxxxxxxxxxxxx>" \
  -var="my_ip=<YOUR_PUBLIC_IP>/32"

# 3. Recupera l'IP pubblico dall'output
terraform output public_ip

# 4. Connessione SSH
chmod 400 demo-key.pem
ssh -i demo-key.pem ec2-user@<public_ip>

# 5. Termina le risorse
terraform destroy \
  -var="ami_id=<ami-xxxxxxxxxxxxxxxxx>" \
  -var="my_ip=<YOUR_PUBLIC_IP>/32"
```

> Per trovare l'AMI ID corrente di Amazon Linux 2023 in us-east-1:  
> EC2 → AMI Catalog → cerca "Amazon Linux 2023" → copia l'AMI ID.

## Evidenza SSH

```
ssh -i demo-key.pem ec2-user@<public_ip>

   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
  ~~     \###|       Kernel ...
  ~~       \#/ ___
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'
[ec2-user@ip-xxx-xxx-xxx-xxx ~]$
```

## Note di scelta

- **t3.micro** è il tipo più economico con supporto a burst CPU, adatto a un web server a basso traffico e compatibile con i limiti del Learner Lab (max `.large`).
- **Amazon Linux 2023** è l'AMI raccomandata da AWS per nuovi workload: aggiornamenti di sicurezza frequenti e integrazione nativa con i tool AWS.
- **SSH ristretto a My IP** riduce la superficie di attacco rispettando il principio del minimo privilegio.
