****# AgentMessage Verifiers Documentation

This document outlines the purpose and constraints enforced by each verifier in the AgentMessage DSL system.

## Overview

The AgentMessage extension uses Spark.Dsl.Verifier modules to enforce business rules and constraints on the DSL structures. These verifiers run during compile time to ensure the generated AgentMessage structures are valid according to the Google RCS Business Messaging specification.

## Verifiers

### 1. RootVerifier (`AgentMessage.Verifiers.RootVerifier`)

**Purpose**: Validates constraints on the root AgentMessage object.

**Constraints**:
- Ensures `expireTime` and `ttl` are mutually exclusive
- Both fields cannot be set simultaneously on an AgentMessage

**Error Messages**:
- "expireTime and ttl are mutually exclusive and cannot both be set."

### 2. AgentContentMessageVerifier (`AgentMessage.Verifiers.AgentContentMessageVerifier`)

**Purpose**: Verifies constraints on the AgentContentMessage section, which represents the main content of a message.

**Constraints**:
- Exactly one content type must be provided among: `text`, `fileName`, `uploadedRbmFile`, `richCard`, or `contentInfo`
- Maximum of 11 suggestions are allowed per content message

**Error Messages**:
- "One content type (text, fileName, uploadedRbmFile, richCard, or contentInfo) must be provided."
- "Only one content type can be provided. Found: [list of found types]."
- "A maximum of 11 suggestions are allowed. Found: [count]."

### 3. ViewLocationActionVerifier (`AgentMessage.Verifiers.ViewLocationActionVerifier`)

**Purpose**: Validates ViewLocationAction entities used for displaying locations on maps.

**Constraints**:
- Exactly one location specification must be provided: either `latLong` or `query`
- Cannot specify both latitude/longitude coordinates and a search query

**Error Messages**:
- "ViewLocationAction must contain either latLong or query, but not both. Found both."
- "ViewLocationAction must contain either latLong or query. None provided."

### 4. ComposeActionVerifier (`AgentMessage.Verifiers.ComposeActionVerifier`)

**Purpose**: Validates ComposeAction entities used for opening message composition interfaces.

**Constraints**:
- Exactly one compose type must be provided: either `composeTextMessage` or `composeRecordingMessage`
- Cannot specify both text and recording message composition

**Error Messages**:
- "ComposeAction must contain either composeTextMessage or composeRecordingMessage, but not both. Found both."
- "ComposeAction must contain either composeTextMessage or composeRecordingMessage. None provided."

### 5. SuggestedActionVerifier (`AgentMessage.Verifiers.SuggestedActionVerifier`)

**Purpose**: Validates SuggestedAction entities that provide interactive buttons for users.

**Constraints**:
- Exactly one specific action type must be provided from: `dialAction`, `viewLocationAction`, `createCalendarEventAction`, `openUrlAction`, `shareLocationAction`, or `composeAction`
- Cannot specify multiple action types in a single suggestion

**Error Messages**:
- "A suggested action must contain exactly one specific action type (e.g., dialAction, viewLocationAction). None provided."
- "A suggested action must contain exactly one specific action type. Found: [list of found actions]."

### 6. SuggestionVerifier (`AgentMessage.Verifiers.SuggestionVerifier`)

**Purpose**: Validates Suggestion entities that can contain either quick replies or actions.

**Constraints**:
- Exactly one suggestion type must be provided: either `reply` or `action`
- Cannot specify both a reply and an action in the same suggestion

**Error Messages**:
- "A suggestion must contain either a reply or an action, but not both. Found both."
- "A suggestion must contain either a reply or an action. None provided."

### 7. MediaVerifier (`AgentMessage.Verifiers.MediaVerifier`)

**Purpose**: Validates Media entities used in rich cards.

**Constraints**:
- Exactly one media source must be provided: either `uploadedRbmFile` or `contentInfo`
- Cannot specify both an uploaded file and external content info

**Error Messages**:
- "Media must contain either an uploadedRbmFile or contentInfo, but not both. Found both."
- "Media must contain either an uploadedRbmFile or contentInfo. None provided."

### 8. CardContentVerifier (`AgentMessage.Verifiers.CardContentVerifier`)

**Purpose**: Validates CardContent entities used within rich cards.

**Constraints**:
- Maximum of 4 suggestions are allowed per card content

**Error Messages**:
- "CardContent can have a maximum of 4 suggestions. Found: [count]."

### 9. CarouselCardVerifier (`AgentMessage.Verifiers.CarouselCardVerifier`)

**Purpose**: Validates CarouselCard entities that display multiple cards in a horizontal scroll.

**Constraints**:
- Must have between 2 and 10 card contents
- All cards with media must have the same media height for visual consistency

**Error Messages**:
- "CarouselCard must have between 2 and 10 cardContents. Found: [count]."
- "All cards in a CarouselCard must have the same media.height if media is present."

### 10. StandaloneCardVerifier (`AgentMessage.Verifiers.StandaloneCardVerifier`)

**Purpose**: Validates StandaloneCard entities that display a single rich card.

**Constraints**:
- When `cardOrientation` is `HORIZONTAL` and media is present, the card content must also have at least one of: `title`, `description`, or `suggestions`
- This ensures horizontal cards with media have accompanying text or interactive elements

**Error Messages**:
- "When cardOrientation is HORIZONTAL and media is present, cardContent must also have a title, description, or suggestions."

### 11. RichCardVerifier (`AgentMessage.Verifiers.RichCardVerifier`)

**Purpose**: Validates RichCard entities that can contain either carousel or standalone cards.

**Constraints**:
- Exactly one card type must be provided: either `carouselCard` or `standaloneCard`
- Cannot specify both carousel and standalone cards in the same rich card

**Error Messages**:
- "RichCard must contain either a carouselCard or a standaloneCard, but not both. Found both."
- "RichCard must contain either a carouselCard or a standaloneCard. None provided."

## Verifier Architecture

All verifiers follow the same pattern:

1. **Inherit from `Spark.Dsl.Verifier`**: Use the Spark framework's verifier behavior
2. **Implement `verify/1`**: The main validation function that receives the DSL state
3. **Extract context**: Get module name and path information for error reporting
4. **Check constraints**: Validate business rules specific to each entity type
5. **Return results**: Either `:ok` for valid structures or `{:error, Spark.Error.DslError.exception(...)}` for violations

## Error Handling

Verifiers use `Spark.Error.DslError.exception/1` to create structured errors that include:
- **message**: Human-readable description of the constraint violation
- **path**: Location in the DSL structure where the error occurred
- **module**: The module being compiled when the error was detected

This provides developers with precise error messages that help them quickly identify and fix DSL validation issues. 