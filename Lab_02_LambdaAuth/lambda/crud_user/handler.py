import json
import os
import boto3
from boto3.dynamodb.conditions import Key

TABLE = os.environ["TABLE_NAME"]
_db = boto3.resource("dynamodb")
table = _db.Table(TABLE)


def respond(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def handler(event, context):
    method = event["httpMethod"]
    params = event.get("pathParameters") or {}
    user_id = params.get("id")
    body = json.loads(event["body"]) if event.get("body") else {}

    if method == "GET" and not user_id:
        result = table.scan()
        return respond(200, result["Items"])

    if method == "GET" and user_id:
        result = table.get_item(Key={"userId": user_id})
        item = result.get("Item")
        return respond(200, item) if item else respond(404, {"error": "Not found"})

    if method == "POST":
        if "userId" not in body:
            return respond(400, {"error": "userId required"})
        table.put_item(Item=body)
        return respond(201, body)

    if method == "PUT" and user_id:
        body["userId"] = user_id
        table.put_item(Item=body)
        return respond(200, body)

    if method == "DELETE" and user_id:
        table.delete_item(Key={"userId": user_id})
        return respond(200, {"deleted": user_id})

    return respond(405, {"error": "Method not allowed"})
