# Plan for Implementing Concise DSL Macros for RcsLang

## Key Features to Support

1. **English-like `with` Syntax**
   - `status_response with appointment: 1, time: ~T[10:00]` expands to a tuple or struct representing a transition with parameters.

2. **Flow Macro**
   - `flow do ... end` block parses transitions, including `->`, `cond do ... end`, and supports the `with` macro.

3. **Messages Macro**
   - `messages do ... end` block supports both concise and formal syntax for messages, including `text ... do ... end` and `agentMessage do ... end` forms, and `cond do ... end` for conditional message variants.

4. **Macros for Suggestions and Inputs**
   - `reply(...)`, `action(...)`, `share_location(...)`, etc.
   - `input(:id, :time)` to declare required input variables for a message.

5. **RichCard and Media Macros**
   - `richCard do ... end`, `standaloneCard do ... end`, `media do ... end`, etc.
   - Support for both `contentInfo` and `uploadedRbmFile` as mutually exclusive options.

## Implementation Steps

1. **Create Macro Modules**
   - `lib/rcs_lang/flow_dsl/macros.ex` for the flow and messages DSL.
   - `lib/rcs_lang/macros/suggestions.ex` for suggestion macros.
   - `lib/rcs_lang/macros/messages.ex` for message macros (text, rich_card, etc.).

2. **Implement the `with` Macro**
   - Define a macro that allows `message_key with key: value, ...` and expands to a tuple or struct.

3. **Implement the `flow` Macro**
   - Parse the block, handle transitions, and support the `with` macro in transitions.

4. **Implement the `messages` Macro**
   - Parse the block, support both concise and formal message definitions, and handle `cond do ... end`.

5. **Implement Suggestion and Message Macros**
   - Implement `reply/1`, `action/1`, `share_location/1`, `text/2`, `richCard/1`, etc.

## Example: Implementing the `with` Macro

```elixir
defmacro with(args) do
  quote do
    {:with, unquote(Macro.escape(args))}
  end
end
```

In the flow macro, pattern match on:
```elixir
status_response with appointment: 1, time: ~T[10:00]
# expands to
{:status_response, %{appointment: 1, time: ~T[10:00]}}
```

## Next Steps

- Scaffold macro modules.
- Implement the `with` macro and the `flow` macro parser.
- Implement the `messages` macro and suggestion/message macros.

## Next Steps (Immediate)

- Enhance `RcsLang.Macros.Messages` to support `rich_card` and its nested components (`standalone_card`, `carousel_card`, `card_content`, `media`, `content_info` (for media), `uploaded_rbm_file` (for media)).
- Update the main `RcsLang` module to properly import and manage the concise macros alongside the Spark DSL, if necessary (currently imports them directly).
- Refine the main `messages` macro in `RcsLang.FlowDsl.Macros` (or a similar place) to correctly parse and store message definitions that use these new concise macros.
- Add tests for the new concise macros. 