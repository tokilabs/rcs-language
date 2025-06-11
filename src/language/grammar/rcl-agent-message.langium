grammar RclAgentMessage

import "./rcl-common";

// ======== Messages Section Details: AgentMessage and its components ========
entry AgentMessage infers AgentMessage:
    'agentMessage' (messageName=ID)? // Optional name for the message block
    // Ordered sequence.
    ('messageTrafficType' ':' messageTrafficType=ATOM) // Now mandatory
    ((('expireTime' ':' expireTime=STRING) | ('ttl' ':' ttl=ISO_DURATION_LITERAL)))? // oneOf expireTime/ttl, whole group optional
    (contentMessage=ContentMessage);

ContentMessage infers ContentMessage:
    'contentMessage'
    // oneOf for the main content type - this block is now mandatory
    (
        ('text' ':' text=STRING) |
        ('fileName' ':' fileName=STRING) |
        ('uploadedRbmFile' uploadedRbmFile=UploadedRbmFile) |
        ('richCard' richCard=RichCard) |
        ('contentInfo' contentInfo=ContentInfo)
    )
    (suggestions+=Suggestion)*;

Suggestion infers Suggestion:
    'suggestion'
    (
        ('reply' reply=SuggestedReply) |
        ('action' action=SuggestedAction)
    );

SuggestedReply infers SuggestedReply:
    content=InlineParameterList; // Parses text: STRING, postbackData: STRING

SuggestedAction infers SuggestedAction:
    (props=InlineParameterList)? // Parses text: STRING, postbackData: STRING, fallbackUrl: STRING?
    (
        ('dialAction' dialAction=DialAction) |
        ('viewLocationAction' viewLocationAction=ViewLocationAction) |
        ('createCalendarEventAction' createCalendarEventAction=CreateCalendarEventAction) |
        ('openUrlAction' openUrlAction=OpenUrlAction) |
        ('shareLocationAction' shareLocationAction=ShareLocationAction) |
        ('composeAction' composeAction=ComposeAction)
    );

// --- Action Types ---
DialAction infers DialAction:
    ('phoneNumber' ':' phoneNumber=STRING);

LatLongObject infers LatLongObject: // New rule for the latLong structure, used by ViewLocationAction
    content=InlineParameterList; // Parses latitude: NUMBER, longitude: NUMBER

ViewLocationAction infers ViewLocationAction:
    // Ordered sequence
    ('label' ':' label=STRING)?
    (
        ('latLong' latLong=LatLongObject) |
        ('query' ':' query=STRING)
    );

CreateCalendarEventAction infers CreateCalendarEventAction:
    content=InlineParameterList; // Parses startTime, endTime, title, description

ShareLocationAction infers ShareLocationAction:
    {infer ShareLocationAction} 'shareLocationAction';

OpenUrlAction infers OpenUrlAction:
    ('url' ':' url=STRING);

ComposeAction infers ComposeAction:
    (
        ('composeTextMessage' composeTextMessage=ComposeTextMessage) |
        ('composeRecordingMessage' composeRecordingMessage=ComposeRecordingMessage)
    );

ComposeTextMessage infers ComposeTextMessage:
    content=InlineParameterList; // Parses phoneNumber: STRING, text: STRING

ComposeRecordingMessage infers ComposeRecordingMessage:
    content=InlineParameterList; // Parses phoneNumber: STRING, type: ATOM

// --- File and Content Info ---
UploadedRbmFile infers UploadedRbmFile:
    ( explicitMap=ExplicitMap |
      props=InlineParameterList // Parses fileName: STRING, thumbnailUrl: STRING?, thumbnailName: STRING?
    );

ContentInfo infers ContentInfo:
    ( explicitMap=ExplicitMap |
      props=InlineParameterList // Parses fileUrl: STRING, thumbnailUrl: STRING?, forceRefresh: BooleanLiteral?, altText: STRING?
    );

// --- Rich Card Components ---
RichCard infers RichCard:
    (
        ('standaloneCard' standaloneCard=StandaloneCard) |
        ('carouselCard' carouselCard=CarouselCard)
    );

StandaloneCard infers StandaloneCard:
    // Ordered sequence
    ('cardOrientation' ':' cardOrientation=ATOM)
    ('thumbnailImageAlignment' ':' thumbnailImageAlignment=ATOM)?
    ('cardContent' cardContent=CardContent);

CarouselCard infers CarouselCard:
    // Ordered sequence
    ('cardWidth' ':' cardWidth=ATOM)
    (cardContents+=CardContent cardContents+=CardContent+); // Requires at least two CardContent elements

CardContent infers CardContent:
    // Ordered sequence
    ('title' ':' title=STRING)
    ('description' ':' description=STRING)?
    ('media' media=Media)?
    (suggestions+=CardSuggestion)*;

CardSuggestion infers CardSuggestion:
    'suggestion'
    (
        ('reply' reply=SuggestedReply) |
        ('action' action=SuggestedAction)
    );

Media infers Media:
    // Ordered sequence now
    ('height' ':' height=ATOM)
    (
        ('file' file=UploadedRbmFile) |
        ('contentInfo' contentInfo=ContentInfo)
    );