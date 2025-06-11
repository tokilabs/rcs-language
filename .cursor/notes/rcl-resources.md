# RCL Language Development Resources

This note collects useful links and resources for the development of the Rich Communication Language (RCL) and its tooling.

## Langium Core & Language Design

-   **Langium Documentation**: Main portal for Langium.
    -   [Semantic Model Inference](https://langium.org/docs/reference/semantic-model/): Explains how Langium derives AST types from the grammar (inferred vs. declared). Useful for understanding AST generation and how to create stable semantic models.
    -   [Indentation-Sensitive Languages](https://langium.org/docs/recipes/lexing/indentation-sensitive-languages/): Describes how to implement strict indentation using a custom lexer with `INDENT`/`DEDENT` tokens. Relevant for potential future enhancement of RCL.
    -   [Built-in Libraries](https://langium.org/docs/recipes/builtin-library/): Discusses reusing common grammar constructs or creating standard libraries for Langium languages. Potentially useful if RCL or related DSLs expand.
    -   [Formatting](https://langium.org/docs/recipes/formatting/): Guide to implementing auto-formatting for a Langium language. A future enhancement for RCL developer experience.
    -   [Keywords as Identifiers](https://langium.org/docs/recipes/keywords-as-identifiers/): How to allow keywords to be used as identifiers in specific contexts. Not directly planned for RCL but good to know.
    -   [Multiple Dependent Languages](https://langium.org/docs/recipes/multiple-languages/): How to split a single language grammar into multiple interdependent `.langium` files. Potentially useful if RCL grammar becomes very large.
    -   [File-Based Scoping](https://langium.org/docs/recipes/scoping/file-based/): **Crucial for RCL imports**. Details how to make cross-references work across files using `ScopeProvider` and `IndexManager`.
    -   [Qualified Name Scoping](https://langium.org/docs/recipes/scoping/qualified-name/): Implementing scoping for qualified names (e.g., `my.module.MyClass`). Relevant if RCL evolves more complex namespacing.
    -   [Validation - Dependency Loops](https://langium.org/docs/recipes/validation/dependency-loops/): **Important for RCL imports and flow calls**. How to detect and report circular dependencies.
    -   [Configuration via Services](https://langium.org/docs/reference/configuration-services/): Overview of Langium services and their configuration. Fundamental for custom language features.

## Web IDE & Tooling

-   **Monaco Editor & Langium (Potentially Outdated Tutorials)**:
    -   [Langium + Monaco Editor (Minilogo Tutorial)](https://langium.org/docs/learn/minilogo/langium_and_monaco/): Official tutorial, noted as potentially outdated. Describes setting up Langium with Monaco Editor for web-based LSP support.
    -   [Generation in the Web (Minilogo Tutorial)](https://langium.org/docs/learn/minilogo/generation_in_the_web/): Companion to the Monaco tutorial, focusing on running code generation (transpilation) in the browser. Also potentially outdated.
-   **AST Transformation & Helpers**:
    -   [langium-ast-helper (npm)](https://www.npmjs.com/package/langium-ast-helper): A package for AST transformations, converting Langium ASTs into other data formats (e.g., graphs). Useful for data analysis or custom visualizations based on the AST, and potentially for the transpiler if direct AST traversal is not preferred.
-   **Type Checking (Advanced)**:
    -   [Typir (GitHub - typefox/typir)](https://github.com/typefox/typir): A library for type checking, with Langium integration examples. Could be relevant if RCL develops a more complex internal type system beyond schema validation.

## Diagramming & Visualization (Future Development)

-   **Sprotty & Langium Integration**: For displaying RCL flows as diagrams.
    -   [langium-sprotty (GitHub - eclipse-langium/langium/packages/langium-sprotty)](https://github.com/eclipse-langium/langium/tree/main/packages/langium-sprotty): Official Langium integration package for Sprotty, a graphical framework.
    -   [Sprotty Homepage](https://sprotty.org/): Main website for the Sprotty diagramming framework.
    -   [sprotty-vscode (npm)](https://www.npmjs.com/package/sprotty-vscode): VS Code integration library for Sprotty diagrams, enabling them within the editor.

## RCL Project Specific Files (Examples & Schemas)

-   `spec/agent-example.rcl`: Example RCL file demonstrating language usage.
-   `spec/agent-message.schema.json`: JSON schema for agent messages.
-   `spec/agent-config.schema.json`: JSON schema for agent configuration. 