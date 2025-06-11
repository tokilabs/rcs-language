# Rich Communication Language (RCL) Implementation Plan

## 1. Overview & Goals

-   **RCL**: A human-readable, indentation-guided Domain Specific Language (DSL) for defining RCS Business Messaging agents.
-   **Primary Goal**: Transpile RCL files into JSON that strictly conforms to `agent-config.schema.json` and `agent-message.schema.json`.
-   **Secondary Goal**: Provide a good developer experience with clear syntax, robust validation, and helpful error messages through IDE support (leveraging Langium services).

## 2. Core Language Structure (Grammar - `rcl.langium`)

-   **Entry Point**: `RclFile` contains optional `ImportStatement`s followed by one `AgentDefinition`.
-   **Agent Definition** (`AgentDefinition` rule):
    -   Starts with the keyword `Agent` followed by a `QualifiedName`.
    -   **Direct Agent Properties**: Explicit properties like `displayName: STRING`, `brandName: STRING` directly under the `Agent` declaration (maps to `agent-config.schema.json` top-level fields).
    -   **Sections** (each introduced by its keyword):
        -   `Config` section (optional): Contains explicit properties mapping to `rcsBusinessMessagingAgent` object in `agent-config.schema.json`.
        -   `Defaults` section (optional): Contains explicit properties for message defaults (e.g., `fallback_message: STRING`, `messageTrafficType: ATOM`).
        -   One or more named `Flow` definitions (e.g., `flow FlowName ...`).
        -   `Messages` section (mandatory): Contains one or more `agentMessage` definitions.
-   **Imports** (`ImportStatement` rule):
    -   Initial: `import "./path/to/another.rcl";`
    -   AST includes `AbstractNamedSection` interface for linkable elements.
-   **Lexical Elements (Terminals)**: `ID`, `QUALIFIED_NAME`, `STRING`, `ATOM`, `NUMBER`, `BOOLEAN_LITERAL`, `TIME_LITERAL`, `ISO_DURATION_LITERAL`, `SL_COMMENT`.
-   **Semantic Model**: Primarily uses inferred types from grammar rules. Explicitly declared `interface AbstractNamedSection` is used for common contracts (e.g., linkable items). As the language matures, more core AST nodes might become explicitly declared interfaces in the grammar for enhanced stability.

## 3. Detailed Grammar Strategy for Schema Compliance

-   **Key Principle: Explicit Properties over Generic Assignments**.
    -   Grammar rules for constructs mapping to JSON objects (e.g., `AgentMessage`, `DialAction`) will explicitly define allowed attributes based on schemas and `agent-example.rcl`.
-   **Schema Mapping Process**:
    -   JSON `properties` -> specific Langium assignments.
    -   `enum` values -> `ATOM`s or specific string literals.
    -   `oneOf` -> Langium alternatives (`|`).
    -   `required` properties -> non-optional Langium assignments.
    -   Arrays -> `+=` assignments on repeatable rules.

## 4. Flow Section Details

-   Multiple `Flow` definitions allowed directly under `AgentDefinition`.
-   Each `Flow` (`flow FlowName ...`) has a unique `name` (ID).
-   Contains `FlowRule`s: `fromOperand -> toOperandOrRef (-> toOperandOrRef)* (withClause)?`.
    -   `toOperandOrRef`: Can be `FlowOperand` or a `Reference` to a named section (e.g., an imported `Flow`).

## 5. Semantic Validation (TypeScript - `RichCommunicationLanguageValidator`)

-   **Agent Level Checks**:
    -   Unique flow names within an agent.
    -   Flow names not "Config", "Defaults", "Messages".
    -   If multiple flows, one must have a `:start -> SomeState` rule.
-   **Schema Compliance Checks (Beyond Grammar)**:
    -   String patterns (e.g., URIs, hex colors if not terminal-specific).
    -   Min/max item counts for arrays.
    -   Inter-field dependencies.
    -   `ATOM` values match schema enums.
-   **Reference Resolution**: Ensure `Reference`s point to valid declared/imported sections.
-   **Dependency Loops**: Detect and report circular dependencies in imports and flow calls (referencing Langium recipes for strategy).

## 6. Linking and Scoping (TypeScript - `RichCommunicationLanguageScopeProvider`, `Linker`, `IndexManager`)

-   Implement services to handle `ImportStatement`s and resolve `Reference`s.
-   This will heavily rely on Langium's `ScopeProvider`, `Linker`, and `IndexManager` for file-based scoping, enabling references to definitions in other RCL files as per Langium documentation ([File-based scoping](https://langium.org/docs/recipes/scoping/file-based/)).

## 7. Indentation

-   Grammar structure guides indentation-based syntax.
-   Strict `INDENT`/`DEDENT` token-based parsing (as per Langium recipe) is a potential future enhancement if needed for more rigid error reporting on indentation, but not for the initial version.

## 8. Transpilation to JSON

-   Dedicated service to traverse validated AST and map RCL constructs to JSON (conforming to `agent-config.schema.json` and `agent-message.schema.json`).

## 9. Development Steps & Priorities

1.  **Refine Grammar (Iterative Process)**:
    *   **Done**: Agent-level properties (`displayName`, `brandName`), explicit properties for `ConfigSection`, `DefaultsSection`, `AgentMessage`, `ContentMessage`, and Action types (including `ViewLocationAction` with `LatLongObject`).
    *   **Systematic Schema Walkthrough (Ongoing/Final Check)**: Ensure all properties within `MessagesSection` sub-components (`Suggestion`, `RichCard`, `StandaloneCard`, `CarouselCard`, `CardContent`, `Media`, `UploadedRbmFile`, `ContentInfo`) are explicitly and accurately defined in the grammar according to `agent-message.schema.json` and `agent-example.rcl`.
