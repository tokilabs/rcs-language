# Rich Communication Language (RCL) Implementation Plan v2

## Executive Summary

This plan implements a complete RCL language with all features defined in `overview.md`, including indentation-sensitive parsing, expression system, multi-line strings, type conversion, RCS shortcuts, and comprehensive validation. The implementation prioritizes developer experience through robust error messages, semantic highlighting, and modular grammar organization.

## 1. Indentation-Sensitive Language Configuration

### Status: **REQUIRED** - Current grammar uses `hidden terminal WS: /\s+/` (not indentation-aware)

#### 1.1 Update Language Module (`src/language/rcl-module.ts`)
```typescript
import { IndentationAwareTokenBuilder, IndentationAwareLexer } from 'langium';

export const RclModule: Module<RclServices, PartialLangiumServices & RclAddedServices> = {
    parser: {
        TokenBuilder: () => new IndentationAwareTokenBuilder({
            indentTokenName: 'INDENT',
            dedentTokenName: 'DEDENT',
            whitespaceTokenName: 'WS',
            ignoreIndentationDelimiters: [
                ['(', ')'],  // Ignore indentation in parameter lists
                ['[', ']'],  // Ignore indentation in arrays
                ['{', '}'],  // Ignore indentation in explicit maps
            ],
        }),
        Lexer: (services) => new IndentationAwareLexer(services),
    },
    validation: {
        RclValidator: () => new RclValidator()
    }
};
```

#### 1.2 Update Common Grammar (`src/language/grammar/rcl-common.langium`)
```langium
// Replace existing WS terminal with indentation-aware terminals
terminal INDENT: 'synthetic:indent';
terminal DEDENT: 'synthetic:dedent';
hidden terminal WS: /[\t ]+/;
hidden terminal NL: /[\r\n]+/;
hidden terminal SL_COMMENT: /#.*/;
```

## 2. Grammar Architecture & Organization

### 2.1 Current Grammar Structure (Keep)
- ✅ `rcl-common.langium` - Shared terminals and basic rules
- ✅ `rcl-agent-config.langium` - Agent configuration syntax
- ✅ `rcl-agent-message.langium` - Message definitions
- ✅ `rcl.langium` - Main entry point and imports

### 2.2 New Grammar Files (Add)
- `rcl-expressions.langium` - Expression system and blocks
- `rcl-strings.langium` - Multi-line string variants
- `rcl-types.langium` - Type conversion syntax
- `rcl-shortcuts.langium` - RCS spec shortcuts
- `rcl-flows.langium` - Enhanced flow system (extract from main)

### 2.3 Grammar Import Strategy
```langium
// rcl.langium
grammar Rcl

import "./grammar/rcl-common";
import "./grammar/rcl-expressions";
import "./grammar/rcl-strings";
import "./grammar/rcl-types";
import "./grammar/rcl-shortcuts";
import "./grammar/rcl-flows";
import "./grammar/rcl-agent-config";
import "./grammar/rcl-agent-message";
```

## 3. Expression System Implementation

### 3.1 New Grammar File: `src/language/grammar/rcl-expressions.langium`
```langium
grammar RclExpressions

import "./rcl-common";

// Single-line expressions: $> or $js> or $ts>
terminal SINGLE_LINE_EXPRESSION: /\$([a-z]*>)\s*[^\r\n]*/;

// Multi-line expression blocks: $>>> or $js>>> or $ts>>>
terminal MULTI_LINE_EXPRESSION_START: /\$([a-z]*>>>)/;
terminal MULTI_LINE_EXPRESSION_CONTENT: /[^]*/; // Will be handled by custom lexer logic

Expression infers Expression:
    SingleLineExpression | MultiLineExpression;

SingleLineExpression infers SingleLineExpression:
    content=SINGLE_LINE_EXPRESSION;

MultiLineExpression infers MultiLineExpression:
    start=MULTI_LINE_EXPRESSION_START
    INDENT
    content=MULTI_LINE_EXPRESSION_CONTENT
    DEDENT;

// Usage in flow transitions and message content
ExpressionValue infers ExpressionValue:
    expression=Expression | value=SimpleValue;
```

### 3.2 Integration Points
- Flow state transitions: `$js> determine_next_step(context.user.type)`
- Message content: `text: $js> format_greeting(context.user.name)`
- Default configurations: `postbackData: $js> formatAsSnakeCase(context.text)`

