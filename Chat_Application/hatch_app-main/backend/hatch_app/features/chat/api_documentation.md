# Get Recent Direct Messages
**URL:** `/api/chat/direct-messages/recent/`  
**Method:** `GET`  
**Description:** Retrieves the latest direct messages (1-on-1 chats) for the authenticated user. (For chat screen)

#### Input Parameters:
- None

#### Responses:
- **200 OK:** List of recent direct messages.
  ```json
  [
      {
          "channel_id": 1,
          "channel_name": "John and Jane",
          "latest_message": "Hello, how are you?",
          "latest_sender": "John Doe",
          "timestamp": "2023-10-01T12:00:00Z"
      },
      {
          "channel_id": 2,
          "channel_name": "John and Alice",
          "latest_message": "See you tomorrow!",
          "latest_sender": "Alice Smith",
          "timestamp": "2023-10-01T11:00:00Z"
      }
  ]
  ```
- **403 Forbidden:** User is not authenticated.

---
# List Buckets (Organizations) of the User
**URL:** `/api/chat/buckets/`  
**Method:** `GET`  
**Description:** Retrieves all buckets (organizations) the authenticated user is a part of, along with the member count and optional bucket icons.

#### Input Parameters:
- None

#### Responses:
- **200 OK:** List of buckets with additional metadata.
  ```json
  [
      {
          "id": 1,
          "name": "Development Team",
          "member_count": 10,
      },
      {
          "id": 2,
          "name": "Marketing Team",
          "member_count": 8,
      }
  ]
  ```
- **403 Forbidden:** User is not authenticated.

---
# Create Bucket
url = "/api/chat/buckets/create/"
method = "POST"
request = {
    "name" : 
}
//In case of success
response = {
    "id": ,
    "name": ,
    "create_at": ,
    "updated_at": 
}
//In case of missing parameter
response = {
    "name" : "This field is required"
}

# Delete Bucket
url = "/api/chat/buckets/<bucket_id>/delete/"
method = "DELETE"
request = {}
response = {
    "message" : "Bucket deleted"  // 200
}
// In case of user not admin
response = {
    "error" : "permission deleted. Required roles :"
}
//Incase of user not member of bucket
response = {
    "error" : "you are not a member of this bucket"
}

# Add member in the bucket
url = "/api/chat/buckets/members/add/"
method = "POST"
request = {
    "bucket": ""
    "user" : ""
    "role" : ""
}
//Incase of success
response = {
    "id": ,
    "bucket": ,
    "user" : ,
    "role" : ,
    "create_at": ,
    "updated_at": 
}

# Remove member in the bucket
url = "/api/chat/buckets/<bucket_id>/members/<user_id>/remove/"
method = "DELETE"
request = {}
response = {
    "message":"user removed from bucket"
}

# List members in the bucket
url= "/api/chat/buckets/<bucket_id>/members/"
method = "GET"
request = {}
response = [
    {
        "id": ,
        "bucket": ,
        "user" : ,
        "role" : ,
        "create_at": ,
        "updated_at": 
    }
]

# List Channels in a Bucket
**URL:** `/api/chat/buckets/<bucket_id>/channels/`  
**Method:** `GET`  
**Description:** Retrieves all channels in a specific bucket, including the most recent message in each channel.

#### Input Parameters:
- `bucket_id` (path): ID of the bucket.

#### Responses:
- **200 OK:** List of channels with the most recent message.
  ```json
  [
      {
          "id": 1,
          "name": "General",
          "channel_type": "group",
          "latest_message": "Hello, everyone!"
      },
      {
          "id": 2,
          "name": "Announcements",
          "channel_type": "group",
          "latest_message": "No messages yet"
      }
  ]
  ```
- **403 Forbidden:** User is not a member of the bucket.
- **404 Not Found:** Bucket does not exist.

---

### Create a Channel
**URL:** `/api/chat/channels/create/`  
**Method:** `POST`  
**Description:** Creates a new channel in a specific bucket.

#### Input Parameters:
- JSON body:
  ```json
  {
      "name": "General",
      "channel_type": "group",
      "bucket": 1
  }
  ```

