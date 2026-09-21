import json
import os
import re
import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
table = boto3.resource("dynamodb").Table(TABLE_NAME)

HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
}

# Accetta solo userId alfanumerici con trattini, max 64 caratteri
_ID_RE = re.compile(r'^[a-zA-Z0-9\-]{1,64}$')


def _valid_id(user_id):
    return isinstance(user_id, str) and bool(_ID_RE.match(user_id))


def _valid_body(body):
    return isinstance(body, dict)


def respond(status, body):
    return {
        "statusCode": status,
        "headers": HEADERS,
        "body": json.dumps(body),
    }


def handler(event, context):
    method = event["httpMethod"]
    params = event.get("pathParameters") or {}
    user_id = params.get("id")
    raw_body = event.get("body") or "{}"

    try:
        body = json.loads(raw_body)
    except (ValueError, TypeError):
        return respond(400, {"error": "Invalid JSON body"})

    try:
        if method == "GET" and not user_id:
            return list_users()

        if method == "GET" and user_id:
            return get_user(user_id)

        if method == "POST":
            return create_user(body)

        if method == "PUT" and user_id:
            return update_user(user_id, body)

        if method == "DELETE" and user_id:
            return delete_user(user_id)

        return respond(405, {"error": "Method not allowed"})

    except Exception as e:
        return respond(500, {"error": str(e)})


def get_user(user_id):
    if not _valid_id(user_id):
        return respond(400, {"error": "Invalid userId format"})
    result = table.get_item(Key={"userId": user_id})
    item = result.get("Item")
    return respond(200, item) if item else respond(404, {"error": "User not found"})


def list_users():
    result = table.scan(Limit=50)
    return respond(200, {"users": result.get("Items", [])})


def create_user(body):
    if not _valid_body(body):
        return respond(400, {"error": "Invalid body"})
    if "userId" not in body or not _valid_id(body["userId"]):
        return respond(400, {"error": "Valid userId is required"})
    if "name" not in body or not isinstance(body["name"], str):
        return respond(400, {"error": "Valid name is required"})
    # Whitelist dei campi accettati
    item = {
        "userId": body["userId"],
        "name": body["name"][:256],
        "email": str(body.get("email", ""))[:256],
    }
    table.put_item(Item=item)
    return respond(201, item)


def update_user(user_id, body):
    if not _valid_id(user_id):
        return respond(400, {"error": "Invalid userId format"})
    if not _valid_body(body):
        return respond(400, {"error": "Invalid body"})
    item = {
        "userId": user_id,
        "name": str(body.get("name", ""))[:256],
        "email": str(body.get("email", ""))[:256],
    }
    table.put_item(Item=item)
    return respond(200, item)


def delete_user(user_id):
    if not _valid_id(user_id):
        return respond(400, {"error": "Invalid userId format"})
    table.delete_item(Key={"userId": user_id})
    return respond(200, {"deleted": user_id})