## 4. Multi-line String System

### 4.1 New Grammar File: `src/language/grammar/rcl-strings.langium`
```langium
grammar RclStrings

import "./rcl-common";

// Multi-line string terminals
terminal MULTILINE_STRING_CLEAN: /\|\s*$/;          // | - clean with newline
terminal MULTILINE_STRING_TRIM: /\|-\s*$/;          // |- - clean, no newline
terminal MULTILINE_STRING_PRESERVE: /\+\|\s*$/;     // +| - preserve leading
terminal MULTILINE_STRING_PRESERVE_ALL: /\+\|\+\s*$/; // +|+ - preserve all

// String content (handled by indentation-aware lexer)
terminal STRING_CONTENT: /[^]*/;

MultiLineString infers MultiLineString:
    (
        type='|' marker=MULTILINE_STRING_CLEAN |
        type='|-' marker=MULTILINE_STRING_TRIM |
        type='+|' marker=MULTILINE_STRING_PRESERVE |
        type='+|+' marker=MULTILINE_STRING_PRESERVE_ALL
    )
    INDENT
    content=STRING_CONTENT
    DEDENT;

// Enhanced SimpleValue to include multi-line strings
EnhancedSimpleValue infers EnhancedSimpleValue:
    STRING | NUMBER | BooleanLiteral | ATOM | TIME_LITERAL | ISO_DURATION_LITERAL | MultiLineString;
```

### 4.2 Usage Examples
```rcl
description: |
    This is a clean multi-line description.
    It will have proper indentation removed.

welcomeMessage: |-
    Welcome to our service!
    How may we help you today?

template: +|
    Dear {{name}},
        Thank you for your order.
    Best regards,
    The Team
```

## 5. Type Conversion System

### 5.1 New Grammar File: `src/language/grammar/rcl-types.langium`
```langium
grammar RclTypes

import "./rcl-common";

// Type conversion syntax: <type value>
terminal TYPE_CONVERSION_START: /</;
terminal TYPE_CONVERSION_END: />/;
terminal TYPE_NAME: /[a-zA-Z]+/;
terminal PIPE_SEPARATOR: /\|/;

TypeConversion infers TypeConversion:
    '<' typeName=TYPE_NAME value=TypeConversionValue ('|' timezone=STRING)? '>';

TypeConversionValue infers TypeConversionValue:
    STRING | NUMBER | ATOM | ID;

// Supported types with aliases
TypedValue infers TypedValue:
    TypeConversion | SimpleValue;

// Built-in type validators (implemented in services)
// - email: validates email format
// - phone/msisdn: validates and formats phone numbers  
// - url: validates URL format
// - time: parses time with timezone support
// - datetime/date: parses dates with timezone
// - zipcode/zip: validates postal codes with country
```

### 5.2 Usage Examples
```rcl
phoneNumber: <phone +1-555-123-4567>
email: <email support@company.com>
appointmentTime: <time 2:30pm | PST>
eventDate: <date March 15th, 2024>
websiteUrl: <url https://www.example.com>
```

## 6. RCS Spec Shortcuts

### 6.1 New Grammar File: `src/language/grammar/rcl-shortcuts.langium`
```langium
grammar RclShortcuts

import "./rcl-common";
import "./rcl-types";
import "./rcl-strings";

// Message shortcuts
MessageShortcut infers MessageShortcut:
    TextShortcut | FileShortcut | RichCardShortcut;

TextShortcut infers TextShortcut:
    'text' content=(STRING | MultiLineString)
    (INDENT suggestions+=SuggestionShortcut* DEDENT)?;

FileShortcut infers FileShortcut:
    'uploadedRbmFile' fileName=STRING thumbnailName=STRING?
    (INDENT suggestions+=SuggestionShortcut* DEDENT)?;

RichCardShortcut infers RichCardShortcut:
    'richCard' title=STRING
    (INDENT suggestions+=SuggestionShortcut* DEDENT)?;

// Suggestion shortcuts
SuggestionShortcut infers SuggestionShortcut:
    ReplyShortcut | DialShortcut | OpenUrlShortcut | ShareLocationShortcut | 
    CreateCalendarEventShortcut | ViewLocationShortcut;

ReplyShortcut infers ReplyShortcut:
    'reply' text=STRING postbackData=STRING?;

DialShortcut infers DialShortcut:
    'dial' text=STRING phoneNumber=TypedValue; // Expects <phone ...>

OpenUrlShortcut infers OpenUrlShortcut:
    'openUrl' text=STRING url=TypedValue description=STRING?
    (viewMode=(':BROWSER' | ':WEBVIEW') (size=(':FULL' | ':HALF' | ':TALL'))?)?;

ShareLocationShortcut infers ShareLocationShortcut:
    'shareLocation' text=STRING;

CreateCalendarEventShortcut infers CreateCalendarEventShortcut:
    'createCalendarEvent' text=STRING
    INDENT
    'event' title=STRING startTime=TypedValue endTime=TypedValue
    ('description' ':' description=(STRING | MultiLineString))?
    DEDENT;

ViewLocationShortcut infers ViewLocationShortcut:
    'viewLocation' text=STRING?
    (('latLng' lat=NUMBER lng=NUMBER) | ('query' query=STRING))?
    ('label' label=STRING)?;
```

