# Task Management API Documentation

## Endpoints




### 1. List Tasks Assigned to the User in a Channel
**URL:** `/api/tasks/channels/<channel_id>/tasks/assigned/`  
**Method:** `GET`  
**Description:** Retrieves all tasks assigned to the user in a specific channel.

#### Input Parameters:
- `channel_id` (path): ID of the channel.

#### Responses:
- **200 OK:** List of tasks.
  ```json
  [
      {
          "id": 1,
          "title": "Task Title",
          "description": "Task Description",
          "status": "open",
          "due_date": "2023-12-31T23:59:59Z",
          "assigned_by": 1,
          "assigned_to": 2,
          "channel": 1
      }
  ]
  ```
- **403 Forbidden:** User is not a member of the channel.

---

### 2. List Tasks Created by the User in a Channel
**URL:** `/api/tasks/channels/<channel_id>/tasks/me/`  
**Method:** `GET`  
**Description:** Retrieves all tasks created by the user in a specific channel.

#### Input Parameters:
- `channel_id` (path): ID of the channel.

#### Responses:
- **200 OK:** List of tasks.
- **403 Forbidden:** User is not a member of the channel.

---

### 3. List Tasks Assigned to the User in an Organization
**URL:** `/api/tasks/organisations/<organisation_id>/tasks/assigned/`  
**Method:** `GET`  
**Description:** Retrieves all tasks assigned to the user in a specific organization.

#### Input Parameters:
- `organisation_id` (path): ID of the organization.

#### Responses:
- **200 OK:** List of tasks.
- **403 Forbidden:** User is not a member of the organization.

---

### 4. List Tasks Created by the User in an Organization
**URL:** `/api/tasks/organisations/<organisation_id>/tasks/me/`  
**Method:** `GET`  
**Description:** Retrieves all tasks created by the user in a specific organization.

#### Input Parameters:
- `organisation_id` (path): ID of the organization.

#### Responses:
- **200 OK:** List of tasks.
- **403 Forbidden:** User is not a member of the organization.

---

### 5. List All Tasks Assigned to the User
**URL:** `/api/tasks/assigned/`  
**Method:** `GET`  
**Description:** Retrieves all tasks assigned to the user.

#### Responses:
- **200 OK:** List of tasks.

---

### 6. List All Tasks Created by the User
**URL:** `/api/tasks/me/`  
**Method:** `GET`  
**Description:** Retrieves all tasks created by the user.

#### Responses:
- **200 OK:** List of tasks.

---

### 7. Create a New Task
**URL:** `/api/tasks/create/`  
**Method:** `POST`  
**Description:** Creates a new task in a specific channel.

#### Input Parameters:
- JSON body:
  ```json
  {
      "title": "Task Title",
      "description": "Task Description",
      "status": "open",
      "due_date": "2023-12-31T23:59:59Z",
      "assigned_by": 1,
      "assigned_to": 2,
      "channel": 1
  }
  ```

#### Responses:
- **201 Created:** Task created successfully.
  ```json
  {
      "id": 1,
      "title": "Task Title",
      "description": "Task Description",
      "status": "open",
      "due_date": "2023-12-31T23:59:59Z",
      "assigned_by": 1,
      "assigned_to": 2,
      "channel": 1
  }
  ```
- **400 Bad Request:** Validation errors.
- **403 Forbidden:** User is not authorized to create the task.

---

### 8. Retrieve a Specific Task
**URL:** `/api/tasks/<task_id>/`  
**Method:** `GET`  
**Description:** Retrieves details of a specific task.

#### Input Parameters:
- `task_id` (path): ID of the task.

#### Responses:
- **200 OK:** Task details.
  ```json
  {
      "id": 1,
      "title": "Task Title",
      "description": "Task Description",
      "status": "open",
      "due_date": "2023-12-31T23:59:59Z",
      "assigned_by": 1,
      "assigned_to": 2,
      "channel": 1
  }
  ```
- **403 Forbidden:** User is not authorized to view the task.
- **404 Not Found:** Task does not exist.

---

### 9. Update a Task
**URL:** `/api/tasks/<task_id>/update/`  
**Method:** `PUT`  
**Description:** Updates details of a specific task.

#### Input Parameters:
- `task_id` (path): ID of the task.
- JSON body with fields to update (e.g., `title`, `description`, `status`, `due_date`).

#### Responses:
- **200 OK:** Task updated successfully.
  ```json
  {
      "id": 1,
      "title": "Updated Task Title",
      "description": "Updated Task Description",
      "status": "in-progress",
      "due_date": "2023-12-31T23:59:59Z",
      "assigned_by": 1,
      "assigned_to": 2,
      "channel": 1
  }
  ```
- **400 Bad Request:** Validation errors.
- **403 Forbidden:** User is not authorized to update the task.
- **404 Not Found:** Task does not exist.

---

### 10. Delete a Task
**URL:** `/api/tasks/<task_id>/delete/`  
**Method:** `DELETE`  
**Description:** Deletes a specific task.

#### Input Parameters:
- `task_id` (path): ID of the task.

#### Responses:
- **204 No Content:** Task deleted successfully.
- **403 Forbidden:** User is not authorized to delete the task.
- **404 Not Found:** Task does not exist.

---

### 11. List All Tasks Grouped by Organization (Called by Task screen)
**URL:** `/api/tasks/organisations/tasks/`  
**Method:** `GET`  
**Description:** Retrieves all tasks grouped by organization (bucket) for the authenticated user.

#### Input Parameters:
- None

#### Responses:
- **200 OK:** List of tasks grouped by organization.
  ```json
  {
      "Development Team": [
          {
              "id": 1,
              "title": "Fix Bug #123",
              "status": "in-progress",
              "assigned_to": "Alice",
              "assigned_by": "Bob"
          },
          {
              "id": 2,
              "title": "Implement Feature X",
              "status": "open",
              "assigned_to": "Unassigned",
              "assigned_by": "Bob"
          }
      ],
      "Marketing Team": [
          {
              "id": 3,
              "title": "Prepare Campaign",
              "status": "completed",
              "assigned_to": "Charlie",
              "assigned_by": "Alice"
          }
      ]
  }
  ```
- **403 Forbidden:** User is not authenticated.

---
