import boto3
import json
import os

# Get the DynamoDB table name from environment variable
dynamodb_table_name = os.environ.get('DYNAMODB_TABLE_NAME')

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(dynamodb_table_name)


def lambda_handler(event, context):
    """
    Lambda function to persist and retrieve data from a DynamoDB table.

    Args:
        event (dict): The event data passed to the Lambda function.  This should contain
                      an 'action' key ('persist' or 'get').  For 'persist', it should also
                      contain the data to be saved.  For 'get', it should contain the key
                      to retrieve the item.
        context (object): Lambda context object (not used in this example).

    Returns:
        dict: A dictionary containing the status code and a message/data.
    """

    try:
        if 'action' not in event:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Missing "action" key in event.'})
            }

        action = event['action']

        if action == 'persist':
            if 'data' not in event:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'Missing "data" key in event for persist action.'})
                }
            data = event['data']
            table.put_item(Item=data)
            return {
                'statusCode': 201,  # Created
                'body': json.dumps({'message': 'Item persisted successfully.'})
            }

        elif action == 'get':
            if 'id' not in event:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'Missing "id" key in event for get action.'})
                }
            key = {'id': event['id']}  # Assuming 'id' is the partition key
            item = table.get_item(Key=key)
            if 'Item' in item:
                return {
                    'statusCode': 200,
                    'body': json.dumps(item['Item'])
                }
            else:
                return {
                    'statusCode': 404,
                    'body': json.dumps({'message': 'Item not found.'})
                }

        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Invalid action.  Must be "persist" or "get".'})
            }

    except Exception as e:
        print(f"Error: {e}")  # Log the error for debugging
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'An error occurred.'})
        }