### 6.2 Automatic Expansion Service
Create `src/language/rcl-shortcut-expander.ts` to transform shortcuts into full `AgentMessage` structures during code generation.

## 7. Enhanced Flow System

### 7.1 New Grammar File: `src/language/grammar/rcl-flows.langium`
```langium
grammar RclFlows

import "./rcl-common";
import "./rcl-expressions";

// Enhanced flow section with expression support
EnhancedFlowSection infers EnhancedFlowSection:
    'flow' name=(ID | TITLE) // Support title identifiers
    INDENT
    (rules+=EnhancedFlowRule)*
    DEDENT;

EnhancedFlowRule infers EnhancedFlowRule:
    from=FlowOperandOrExpression ('->' to+=FlowOperandOrExpression)+ 
    (withClause=EnhancedWithClause)?;

FlowOperandOrExpression infers FlowOperandOrExpression:
    FlowOperand | Expression | 'ref' target=[AbstractNamedSection:ID];

EnhancedWithClause infers EnhancedWithClause:
    'with' (params+=EnhancedParameter (',' params+=EnhancedParameter)*);

EnhancedParameter infers EnhancedParameter:
    name=ID ':' value=(SimpleValue | Expression);

// Title identifier support
terminal TITLE: /[A-Z][a-z]*(\s+[A-Z][a-z]*)*/;
```

### 7.2 Flow Validation Rules
- `:start` symbol validation
- Circular dependency detection
- Expression type checking
- Parameter flow validation

## 8. Title Identifiers

### 8.1 Grammar Integration
```langium
// In rcl-common.langium
terminal TITLE: /[A-Z][a-z]*(\s+[A-Z][a-z]*)*/;

// Usage in sections
SectionName returns string:
    ID | TITLE;

// Validation rules
TitleValidation:
    - Maximum 5 words
    - Each word 2-20 characters
    - No reserved names (Config, Defaults, Messages)
```

### 8.2 Usage Examples
```rcl
flow Welcome Message
    :start -> Greeting

agentMessage Booking Confirmation
    messageTrafficType: :promotional
    text: "Your booking is confirmed!"
```

## 9. Comprehensive Validation System

### 9.1 Enhanced Validator (`src/language/rcl-validator.ts`)
```typescript
export class RclValidator {
    
    // Agent-level validations
    checkUniqueFlowNames(agent: AgentDefinition, accept: ValidationAcceptor): void;
    checkReservedSectionNames(agent: AgentDefinition, accept: ValidationAcceptor): void;
    checkStartRule(agent: AgentDefinition, accept: ValidationAcceptor): void;
    
    // Schema compliance validations
    validatePhoneNumbers(phone: PhoneNumberProperty, accept: ValidationAcceptor): void;
    validateEmailAddresses(email: EmailProperty, accept: ValidationAcceptor): void;
    validateUrls(url: string, accept: ValidationAcceptor): void;
    validateColorHex(color: string, accept: ValidationAcceptor): void;
    validateSuggestionLimits(suggestions: Suggestion[], accept: ValidationAcceptor): void;
    
    // Expression validations
    validateExpressionSyntax(expr: Expression, accept: ValidationAcceptor): void;
    validateExpressionContext(expr: Expression, accept: ValidationAcceptor): void;
    
    // Type conversion validations
    validateTypeConversion(conversion: TypeConversion, accept: ValidationAcceptor): void;
    
    // Flow system validations
    validateFlowReferences(rule: FlowRule, accept: ValidationAcceptor): void;
    validateCircularDependencies(flows: FlowSection[], accept: ValidationAcceptor): void;
    
    // Multi-line string validations
    validateStringLength(content: string, maxLength: number, accept: ValidationAcceptor): void;
    
    // Title identifier validations
    validateTitleFormat(title: string, accept: ValidationAcceptor): void;
    
    // RCS spec constraint validations
    validateMessageTrafficType(type: string, accept: ValidationAcceptor): void;
    validateDurationFormats(duration: string, accept: ValidationAcceptor): void;
    validateAtomEnumValues(atom: string, allowedValues: string[], accept: ValidationAcceptor): void;
}
```