2.  **Generate Langium Artifacts**: `npm run langium:generate` (or equivalent) after grammar modifications.
3.  **Address Linter/Parser Errors**: Iteratively test with `spec/agent-example.rcl` and other test cases.
4.  **Implement Semantic Validators (TypeScript)**:
    *   Core agent-level checks (flow uniqueness, reserved names, `:start` rule).
    *   Schema compliance (patterns, counts, enums, dependencies).
    *   Circular dependency checks for imports/flows.
5.  **Implement Linking and Scoping (TypeScript)**:
    *   Focus on `ImportStatement` and `Reference` resolution using Langium's `ScopeProvider`, `Linker`, and `IndexManager` (critical for imports).
6.  **Develop Transpiler (TypeScript)**.
7.  **Write Comprehensive Tests**.
8.  **Future Enhancements (Post-MVP)**:
    *   Strict `INDENT`/`DEDENT` lexer for indentation.
    *   Code Formatter (`Langium Formatter` service).
    *   Custom CLI for RCL tooling.

This plan prioritizes a robust, schema-compliant grammar and core validation, with clear steps for enabling modularity via imports.

## 10. Web IDE with Monaco Editor & Live JSON Generation (Future Goal)

-   **Goal**: Create a web page with Monaco Editor for RCL, providing language support (syntax highlighting, validation from LSP) and live transpilation/display of the generated JSON output.
-   **Core Components**:
    -   **Browser-Compatible Language Server (LSP Worker)**:
        -   Create `src/language-server/rcl-main-browser.ts` (or similar path).
            -   Utilize `startLanguageServer` from `langium`.
            -   Use `EmptyFileSystem` (as files will be in-memory in the editor context).
            -   Employ `BrowserMessageReader` and `BrowserMessageWriter` from `vscode-languageserver/browser`.
            -   Inject `createRclServices` (your language-specific services module).
        -   Bundle this `rcl-main-browser.ts` into a single web worker JavaScript file (e.g., using `esbuild`, output to `public/rcl-server-worker.js`). This worker will run the Langium language server in the browser.
    -   **Monaco Editor Client (HTML, CSS, JavaScript)**:
        -   Use `monaco-editor-wrapper` for easier integration of Monaco Editor with LSP capabilities.
        -   **HTML Structure**: An HTML page with a `div` for the Monaco editor instance and another `div` (or `pre` tag) to display the generated JSON output.
        -   **Client-Side JavaScript**:
            -   Instantiate and configure `MonacoEditorLanguageClientWrapper`.
            -   Provide `UserConfig` to the wrapper, specifying:
                -   The HTML element for the editor.
                -   Basic editor options (e.g., theme, initial RCL code).
                -   RCL language definition for Monaco:
                    -   `languageId` (e.g., `'rcl'`).
                    -   `extensions` (e.g., `['.rcl']`).
                    -   A Monarch syntax highlighting grammar for RCL. This can be generated by `langium-cli` (configure in `langium-config.json` to output Monarch syntax).
                -   Language client configuration pointing to the path of the bundled `public/rcl-server-worker.js`.
            -   Start the `MonacoEditorLanguageClientWrapper`.
-   **Live JSON Generation and Display Workflow**:
    -   **Language Server Side (`rcl-main-browser.ts`) Modification**:
        -   Access the `shared.workspace.DocumentBuilder` from the injected services.
        -   Subscribe to the document build lifecycle: `DocumentBuilder.onBuildPhase(DocumentState.Validated, documents => { ... })`.
        -   Inside the handler, for each validated document:
            -   Retrieve the parsed AST (`document.parseResult.value`).
            -   Perform the RCL-to-JSON transpilation using your existing transpiler logic (this logic needs to be callable from the browser worker, ensure it has no Node.js-specific dependencies if run client-side, or keep it in the worker).
            -   Send a custom LSP notification from the server to the client (e.g., `textDocument/rclGeneratedJson`) with a payload like `{ uri: document.uri.toString(), jsonContent: string }`.
    -   **Client Side (Monaco Page JavaScript) Modification**:
        -   After the `MonacoEditorLanguageClientWrapper` has started, obtain the underlying `LanguageClient` instance.
        -   Register a notification handler for `textDocument/rclGeneratedJson` on this client.
        -   When the notification is received, take the `jsonContent` from the payload and update the designated HTML element on the page to display it (e.g., set the `textContent` of a `<pre>` tag).
-   **Build Process for Web Application**:
    -   Add/update `package.json` scripts to:
        -   Build the RCL language server for Node.js (for VS Code extension, if separate).
        -   Build the browser-compatible language server worker (`rcl-server-worker.js`).
        -   Copy necessary assets (Monaco editor files, `monaco-editor-wrapper` assets, the worker script, HTML, CSS) to a `public` directory.
    -   A simple HTTP server (e.g., Node.js `http` module, `express`, or `vite` dev server) to serve the contents of the `public` directory.
-   **Primary References & Guidance**:
    -   Adapt fundamental concepts from Langium's official (but marked as outdated) Monaco tutorials: [Langium + Monaco Editor](https://langium.org/docs/learn/minilogo/langium_and_monaco/) and [Generation in the Web](https://langium.org/docs/learn/minilogo/generation_in_the_web/).
    -   Consult newer articles or examples for `monaco-editor-wrapper` if specific API details from the old tutorials don't work (e.g., [Zuehlke article on Angular/Monaco/LSP](https://software-engineering-corner.zuehlke.com/develop-a-web-editor-for-your-dsl-using-angular-and-monaco-editor-library-with-language-server-support)).

This addition outlines a clear path for the Web IDE feature, treating it as a future goal built upon the core language services. 