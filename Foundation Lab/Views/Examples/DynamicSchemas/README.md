# Dynamic Schema Examples

This directory contains comprehensive examples demonstrating the use of `DynamicGenerationSchema` in the Foundation Models Framework. These examples show how to create schemas at runtime for flexible data extraction.

## Overview

`DynamicGenerationSchema` allows you to build schemas dynamically at runtime, unlike the static `@Generable` attribute. This is useful when:
- Schema structure is determined by user input
- You need to adapt to changing data formats
- Building generic tools that work with various data structures
- Creating form builders or configuration-driven extraction

## Examples

### 1. Basic Object Schema (`BasicDynamicSchemaView.swift`)
- **Concepts**: Creating simple object schemas with properties
- **Examples**: Person info, Product details, Custom objects
- **Key Features**:
  - Basic property types (String, Int, Float)
  - Simple object creation
  - Converting to GenerationSchema

### 2. Array Schemas (`ArrayDynamicSchemaView.swift`)
- **Concepts**: Arrays with min/max constraints
- **Examples**: Todo lists, Recipe ingredients, Article tags
- **Key Features**:
  - Array constraints (minimumElements, maximumElements)
  - Arrays of objects vs simple types
  - Dynamic constraint adjustment

### 3. Enum Schemas (`EnumDynamicSchemaView.swift`)
- **Concepts**: String enumerations using anyOf
- **Examples**: Sentiment analysis, Priority levels, Weather conditions
- **Key Features**:
  - anyOf with string choices
  - Custom choice sets
  - Validation of generated values

### 4. Nested Objects (`NestedDynamicSchemaView.swift`)
- **Concepts**: Complex nested structures
- **Examples**: Company structure, Order details, Event information
- **Key Features**:
  - Multiple nesting levels
  - Objects within objects
  - Arrays of nested objects
  - Dependency management

### 5. Schema References (`ReferencedSchemaView.swift`)
- **Concepts**: Reusing schemas through references
- **Examples**: Blog system, Project teams, Library catalog
- **Key Features**:
  - DynamicGenerationSchema.init(referenceTo:)
  - Avoiding duplication
  - Circular references support
  - Consistent data structures

### 6. Optional Fields (`OptionalFieldsSchemaView.swift`)
- **Concepts**: Required vs optional properties
- **Key Features**:
  - isOptional parameter
  - Handling missing data
  - Validation strategies

### 7. Generation Guides (`GuidedDynamicSchemaView.swift`)
- **Concepts**: Applying constraints to values
- **Key Features**:
  - String patterns with regex
  - Number ranges
  - Constant values
  - Array length limits

### 8. Union Types (`UnionTypesSchemaView.swift`)
- **Concepts**: anyOf with different object types
- **Key Features**:
  - Polymorphic schemas
  - Type discrimination
  - Multiple type alternatives

### 9. Form Builder (`FormBuilderSchemaView.swift`)
- **Concepts**: Building forms dynamically
- **Use Case**: User-defined data extraction

### 10. Error Handling (`SchemaErrorHandlingView.swift`)
- **Concepts**: Handling schema errors
- **Topics**:
  - Duplicate type names
  - Undefined references
  - Empty type choices
  - Circular dependencies

### 11. Invoice Processing (`InvoiceProcessingSchemaView.swift`)
- **Concepts**: Real-world complex extraction
- **Features**: Complete invoice data model

## Code Patterns

### Basic Schema Creation
```swift
let schema = DynamicGenerationSchema(
    name: "Person",
    description: "A person",
    properties: [
        DynamicGenerationSchema.Property(
            name: "name",
            description: "Full name",
            schema: .init(type: String.self)
        )
    ]
)
```

### Using References
```swift
let schema = DynamicGenerationSchema.Property(
    name: "author",
    schema: .init(referenceTo: "Person")
)
```

### Array Constraints
```swift
let arraySchema = DynamicGenerationSchema(
    arrayOf: itemSchema,
    minimumElements: 2,
    maximumElements: 5
)
```

### Converting to GenerationSchema
```swift
let schema = try GenerationSchema(
    root: rootSchema,
    dependencies: [schema1, schema2, ...]
)
```

## Edge Cases Handled

1. **Empty arrays** - When minimum is 0
2. **Circular references** - Person → Book → Person
3. **Deep nesting** - Multiple levels of nested objects
4. **Missing optional fields** - Graceful handling
5. **Invalid enum values** - Validation and error reporting
6. **Schema name conflicts** - Error detection
7. **Dynamic schema updates** - Runtime modifications

## Best Practices

1. **Always register dependencies** - Include all referenced schemas
2. **Use descriptive names** - Help the model understand intent
3. **Provide descriptions** - Natural language hints improve accuracy
4. **Test edge cases** - Validate with minimal and maximal data
5. **Handle errors gracefully** - Catch and display schema errors
6. **Keep schemas focused** - Single responsibility per schema

## Integration Tips

- Use with `LanguageModelSession.respond(to:schema:)`
- Set `temperature: 0.1` for consistent extraction
- Include schema in prompt for better results
- Validate extracted data against constraints
- Consider performance for deeply nested schemas
