# Rich Communication Language (RCL) Specification

## 1. Introduction

Rich Communication Language (RCL) is a declarative, indentation-sensitive language designed for specifying RCS (Rich Communication Services) agents. RCL files are intended to be transpiled into JSON structures that conform to predefined schemas for agent configuration and messaging. Its primary goal is to provide a human-readable and writable format for describing agent behavior and messages.

Key features of RCL:
- **Declarative**: Describes *what* the agent configuration and messages are, not *how* they are processed.
- **Indentation-Sensitive**: Uses indentation to define structure and nesting, enhancing readability.
- **Human-Readable Syntax**: Aims for a clear and concise syntax, drawing some inspiration from languages like Elixir (for atoms) and YAML (for structure).
- **Schema-Driven**: Designed to map directly to JSON schemas for RCS agent definitions.

## 2. File Structure

- RCL files use the `.rcl` extension.
- Each `.rcl` file defines a single RCS agent.
- The definition must start with an `Agent` declaration.

## 3. Lexical Elements

### 3.1. Comments
Single-line comments start with a `#` character and extend to the end of the line.
```rcl
# This is a comment
displayName: "My Agent" # This is an inline comment
```

### 3.2. Keywords
Keywords are reserved words that have special meaning in RCL.
Examples: `Agent`, `Config`, `Defaults`, `Flow`, `Messages`, `with`, `agentMessage`, `contentMessage`, `suggestion`, `reply`, `action`, `dialAction`, `openUrlAction`, `richCard`, `standaloneCard`, `carouselCard`, `cardContent`, `media`, etc.

Keywords are case-sensitive.

### 3.3. Identifiers (Names)
Identifiers are used for agent names, flow states, and other custom names.
- **Simple Identifiers**: Start with a letter or underscore, followed by letters, numbers, or underscores (e.g., `welcome`, `book_appointment`, `myVariable`). Regex: `[_a-zA-Z][\w_]*`
- **Qualified Identifiers**: Used for agent names, consisting of one or more Simple Identifiers separated by dots (`.`). (e.g., `MyBrand.SampleAgent`). Regex for each part: `[_a-zA-Z][\w_]*`.

### 3.4. Attributes / Keys
Attributes or keys in object-like structures are typically lowercase or snake_case, followed by a colon (`:`), and then a value. An optional space may exist after the colon.
```rcl
displayName: "Sample Agent"
fallback_message: "Sorry, I can't help with that."
```

### 3.5. Atoms
Atoms are constants whose value is their own name. They are prefixed with a colon (`:`). They follow Elixir-like rules (e.g., can contain letters, numbers, underscores, and `@` if not the first character). If an atom needs to contain spaces or special characters, it should be enclosed in double quotes after the colon (e.g., `:"My Atom With Spaces"`).
```rcl
messageTrafficType: :TRANSACTION
cardOrientation: :HORIZONTAL
error_type: :network_error
```
Atoms are typically used for enum values from the JSON schema.

### 3.6. Strings
Strings are sequences of characters enclosed in double quotes (`"`). Standard escape sequences like `\n`, `\t`, `\"` are supported.
```rcl
text: "Hello, world!\nHow are you?"
description: "A card description."
```

### 3.7. Numbers
Numbers can be integers or floating-point values.
```rcl
id: 1
latitude: 37.7749
longitude: -122.4194
```

### 3.8. Booleans
Booleans are represented by the keywords `true` and `false`.
```rcl
forceRefresh: false
enabled: true
```

### 3.9. Special Timestamp/Duration/Time Syntaxes
RCL supports specific string formats for dates, times, and durations, aligning with JSON schema requirements:
- **ISO 8601 DateTime**: Standard date-time strings.
  ```rcl
  expireTime: "2024-12-31T23:59:59Z"
  startTime: "2025-01-15T10:00:00Z"
  ```
- **ISO 8601 Duration**: Standard duration strings (for TTL).
  ```rcl
  ttl: "P7D"  # 7 days
  ttl: "PT1H" # 1 hour
  ttl: "3.5s" # 3.5 seconds (as per schema pattern for direct seconds)
  ```
- **Custom Time Format `~T[HH:MM]`**: Represents a specific time of day. This typically translates to a string like "HH:MM".
  ```rcl
  time: ~T[10:00] # Represents "10:00"
  ```

### 3.10. Maps / Structs (Explicit)
Explicit maps or structs can be defined using the `%{ ... }` syntax. Keys are typically atoms or strings, and values are any valid RCL type. This syntax is used when a property explicitly requires a map-like object.
```rcl
uploadedRbmFile: %{
  fileName: "invoice_123.pdf",
  thumbnailUrl: "https://cdn.example.com/thumbnails/invoice_123_thumb.png"
}
```
Keys within `%{...}` follow attribute naming conventions (e.g. `fileName:`).

## 4. Agent Definition
An RCL file defines a single agent. The definition must start with the `Agent` keyword, followed by the agent's qualified name.
```rcl
Agent MyBrand.SampleAgent
  # Agent sections (Config, Defaults, Flow, Messages) follow
```

