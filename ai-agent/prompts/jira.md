# Jira Ticket Processing Custom Command

## Command Name
`/jira`

## Overview
A custom command that retrieves Jira ticket details, automatically updates status, and executes specified work.

## Usage
```
/jira <ticket-number>
```

Example:
```
/jira FRT-1234
```

## Workflow
### 1. Receive Ticket Number
Receives the Jira ticket number (e.g., FRT-1234) as a command argument.

### 2. Retrieve Ticket Details
Uses MCP tools to retrieve the following information for the specified ticket:
- Title
- Description
- Description for development ticket template
- Current status
- Assignee
- Other related information

### 3. Automatic Status Update
If the ticket status is "To Do":
1. Automatically update status to "In Progress"
2. Log the update completion

### 4. Create Work Plan
Analyze the ticket description to identify specific work items, report the content, and obtain approval.
If approval is not obtained, revise the plan according to instructions and request approval again. Repeat until approved.

### 5. Execute Work
Once approved, execute the work according to the plan. Follow these steps:
- Create a new branch from the default branch (e.g., `main`, `master` or `develop`)
  - Branch name should use the ticket number (e.g., `FRT-1234`)
- Make code changes
- Run tests
- Update documentation (if needed)
- Other specified tasks

### 6. Generate Work Report
Summarize the executed work and create a report in the following format:

```
## Work Report
### Ticket Information
- Ticket Number: [ticket-number]
- Title: [ticket-title]
- Status: [before] → [after]

### Executed Work
1. [work-item-1]
2. [work-item-2]
3. ...

### Changed Files
- [file-path-1]
- [file-path-2]
- ...

### Notes
[Additional information as needed]
```

## Error Handling
### Ticket Not Found
- Display error message
- Guide correct ticket number format

### MCP Connection Error
- Display connection error details
- Offer retry option

### Status Update Failure
- Display failure reason
- Guide manual update method

## Required MCP Tools
### Required Tools
1. **Jira MCP Server** - Handles communication with Jira
   - Retrieve ticket details
   - Update status
   - Add comments

## Usage Examples
### Basic Usage
```
/jira FRT-1234
```

Output example:
```
## Work Report

### Ticket Information
- Ticket Number: FRT-1234
- Title: Add validation to user registration form
- Status: To Do → In Progress

### Executed Work
1. Added email address validation function
2. Implemented password strength check feature
3. Created unit tests
4. Updated Storybook stories

### Changed Files
- src/components/user-registration/validation.ts
- src/components/user-registration/index.tsx
- src/components/user-registration/validation.test.ts
- src/components/user-registration/user-registration.stories.tsx

### Notes
- All tests passed
- No issues with TypeScript type checking
```

## Important Notes
1. **Permission Verification**
   - Jira ticket update permission is required
   - Verify project access permissions in advance
2. **Branch Creation**
   - Recommended to auto-generate branch names including ticket number
   - Example: `feature/FRT-1234-user-validation`
3. **Commit Messages**
   - Recommended to include ticket number
   - Example: `FRT-1234: Add email validation to user registration form`
4. **Security**
   - Manage API tokens via environment variables
   - Do not hardcode in source code

## Troubleshooting

### Common Issues

#### Cannot Connect to MCP Server
```
Error: Failed to connect to MCP server
```
Solutions:
1. Restart Claude Desktop
2. Verify MCP configuration file syntax
3. Confirm environment variables are correctly set

#### Ticket Status Update Failed
```
Error: Cannot transition issue from current state
```
Solutions:
1. Check workflow settings
2. Verify that transition from current status to target status is allowed
3. Confirm necessary permissions are granted

## Future Extensions

- [ ] Batch processing of multiple tickets
- [ ] Integration with PR creation
- [ ] Automatic work time logging
- [ ] Slack notification integration
- [ ] Custom workflow support