### 9.2 Validation Categories
- **Syntax Validations**: Grammar compliance, indentation consistency
- **Semantic Validations**: Cross-references, type compatibility
- **Schema Validations**: RCS specification compliance
- **Business Logic Validations**: Flow completeness, message limits
- **Expression Validations**: JavaScript/TypeScript syntax, context variables

## 10. Semantic Highlighting Support

### 10.1 New Service: `src/language/rcl-semantic-highlighter.ts`
```typescript
import { SemanticTokensProvider, SemanticTokens } from 'langium/lsp';

export class RclSemanticHighlighter implements SemanticTokensProvider {
    
    async semanticTokens(document: LangiumDocument): Promise<SemanticTokens> {
        const tokens: SemanticToken[] = [];
        
        // Highlight expressions
        this.highlightExpressions(document.parseResult.value, tokens);
        
        // Highlight type conversions
        this.highlightTypeConversions(document.parseResult.value, tokens);
        
        // Highlight flow references
        this.highlightFlowReferences(document.parseResult.value, tokens);
        
        // Highlight multi-line strings
        this.highlightMultiLineStrings(document.parseResult.value, tokens);
        
        // Highlight shortcuts
        this.highlightShortcuts(document.parseResult.value, tokens);
        
        return { tokens };
    }
    
    private highlightExpressions(node: AstNode, tokens: SemanticToken[]): void {
        // JavaScript/TypeScript expression highlighting
    }
    
    private highlightTypeConversions(node: AstNode, tokens: SemanticToken[]): void {
        // Type conversion syntax highlighting
    }
    
    // ... other highlighting methods
}
```

### 10.2 Token Types
- `expression` - JavaScript/TypeScript expressions
- `typeConversion` - Type conversion syntax
- `flowReference` - Flow cross-references
- `multilineString` - Multi-line string content
- `shortcut` - RCS shortcut syntax
- `atom` - Atom values (symbols)
- `title` - Title identifiers

### 10.3 Module Integration
```typescript
// In rcl-module.ts
export const RclModule: Module<RclServices, PartialLangiumServices & RclAddedServices> = {
    lsp: {
        SemanticTokensProvider: () => new RclSemanticHighlighter(),
    },
    // ... other services
};
```

## 11. Deprecated Feature Removal

### 11.1 RCS Specification Analysis
Research and identify deprecated features from:
- `https://developers.google.com/business-communications/rcs-business-messaging/reference/rest/v1/phones.agentMessages#ComposeAction`
- Agent message schema definitions
- Action type specifications

### 11.2 Removal Strategy
```typescript
// Create deprecation validator
export class DeprecationValidator {
    private deprecatedFeatures = [
        'deprecatedProperty1',
        'deprecatedAction2',
        // ... populate from RCS docs
    ];
    
    validateDeprecatedUsage(node: AstNode, accept: ValidationAcceptor): void {
        // Check for deprecated feature usage
        // Provide migration suggestions
    }
}
```

### 11.3 Migration Guidance
- Error messages with suggested alternatives
- Documentation updates
- Example transformations

## 12. Development Workflow & Testing

### 12.1 Implementation Phases

#### Phase 1: Foundation (Week 1)
1. Configure indentation-sensitive parsing
2. Update grammar organization
3. Implement basic expression terminals
4. Basic validation framework

#### Phase 2: Core Features (Week 2)
1. Multi-line string system
2. Type conversion syntax
3. Enhanced flow system
4. Title identifier support

#### Phase 3: Advanced Features (Week 3)
1. RCS shortcut system
2. Comprehensive validation rules
3. Semantic highlighting
4. Expression expansion service

