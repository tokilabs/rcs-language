// ======== Terminals (Shared) ========
hidden terminal WS: /\s+/;
hidden terminal SL_COMMENT: /#.*/;

terminal ID: /[_a-zA-Z][\w_]*/;
terminal ATOM: /:([_a-zA-Z][\w_]*|\"[^\"\\]*\")/;
terminal STRING: /\"(\\.|[^\"\\])*\"/;
terminal NUMBER returns number: /[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?/;
terminal TIME_LITERAL: /~T\[[0-9]{2}:[0-9]{2}\]/; // "~T[HH:MM]"
terminal ISO_DURATION_LITERAL: /(P(\d+Y)?(\d+M)?(\d+W)?(\d+D)?(T(\d+H)?(\d+M)?(\d+(\.\d+)?S)?)?)|([0-9]+(\.[0-9]+)?s)/; // ISO 8601 Duration or simple seconds like "3.5s"

// ======== Basic Shared Types & Rules ========
QualifiedName returns string:
    ID ('.' ID)*;

SimpleValue returns string:
    STRING | NUMBER | BooleanLiteral | ATOM | TIME_LITERAL | ISO_DURATION_LITERAL;

BooleanLiteral returns boolean:
    'true' | 'false';

ExplicitMap infers ExplicitMap:
    '%' '{' (entries+=PropertyAssignment)* '}';

InlineParameterList infers InlineParameterList:
    (parameters+=Parameter (',' parameters+=Parameter)*);

Parameter infers Parameter: // Used in WithClause and InlineParameterList
    name=ID ':' value=SimpleValue;

PropertyAssignment infers PropertyAssignment: // Used in ExplicitMap
    key=ID ':' value=Value;

Value infers Value: // General value holder, used by PropertyAssignment
    SimpleValue | ExplicitMap | InlineParameterList | Ref;

// ======== Abstract Named Section & Ref (Shared) ========
interface AbstractNamedSection {
    name: string
}

Ref infers Ref:
    target=[AbstractNamedSection:ID];