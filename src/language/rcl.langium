grammar Rcl

import "./grammar/rcl-common";
import "./grammar/rcl-agent-config";
import "./grammar/rcl-agent-message";

entry RclFile infers RclFile:
    (imports+=ImportStatement)*
    AgentDefinition;

// ======== Import Management ========
// The AbstractNamedSection interface is defined in rcl-common.langium
// FlowSection below infers it, enabling it for cross-references.
ImportStatement infers ImportStatement:
    'import' source=STRING ('as' alias=ID)? ';';

// ======== Agent Definition ========
// QualifiedName, ConfigSection, AgentMessage are imported.
AgentDefinition infers AgentDefinition:
    'Agent' name=QualifiedName
    ('displayName' ':' displayName=STRING)
    ('brandName' ':' brandName=STRING)?
    (config=ConfigSection)?
    (defaults=DefaultsSection)?
    (flows+=FlowSection)+
    (messages=MessagesSection);

// ======== Sections retained in main grammar ========
// DefaultsSection uses imported ATOM, STRING, ISO_DURATION_LITERAL
DefaultsSection infers DefaultsSection:
    'Defaults'
    (('fallback_message' ':' fallback_message=STRING))?
    (('messageTrafficType' ':' messageTrafficType=ATOM))?
    (('ttl' ':' ttl=ISO_DURATION_LITERAL))?;

// FlowSection should implicitly be compatible with AbstractNamedSection (imported from rcl-common)
// due to its 'name: ID' property, without needing explicit 'infers'.
FlowSection infers FlowSection:
    'flow' name=ID // ID is an imported terminal
    (rules+=FlowRule)*;

// MessagesSection uses imported AgentMessage
MessagesSection infers MessagesSection:
    'Messages'
    (messages+=AgentMessage)*;

// ======== Flow Section Details ========
// FlowRule uses local FlowOperand, FlowOperandOrRef, WithClause
FlowRule infers FlowRule:
    from=FlowOperand ('->' to+=FlowOperandOrRef)+ (withClause=WithClause)?;

// FlowOperand uses imported ATOM, ID, STRING terminals
FlowOperand returns string:
    ATOM | ID | STRING;

// FlowOperandOrRef uses local FlowOperand, imported Reference, local FlowActionText
FlowOperandOrRef:
    FlowOperand | 'ref' Ref | FlowActionText;

// WithClause uses imported Parameter
WithClause infers WithClause:
    'with' (params+=Parameter (',' params+=Parameter)*);

// Rule for text action in flows - uses imported STRING terminal
FlowActionText infers FlowActionText:
    'text' message=STRING;

// All terminals (ID, ATOM, STRING, NUMBER, BooleanLiteral, TIME_LITERAL, ISO_DURATION_LITERAL, WS, SL_COMMENT)
// and common rules (QualifiedName, SimpleValue, ExplicitMap, InlineParameterList, Parameter, PropertyAssignment, Value, Ref)
// and the AbstractNamedSection interface are now defined in and imported from grammar/rcl-common.langium.

// Config-specific rules (ConfigSection, PhoneNumberProperty, etc.) are imported from grammar/rcl-agent-config.langium.

// Message-specific rules (AgentMessage, ContentMessage, Suggestion, all Actions, RichCard components, etc.) are imported from grammar/rcl-agent-message.langium.