#### Phase 4: Polish & Integration (Week 4)
1. Deprecated feature removal
2. Comprehensive testing
3. Documentation updates
4. Performance optimization

### 12.2 Testing Strategy
```typescript
// Test file structure
test/
├── parsing/
│   ├── expressions.test.ts
│   ├── multiline-strings.test.ts
│   ├── type-conversions.test.ts
│   ├── shortcuts.test.ts
│   └── indentation.test.ts
├── validation/
│   ├── schema-compliance.test.ts
│   ├── flow-validation.test.ts
│   ├── expression-validation.test.ts
│   └── deprecation.test.ts
├── linking/
│   ├── cross-references.test.ts
│   ├── imports.test.ts
│   └── scoping.test.ts
└── integration/
    ├── full-agent.test.ts
    ├── shortcut-expansion.test.ts
    └── semantic-highlighting.test.ts
```

### 12.3 Build Process Updates
```json
// package.json scripts
{
  "scripts": {
    "langium:generate": "langium generate",
    "langium:watch": "langium generate --watch",
    "build": "npm run langium:generate && tsc",
    "test": "vitest",
    "test:watch": "vitest --watch",
    "lint": "eslint src --ext ts",
    "validate:examples": "node bin/cli.js validate examples/*.rcl"
  }
}
```

## 13. Service Architecture

### 13.1 Complete Service Structure
```typescript
export type RclAddedServices = {
    validation: {
        RclValidator: RclValidator,
        DeprecationValidator: DeprecationValidator
    },
    transformation: {
        ShortcutExpander: ShortcutExpander,
        ExpressionEvaluator: ExpressionEvaluator,
        TypeConverter: TypeConverter
    },
    lsp: {
        SemanticTokensProvider: RclSemanticHighlighter,
        Formatter: RclFormatter
    }
}
```

### 13.2 New Services to Implement
- `ShortcutExpander` - Transform shortcuts to full syntax
- `ExpressionEvaluator` - Validate and process expressions
- `TypeConverter` - Handle type conversion validations
- `RclFormatter` - Code formatting with indentation support
- `DeprecationValidator` - Deprecated feature detection

## 14. VSCode Extension Enhancements

### 14.1 Enhanced Language Configuration
```json
// language-configuration.json updates
{
  "indentationRules": {
    "increaseIndentPattern": ":(\\s*)$",
    "decreaseIndentPattern": "^\\s*(DEDENT|\\})"
  },
  "folding": {
    "markers": {
      "start": "^\\s*\\w+\\s*:",
      "end": "^\\s*$"
    }
  }
}
```

### 14.2 Syntax Highlighting Updates
- Expression syntax highlighting
- Type conversion highlighting
- Multi-line string highlighting
- Shortcut syntax highlighting

## 15. Future Enhancements (Post-MVP)

### 15.1 Advanced Features
- Code completion for expressions
- Hover information for type conversions
- Refactoring support for shortcuts
- Live expression evaluation
- RCS specification updates integration

### 15.2 Tooling
- CLI commands for validation
- Batch processing tools
- Migration utilities
- Performance profiling

## 16. Success Criteria

### 16.1 Functional Requirements
- ✅ All features from `overview.md` implemented
- ✅ Indentation-sensitive parsing working
- ✅ Comprehensive validation with helpful errors
- ✅ Semantic highlighting in VSCode
- ✅ No deprecated RCS features
- ✅ Robust expression system
- ✅ Complete shortcut system

### 16.2 Quality Requirements
- ✅ 95%+ test coverage
- ✅ Performance: <100ms parse time for 1000-line files
- ✅ Memory: <50MB for typical projects
- ✅ Error recovery: Graceful handling of syntax errors
- ✅ Documentation: Complete API and user documentation

## 17. Comparison with Plan v1

### New Additions (vs Plan v1)
- ✅ Indentation-sensitive parsing configuration
- ✅ Complete expression system specification
- ✅ Multi-line string implementation
- ✅ Type conversion syntax
- ✅ RCS shortcut system
- ✅ Title identifier support
- ✅ Semantic highlighting service
- ✅ Deprecated feature removal
- ✅ Grammar modularization strategy
- ✅ Comprehensive validation framework

### Enhanced Areas
- More detailed grammar organization
- Specific validation categories
- Complete service architecture
- Advanced testing strategy
- VSCode extension enhancements

This plan provides a complete roadmap for implementing all RCL features while maintaining excellent developer experience and code quality. 