## 5. Sections
An agent definition is composed of several top-level sections: `Config`, `Defaults`, `Flow`, and `Messages`. The `Flow` and `Messages` sections are mandatory. `Config` and `Defaults` are optional. The content of each section is defined by indentation.

### 5.1. `Config` Section (Optional)
Contains global configuration for the agent. These settings typically map to the `rcsBusinessMessagingAgent` object and its properties in the `agent-config.schema.json`.
```rcl
Agent MyBrand.SampleAgent
  Config
    displayName: "Sample Agent"
    brandName: "Sample Brand" # Output only in schema, but can be specified for clarity
    logoUri: "https://www.example.com/logo.png"
    color: "#123456"
    # ... other config properties
```

### 5.2. `Defaults` Section (Optional)
Specifies default values for message properties. These can be overridden in individual messages.
```rcl
Agent MyBrand.SampleAgent
  Defaults
    fallback_message: "I didn't understand that. Let me connect you with support."
    messageTrafficType: :TRANSACTION
    ttl: "PT1H"
```

### 5.3. `Flow` Section (Mandatory)
Defines the conversational flow of the agent using states and transitions (clauses).
```rcl
Agent MyBrand.SampleAgent
  Flow
    :start -> welcome  # Initial state transition

    welcome -> # From 'welcome' state
        "Book Appointment" -> book_appointment  # If user input is "Book Appointment", go to 'book_appointment'
        "Check Status" -> check_status
        "Contact Support" -> contact_support

    check_status ->
        "Appointment 1" -> status_response with id: 1, time: ~T[10:00] # Transition with parameters
        # ... other transitions
```
- Flow states are typically atoms (e.g., `:start`) or identifiers (e.g., `welcome`).
- Transitions are defined by `->`.
- User input matching is done via string literals.

### 5.4. `Messages` Section (Mandatory)
Defines named, pre-structured messages that the agent can send. These messages conform to the `agent-message.schema.json`.
```rcl
Agent MyBrand.SampleAgent
  Messages
    agentMessage myWelcomeMessage // A named agentMessage (optional naming, or just `agentMessage`)
      messageTrafficType: :TRANSACTION
      contentMessage
        text: "Hello! Welcome to our service."
        suggestion
          reply text: "Hi there!", postbackData: "welcome_reply"

    agentMessage anotherMessage
      # ... message definition
```
If not explicitly named, `agentMessage` simply defines an anonymous message structure that might be referenced by the system or flow logic implicitly. The example `spec/agent-example.rcl` does not name the messages, it just lists `agentMessage` blocks. This suggests they are more like message templates or direct definitions.

## 6. Statements and Expressions

### 6.1. Attribute Assignment
Assigns a value to a key/property.
Syntax: `key: value`
```rcl
displayName: "Sample Agent"
text: "Hello"
count: 10
```
Values can be literals (strings, numbers, booleans, atoms), special formats (`~T[HH:MM]`), or nested object definitions.

### 6.2. Nested Object Definition
Objects can be nested by indenting attribute assignments under a parent key that represents an object. Many keywords (like `contentMessage`, `suggestion`, `action`, `dialAction`, `richCard`) implicitly define an object scope for their properties.
```rcl
agentMessage
  contentMessage // Defines a contentMessage object
    text: "This is a message."
    suggestion // Defines a suggestion object (adds to a list of suggestions)
      reply // Defines a reply object
        text: "Okay"
        postbackData: "okay_pb"
```
A property itself can be an object type from the schema. For example, in `SuggestedAction`, `dialAction` is a property whose type is `DialAction`. In RCL, this is written as:
```rcl
suggestion
  action
    text: "Call now"
    postbackData: "call_now_pb"
    dialAction // 'dialAction' is the property name and implies the type DialAction
      phoneNumber: "+1234567890" // 'phoneNumber' is a property of the DialAction object
```

### 6.3. Clauses (Flow Rules)
Used in the `Flow` section to define transitions.
Basic form: `CURRENT_STATE_OR_INPUT -> NEXT_STATE`
```rcl
:start -> welcome
welcome -> "Details" -> show_details
```
Clauses can also involve the `with` keyword.

### 6.4. `with` Keyword
The `with` keyword is used to pass parameters or set properties when transitioning to a new state or invoking a function-like construct in a flow.
Syntax: `TARGET with param1: value1, param2: value2, ...`
```rcl
check_status ->
    "Appointment 1" -> status_response with id: 1, time: ~T[10:00], details: "Meeting about project X"
```
This implies that `status_response` (which could be a message template or another flow logic) is invoked with the given parameters. The parameters are specified as key-value pairs.

