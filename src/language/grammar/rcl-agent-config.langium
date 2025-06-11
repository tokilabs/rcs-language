grammar RclAgentConfig

import "./rcl-common";

// ======== Config Section Rules ========
entry ConfigSection infers ConfigSection:
    'Config'
    // Properties from agent-config.schema.json#RcsBusinessMessagingAgent
    // All are optional as per typical config block nature and schema not always enforcing all.
    // Ordered sequence of optional properties.
    (('description' ':' description=STRING))?
    (('logoUri' ':' logoUri=STRING))?
    (('heroUri' ':' heroUri=STRING))?
    (phoneNumbers+=PhoneNumberProperty)*
    (emails+=EmailProperty)*
    (websites+=WebsiteProperty)*
    (privacy=PrivacyProperty)?
    (termsConditions=TermsConditionsProperty)?
    (('color' ':' color=STRING))? // Add validation for hex pattern later
    (billingConfig=BillingConfigProperty)?
    (('agentUseCase' ':' agentUseCase=ATOM))?
    (('hostingRegion' ':' hostingRegion=ATOM))?;

PhoneNumberProperty infers PhoneNumberProperty:
    'phoneNumberEntry' // Keyword to distinguish this block
    ('number' ':' number=STRING)
    (('label' ':' label=STRING))?;

EmailProperty infers EmailProperty:
    'emailEntry' // Keyword to distinguish this block
    ('address' ':' address=STRING)
    (('label' ':' label=STRING))?;

WebsiteProperty infers WebsiteProperty: // Used for general websites array
    'websiteEntry' // Keyword to distinguish this block
    ('url' ':' url=STRING)
    (('label' ':' label=STRING))?;

PrivacyProperty infers PrivacyProperty: // Specific property for privacy, maps to WebEntry schema
    'privacy' // Keyword is the property name
    ('url' ':' url=STRING)
    (('label' ':' label=STRING))?;

TermsConditionsProperty infers TermsConditionsProperty: // Specific property for terms, maps to WebEntry schema
    'termsConditions' // Keyword is the property name
    ('url' ':' url=STRING)
    (('label' ':' label=STRING))?;

BillingConfigProperty infers BillingConfigProperty:
    'billingConfig' // Keyword is the property name
        ('billingCategory' ':' billingCategory=ATOM);