#### Responses:
- **201 Created:** Channel created successfully.
  ```json
  {
      "id": 1,
      "name": "General",
      "channel_type": "group",
      "bucket": 1,
      "created_at": "2023-10-01T12:00:00Z",
      "updated_at": "2023-10-01T12:00:00Z"
  }
  ```
- **400 Bad Request:** Validation errors.
- **403 Forbidden:** User does not have permission to create a channel.
- **404 Not Found:** Bucket does not exist.

---

### Delete a Channel
**URL:** `/api/chat/channels/<channel_id>/delete/`  
**Method:** `DELETE`  
**Description:** Deletes a specific channel.

#### Input Parameters:
- `channel_id` (path): ID of the channel.

#### Responses:
- **204 No Content:** Channel deleted successfully.
- **403 Forbidden:** User does not have permission to delete the channel.
- **404 Not Found:** Channel does not exist.

---

### Add a User to a Channel
**URL:** `/api/chat/channels/members/add/`  
**Method:** `POST`  
**Description:** Adds a user to a specific channel.

#### Input Parameters:
- JSON body:
  ```json
  {
      "channel": 1,
      "user": 2
  }
  ```

#### Responses:
- **201 Created:** User added to the channel successfully.
  ```json
  {
      "id": 1,
      "channel": 1,
      "user": 2,
      "created_at": "2023-10-01T12:00:00Z",
      "updated_at": "2023-10-01T12:00:00Z"
  }
  ```
- **400 Bad Request:** Validation errors.
- **403 Forbidden:** User does not have permission to add members to the channel.
- **404 Not Found:** Channel does not exist.

---

### Remove a User from a Channel
**URL:** `/api/chat/channels/<channel_id>/members/<user_id>/remove/`  
**Method:** `DELETE`  
**Description:** Removes a user from a specific channel.

#### Input Parameters:
- `channel_id` (path): ID of the channel.
- `user_id` (path): ID of the user to remove.

#### Responses:
- **204 No Content:** User removed from the channel successfully.
- **403 Forbidden:** User does not have permission to remove members from the channel.
- **404 Not Found:** Channel or user does not exist.

---

### Fetch Messages in a Channel
**URL:** `/api/chat/channels/<channel_id>/messages/`  
**Method:** `GET`  
**Description:** Retrieves all messages in a specific channel.

#### Input Parameters:
- `channel_id` (path): ID of the channel.

#### Responses:
- **200 OK:** List of messages.
  ```json
  [
      {
          "id": 1,
          "sender": {
              "id": 1,
              "name": "John Doe",
              "email": "john@example.com"
          },
          "channel": 1,
          "message_text": "Hello, world!",
          "created_at": "2023-10-01T12:00:00Z"
      }
  ]
  ```
- **403 Forbidden:** User is not a member of the channel.
- **404 Not Found:** Channel does not exist.

---

# Join WebSocket for a Channel
**URL:** `ws://<server>/ws/chat/<channel_id>/`  
**Method:** `WebSocket`  
**Description:** Joins a WebSocket connection for real-time communication in a specific channel.

#### Input Parameters:
- `channel_id` (path): ID of the channel.

#### WebSocket Events:
1. **Connect:**
   - Automatically verifies if the user is authenticated and a member of the channel.
   - **Close Codes:**
     - `4001`: User is not authenticated.
     - `4003`: User is not a member of the channel.
     - `4004`: Channel does not exist.

2. **Send Message:**
   - **Payload:**
     ```json
     {
         "message_text": "Hello, world!",
         "channel_id": 1,
         "sender_id": 1
     }
     ```
   - **Response:**
     - Broadcasts the message to all members of the channel.
     - Sends push notifications to offline members.

3. **Receive Message:**
   - **Payload:**
     ```json
     {
         "type": "chat.message",
         "message": "Hello, world!",
         "sender": "John Doe",
         "sender_id": 1,
         "timestamp": "2023-10-01T12:00:00Z"
     }
     ```

#### Errors:
- **Invalid JSON Format:**
  ```json
  {
      "error": "Invalid JSON format"
  }
  ```
- **Validation Error:**
  ```json
  {
      "error": "Sender ID doesn't match authenticated user"
  }
  ```
- **Internal Server Error:**
  ```json
  {
      "error": "Internal server error"
  }
  ```

---