### 6.5. Function-like Calls with Named Parameters (Implicit)
Many constructs, especially actions and card components, behave like function calls or object instantiations with named parameters. These are typically single-line or multi-line indented blocks.
```rcl
# Single line
dialAction phoneNumber: "+1234567890"

# Multi-line using indentation
createCalendarEventAction
  startTime: "2025-01-15T10:00:00Z"
  endTime: "2025-01-15T11:00:00Z"
  title: "Project Discussion"
  description: "Discuss project milestones."
```
If a property itself is a complex object (e.g., `latLong` within `ViewLocationAction`), its sub-properties can be specified directly:
```rcl
viewLocationAction label: "Our Office"
  latLong # This is the field name for the nested object
    latitude: 37.7749
    longitude: -122.4194
```
Or, if the schema defines `latLong` with `latitude` and `longitude` properties, they can sometimes be listed comma-separated if the grammar design supports it for conciseness, though indentation is the primary grouping mechanism:
```rcl
# Alternative for very simple nested objects (requires grammar support)
viewLocationAction label: "Our Office", latLong: (latitude: 37.7749, longitude: -122.4194)
```
The primary documented way for nested objects that are properties is indentation:
```rcl
viewLocationAction
  label: "Our Office"
  latLong # Property name `latLong`
    # Properties of the `latLong` object
    latitude: 37.7749
    longitude: -122.4194
```
The example `latLong latitude: 37.7749, longitude: -122.4194` (indented) suggests `latLong` is a property, and its value is defined by the following key-value pairs on the same or subsequent lines.

## 7. Data Structures

### 7.1. Lists / Arrays
Lists are typically formed by repeating a keyword or element type within a certain scope. For example, multiple `suggestion` blocks under a `contentMessage` or `cardContent` form a list of suggestions.
```rcl
contentMessage
  text: "Choose an option:"
  suggestion # First item in the list of suggestions
    reply text: "Option A", postbackData: "option_a"
  suggestion # Second item in the list of suggestions
    reply text: "Option B", postbackData: "option_b"
```
The JSON schema defines `suggestions` as an array. The RCL syntax above maps to this.
For `cardContents` in a `carouselCard`, multiple `cardContent` blocks are used.

### 7.2. Maps / Structs / Objects
Objects are primarily defined through indentation and attribute assignments. Keywords often introduce new object scopes.
```rcl
# standaloneCard implicitly defines an object
standaloneCard
  cardOrientation: :HORIZONTAL
  cardContent # cardContent is a property that is an object
    title: "Product Showcase"
    description: "Explore our latest product."
    media # media is a property that is an object
      height: :MEDIUM
      contentInfo # contentInfo is a property that is an object
        fileUrl: "https://www.example.com/product_image.jpg"
```
Explicit map syntax `%{...}` is available as described in Lexical Elements, typically used when a property value itself needs to be a map provided inline.

## 8. Indentation
RCL is indentation-sensitive. Indentation is used to define nesting, scope, and structure.
- Consistent use of spaces for indentation is required (e.g., 2 or 4 spaces per level). Mixing tabs and spaces is discouraged.
- An increase in indentation level starts a new block or nested structure.
- A decrease in indentation level closes the current block.
- All statements within the same block must have the same indentation level.

Example:
```rcl
Agent MyAgent
  Config # Level 1
    displayName: "Agent Display Name" # Level 2
  Flow # Level 1
    :start -> welcome # Level 2
    welcome -> # Level 2
        "Option 1" -> option1_flow # Level 3
```

## 9. Mapping to JSON Schema
RCL is designed to be transpiled into JSON that conforms to `agent-config.schema.json` and `agent-message.schema.json`.

- **`Agent NAME` and `Config` / `Defaults` sections**: Map to fields in `agent-config.schema.json`. The `Config` section properties typically populate the `rcsBusinessMessagingAgent` object within the agent definition. `Defaults` can inform default values for messages.
- **`Messages` section**: Each `agentMessage` block (or similarly structured named message) maps to an object conforming to `agent-message.schema.json`.
- **Keywords**: Many keywords in RCL (e.g., `agentMessage`, `contentMessage`, `suggestion`, `reply`, `action`, specific action types like `dialAction`, `openUrlAction`, card types like `richCard`, `standaloneCard`) directly correspond to definitions or properties in the JSON schemas.
- **Attributes**: RCL attributes (e.g., `text: "Hello"`) map to JSON object properties.
- **Atoms**: RCL atoms (e.g., `:TRANSACTION`) map to their string counterparts (e.g., `"TRANSACTION"`) for enum values in JSON.
- **Nested Structures**: Indented blocks in RCL create nested JSON objects.
  For example:
  ```rcl
  suggestion
    action
      text: "Visit Website"
      postbackData: "visit_web_pb"
      openUrlAction
        url: "https://www.example.com"
  ```
  Transpiles to (simplified JSON):
  ```json
  {
    "suggestion": {
      "action": {
        "text": "Visit Website",
        "postbackData": "visit_web_pb",
        "openUrlAction": {
          "url": "https://www.example.com"
        }
      }
    }
  }
  ```
- **Lists**: Repeated elements like `suggestion` under `contentMessage` are collected into a JSON array.
  ```rcl
  contentMessage
    suggestions: [ // In JSON
      { "reply": { ... } },
      { "action": { ... } }
    ]
  ```

This specification document should serve as a basis for developing the Langium grammar for RCL. Reviewing this document will help identify any ambiguities or missing details before implementation. 