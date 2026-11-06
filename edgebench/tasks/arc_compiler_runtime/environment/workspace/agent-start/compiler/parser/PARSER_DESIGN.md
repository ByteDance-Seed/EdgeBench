# Arc Parser Design

**Purpose:** Detailed design for the Arc parser implementation.

**Author:** Subagent 2 (Arc Compiler Architect)  
**Last Updated:** 2026-02-16  
**Status:** Phase 0 - Implementation Blueprint

---

## Overview

The Arc parser transforms a token stream into an Abstract Syntax Tree (AST) using:
- **Recursive Descent** for statements and declarations
- **Pratt Parsing** for expressions (operator precedence)
- **Unified Pattern Parser** for destructuring, match arms, function parameters

---

## Parser Architecture

### Core Structure

```rust
pub struct Parser {
    tokens: Vec<Token>,
    current: usize,
    errors: Vec<ParseError>,
    panic_mode: bool,
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Self { ... }
    
    pub fn parse(&mut self) -> Result<Program, Vec<ParseError>> { ... }
    
    // Token manipulation
    fn peek(&self) -> &Token { ... }
    fn advance(&mut self) -> &Token { ... }
    fn check(&self, kind: TokenKind) -> bool { ... }
    fn match_token(&mut self, kinds: &[TokenKind]) -> bool { ... }
    fn expect(&mut self, kind: TokenKind, message: &str) -> Result<&Token, ParseError> { ... }
    
    // Error handling
    fn error(&mut self, message: &str) -> ParseError { ... }
    fn synchronize(&mut self) { ... }
    fn in_panic_mode(&self) -> bool { ... }
}
```

### Program Structure

```rust
pub struct Program {
    pub statements: Vec<Statement>,
    pub span: Span,
}
```

---

## 1. Top-Level Parsing

### Entry Point

```rust
impl Parser {
    pub fn parse(&mut self) -> Result<Program, Vec<ParseError>> {
        let mut statements = Vec::new();
        
        while !self.is_at_end() {
            match self.parse_statement() {
                Ok(stmt) => statements.push(stmt),
                Err(err) => {
                    self.errors.push(err);
                    self.synchronize();
                }
            }
        }
        
        if self.errors.is_empty() {
            Ok(Program { statements, span: self.span_from(0) })
        } else {
            Err(self.errors.clone())
        }
    }
}
```

### Statement Parsing

```rust
impl Parser {
    fn parse_statement(&mut self) -> Result<Statement, ParseError> {
        match self.peek().kind {
            TokenKind::Fn => self.parse_function_decl(),
            TokenKind::Let => self.parse_let_statement(),
            TokenKind::Type => self.parse_type_decl(),
            TokenKind::Return => self.parse_return_statement(),
            TokenKind::Break => self.parse_break_statement(),
            TokenKind::Continue => self.parse_continue_statement(),
            _ => {
                // Try parsing as expression statement
                let expr = self.parse_expression()?;
                Ok(Statement::Expr(expr))
            }
        }
    }
}
```

---

## 2. Declaration Parsing

### Function Declaration

```rust
// Syntax: fn name(param1, param2, ...) => expr
//         fn name(param1, param2, ...) { body }
fn parse_function_decl(&mut self) -> Result<Statement, ParseError> {
    let start = self.expect(TokenKind::Fn, "Expected 'fn'")?;
    
    let name = self.expect(TokenKind::Identifier, "Expected function name")?;
    
    self.expect(TokenKind::LeftParen, "Expected '(' after function name")?;
    
    let params = self.parse_parameter_list()?;
    
    self.expect(TokenKind::RightParen, "Expected ')' after parameters")?;
    
    // Optional return type
    let return_type = if self.match_token(&[TokenKind::Colon]) {
        Some(self.parse_type()?)
    } else {
        None
    };
    
    // Function body
    let body = if self.match_token(&[TokenKind::FatArrow]) {
        // Single expression: fn double(x) => x * 2
        let expr = self.parse_expression()?;
        Box::new(Expr::Block {
            statements: vec![],
            expr: Some(Box::new(expr)),
            span: expr.span(),
        })
    } else if self.check(TokenKind::LeftBrace) {
        // Block body: fn double(x) { return x * 2 }
        Box::new(self.parse_block_expression()?)
    } else {
        return Err(self.error("Expected '=>' or '{' after function signature"));
    };
    
    Ok(Statement::Function {
        name: name.lexeme.clone(),
        params,
        return_type,
        body,
        span: start.span.to(body.span()),
    })
}
```

### Parameter List

```rust
fn parse_parameter_list(&mut self) -> Result<Vec<Parameter>, ParseError> {
    let mut params = Vec::new();
    
    if self.check(TokenKind::RightParen) {
        return Ok(params); // No parameters
    }
    
    loop {
        let pattern = self.parse_pattern()?;
        
        // Optional type annotation
        let type_annotation = if self.match_token(&[TokenKind::Colon]) {
            Some(self.parse_type()?)
        } else {
            None
        };
        
        params.push(Parameter {
            pattern,
            type_annotation,
        });
        
        if !self.match_token(&[TokenKind::Comma]) {
            break;
        }
    }
    
    Ok(params)
}
```

### Let Statement

```rust
// Syntax: let pattern = expr
//         let pattern: Type = expr
fn parse_let_statement(&mut self) -> Result<Statement, ParseError> {
    let start = self.expect(TokenKind::Let, "Expected 'let'")?;
    
    let pattern = self.parse_pattern()?;
    
    // Optional type annotation
    let type_annotation = if self.match_token(&[TokenKind::Colon]) {
        Some(self.parse_type()?)
    } else {
        None
    };
    
    self.expect(TokenKind::Equal, "Expected '=' after pattern")?;
    
    let value = self.parse_expression()?;
    
    Ok(Statement::Let {
        pattern,
        type_annotation,
        value,
        span: start.span.to(value.span()),
    })
}
```

### Type Declaration

```rust
// Syntax: type Name = TypeExpr
//         type Email = String matching /regex/
//         type Age = Int where x => x >= 0 && x <= 150
fn parse_type_decl(&mut self) -> Result<Statement, ParseError> {
    let start = self.expect(TokenKind::Type, "Expected 'type'")?;
    
    let name = self.expect(TokenKind::Identifier, "Expected type name")?;
    
    self.expect(TokenKind::Equal, "Expected '=' after type name")?;
    
    let base_type = self.parse_type()?;
    
    // Optional constraint
    let constraint = if self.match_token(&[TokenKind::Where, TokenKind::Matching]) {
        Some(self.parse_expression()?)
    } else {
        None
    };
    
    Ok(Statement::TypeDecl {
        name: name.lexeme.clone(),
        base_type,
        constraint,
        span: start.span.to(self.previous().span),
    })
}
```

---

## 3. Expression Parsing (Pratt Parser)

### Operator Precedence Table

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum Precedence {
    None,
    Assignment,   // =
    Pipeline,     // |>
    Or,           // ||, or
    And,          // &&, and
    Equality,     // ==, !=
    Comparison,   // <, >, <=, >=
    Range,        // .., ..=
    Term,         // +, -
    Factor,       // *, /, %
    Power,        // ², ³, ^
    Unary,        // !, -, not
    Call,         // f(x), a[i], a.b
    Primary,      // literals, identifiers
}

impl TokenKind {
    fn precedence(&self) -> Precedence {
        match self {
            TokenKind::Equal => Precedence::Assignment,
            TokenKind::Pipeline => Precedence::Pipeline,
            TokenKind::Or | TokenKind::OrKeyword => Precedence::Or,
            TokenKind::And | TokenKind::AndKeyword => Precedence::And,
            TokenKind::EqualEqual | TokenKind::BangEqual => Precedence::Equality,
            TokenKind::Less | TokenKind::Greater 
            | TokenKind::LessEqual | TokenKind::GreaterEqual => Precedence::Comparison,
            TokenKind::DotDot | TokenKind::DotDotEqual => Precedence::Range,
            TokenKind::Plus | TokenKind::Minus => Precedence::Term,
            TokenKind::Star | TokenKind::Slash | TokenKind::Percent => Precedence::Factor,
            TokenKind::Caret | TokenKind::Squared => Precedence::Power,
            TokenKind::LeftParen | TokenKind::LeftBracket | TokenKind::Dot => Precedence::Call,
            _ => Precedence::None,
        }
    }
}
```

### Expression Parser

```rust
impl Parser {
    fn parse_expression(&mut self) -> Result<Expr, ParseError> {
        self.parse_precedence(Precedence::Assignment)
    }
    
    fn parse_precedence(&mut self, precedence: Precedence) -> Result<Expr, ParseError> {
        // Parse prefix expression
        let mut expr = self.parse_prefix()?;
        
        // Parse infix expressions
        while precedence < self.peek().kind.precedence() {
            expr = self.parse_infix(expr)?;
        }
        
        Ok(expr)
    }
    
    fn parse_prefix(&mut self) -> Result<Expr, ParseError> {
        match self.peek().kind {
            TokenKind::Number => self.parse_number(),
            TokenKind::String => self.parse_string(),
            TokenKind::True | TokenKind::False => self.parse_boolean(),
            TokenKind::Identifier => self.parse_identifier_or_call(),
            TokenKind::LeftParen => self.parse_grouping_or_tuple(),
            TokenKind::LeftBracket => self.parse_array_or_index(),
            TokenKind::LeftBrace => self.parse_object_or_block(),
            TokenKind::If => self.parse_if_expression(),
            TokenKind::Match => self.parse_match_expression(),
            TokenKind::Fn => self.parse_lambda(),
            TokenKind::Minus | TokenKind::Bang => self.parse_unary(),
            TokenKind::Sqrt => self.parse_sqrt(),
            
            // Tool call syntax
            TokenKind::GET | TokenKind::POST 
            | TokenKind::PUT | TokenKind::DELETE => self.parse_http_call(),
            TokenKind::Read | TokenKind::Write => self.parse_file_call(),
            
            _ => Err(self.error("Expected expression")),
        }
    }
    
    fn parse_infix(&mut self, left: Expr) -> Result<Expr, ParseError> {
        match self.peek().kind {
            TokenKind::Plus | TokenKind::Minus 
            | TokenKind::Star | TokenKind::Slash 
            | TokenKind::Percent | TokenKind::Caret => self.parse_binary(left),
            
            TokenKind::EqualEqual | TokenKind::BangEqual
            | TokenKind::Less | TokenKind::Greater
            | TokenKind::LessEqual | TokenKind::GreaterEqual => self.parse_comparison(left),
            
            TokenKind::And | TokenKind::AndKeyword => self.parse_logical_and(left),
            TokenKind::Or | TokenKind::OrKeyword => self.parse_logical_or(left),
            
            TokenKind::Pipeline => self.parse_pipeline(left),
            TokenKind::DotDot | TokenKind::DotDotEqual => self.parse_range(left),
            
            TokenKind::LeftParen => self.parse_call(left),
            TokenKind::LeftBracket => self.parse_index(left),
            TokenKind::Dot => self.parse_field_access(left),
            
            _ => Ok(left),
        }
    }
}
```

### Binary Operators

```rust
fn parse_binary(&mut self, left: Expr) -> Result<Expr, ParseError> {
    let operator = self.advance().clone();
    let precedence = operator.kind.precedence();
    let right = self.parse_precedence(precedence.next())?;
    
    Ok(Expr::Binary {
        left: Box::new(left),
        operator: operator.kind.into(),
        right: Box::new(right),
        span: left.span().to(right.span()),
    })
}
```

### Function Call

```rust
fn parse_call(&mut self, callee: Expr) -> Result<Expr, ParseError> {
    self.expect(TokenKind::LeftParen, "Expected '('")?;
    
    let mut args = Vec::new();
    
    if !self.check(TokenKind::RightParen) {
        loop {
            args.push(self.parse_expression()?);
            
            if !self.match_token(&[TokenKind::Comma]) {
                break;
            }
        }
    }
    
    let end = self.expect(TokenKind::RightParen, "Expected ')' after arguments")?;
    
    Ok(Expr::Call {
        callee: Box::new(callee),
        args,
        span: callee.span().to(end.span),
    })
}
```

### Match Expression

```rust
// Syntax: match expr {
//           pattern1 => expr1
//           pattern2 where guard => expr2
//           _ => default
//         }
fn parse_match_expression(&mut self) -> Result<Expr, ParseError> {
    let start = self.expect(TokenKind::Match, "Expected 'match'")?;
    
    let scrutinee = self.parse_expression()?;
    
    self.expect(TokenKind::LeftBrace, "Expected '{' after match expression")?;
    
    let mut arms = Vec::new();
    
    while !self.check(TokenKind::RightBrace) && !self.is_at_end() {
        let pattern = self.parse_pattern()?;
        
        // Optional guard: where condition
        let guard = if self.match_token(&[TokenKind::Where]) {
            Some(Box::new(self.parse_expression()?))
        } else {
            None
        };
        
        self.expect(TokenKind::FatArrow, "Expected '=>' after pattern")?;
        
        let body = self.parse_expression()?;
        
        arms.push(MatchArm {
            pattern,
            guard,
            body,
        });
        
        // Optional comma or newline between arms
        self.match_token(&[TokenKind::Comma]);
    }
    
    let end = self.expect(TokenKind::RightBrace, "Expected '}' after match arms")?;
    
    Ok(Expr::Match {
        scrutinee: Box::new(scrutinee),
        arms,
        span: start.span.to(end.span),
    })
}
```

### If Expression

```rust
// Syntax: if condition { then } else { else }
//         if condition then_expr else else_expr  (single expression)
//         condition ? then : else  (ternary)
fn parse_if_expression(&mut self) -> Result<Expr, ParseError> {
    let start = self.expect(TokenKind::If, "Expected 'if'")?;
    
    let condition = self.parse_expression()?;
    
    let then_branch = if self.check(TokenKind::LeftBrace) {
        Box::new(self.parse_block_expression()?)
    } else {
        Box::new(self.parse_expression()?)
    };
    
    let else_branch = if self.match_token(&[TokenKind::Else]) {
        if self.check(TokenKind::If) {
            // else if chain
            Some(Box::new(self.parse_if_expression()?))
        } else if self.check(TokenKind::LeftBrace) {
            Some(Box::new(self.parse_block_expression()?))
        } else {
            Some(Box::new(self.parse_expression()?))
        }
    } else {
        None
    };
    
    let span = start.span.to(
        else_branch.as_ref()
            .map(|e| e.span())
            .unwrap_or_else(|| then_branch.span())
    );
    
    Ok(Expr::If {
        condition: Box::new(condition),
        then_branch,
        else_branch,
        span,
    })
}
```

### Lambda Expression

```rust
// Syntax: fn(x, y) => x + y
//         (x, y) => x + y  (shorthand)
//         x => x * 2  (single param)
fn parse_lambda(&mut self) -> Result<Expr, ParseError> {
    let start = self.peek().span;
    
    // Optional 'fn' keyword
    self.match_token(&[TokenKind::Fn]);
    
    // Parameters
    let params = if self.match_token(&[TokenKind::LeftParen]) {
        let params = self.parse_parameter_list()?;
        self.expect(TokenKind::RightParen, "Expected ')' after parameters")?;
        params
    } else if self.check(TokenKind::Identifier) {
        // Single parameter without parens
        vec![Parameter {
            pattern: Pattern::Variable(self.advance().lexeme.clone()),
            type_annotation: None,
        }]
    } else {
        return Err(self.error("Expected parameters in lambda"));
    };
    
    self.expect(TokenKind::FatArrow, "Expected '=>' after lambda parameters")?;
    
    let body = Box::new(self.parse_expression()?);
    
    Ok(Expr::Lambda {
        params,
        body,
        span: start.to(body.span()),
    })
}
```

---

## 4. Pattern Parsing

### Pattern Structure

```rust
#[derive(Debug, Clone)]
pub enum Pattern {
    Wildcard,                                    // _
    Literal(Literal),                            // 42, "hello", true
    Variable(String),                            // x, name
    Tuple(Vec<Pattern>),                         // (x, y, z)
    Array(Vec<Pattern>, Option<Box<Pattern>>),   // [first, second, ..rest]
    Object {                                     // {name, age, ..rest}
        fields: Vec<(String, Pattern)>,
        rest: Option<Box<Pattern>>,
    },
    Or(Vec<Pattern>),                            // Email | Phone | Username
    Guard(Box<Pattern>, Box<Expr>),              // x where x > 0
}
```

### Pattern Parser

```rust
impl Parser {
    fn parse_pattern(&mut self) -> Result<Pattern, ParseError> {
        self.parse_or_pattern()
    }
    
    fn parse_or_pattern(&mut self) -> Result<Pattern, ParseError> {
        let mut patterns = vec![self.parse_primary_pattern()?];
        
        while self.match_token(&[TokenKind::Pipe]) {
            patterns.push(self.parse_primary_pattern()?);
        }
        
        if patterns.len() == 1 {
            Ok(patterns.into_iter().next().unwrap())
        } else {
            Ok(Pattern::Or(patterns))
        }
    }
    
    fn parse_primary_pattern(&mut self) -> Result<Pattern, ParseError> {
        match self.peek().kind {
            TokenKind::Underscore => {
                self.advance();
                Ok(Pattern::Wildcard)
            }
            
            TokenKind::Number | TokenKind::String 
            | TokenKind::True | TokenKind::False => {
                Ok(Pattern::Literal(self.parse_literal()?))
            }
            
            TokenKind::Identifier => {
                Ok(Pattern::Variable(self.advance().lexeme.clone()))
            }
            
            TokenKind::LeftParen => self.parse_tuple_pattern(),
            
            TokenKind::LeftBracket => self.parse_array_pattern(),
            
            TokenKind::LeftBrace => self.parse_object_pattern(),
            
            _ => Err(self.error("Expected pattern")),
        }
    }
    
    fn parse_tuple_pattern(&mut self) -> Result<Pattern, ParseError> {
        self.expect(TokenKind::LeftParen, "Expected '('")?;
        
        let mut patterns = Vec::new();
        
        if !self.check(TokenKind::RightParen) {
            loop {
                patterns.push(self.parse_pattern()?);
                
                if !self.match_token(&[TokenKind::Comma]) {
                    break;
                }
            }
        }
        
        self.expect(TokenKind::RightParen, "Expected ')'")?;
        
        Ok(Pattern::Tuple(patterns))
    }
    
    fn parse_array_pattern(&mut self) -> Result<Pattern, ParseError> {
        self.expect(TokenKind::LeftBracket, "Expected '['")?;
        
        let mut patterns = Vec::new();
        let mut rest = None;
        
        if !self.check(TokenKind::RightBracket) {
            loop {
                if self.match_token(&[TokenKind::DotDot]) {
                    // Rest pattern: [first, ..rest]
                    if self.check(TokenKind::Identifier) {
                        rest = Some(Box::new(Pattern::Variable(
                            self.advance().lexeme.clone()
                        )));
                    } else {
                        rest = Some(Box::new(Pattern::Wildcard));
                    }
                    break;
                } else {
                    patterns.push(self.parse_pattern()?);
                }
                
                if !self.match_token(&[TokenKind::Comma]) {
                    break;
                }
            }
        }
        
        self.expect(TokenKind::RightBracket, "Expected ']'")?;
        
        Ok(Pattern::Array(patterns, rest))
    }
    
    fn parse_object_pattern(&mut self) -> Result<Pattern, ParseError> {
        self.expect(TokenKind::LeftBrace, "Expected '{'")?;
        
        let mut fields = Vec::new();
        let mut rest = None;
        
        if !self.check(TokenKind::RightBrace) {
            loop {
                if self.match_token(&[TokenKind::DotDot]) {
                    // Rest pattern: {name, age, ..rest}
                    if self.check(TokenKind::Identifier) {
                        rest = Some(Box::new(Pattern::Variable(
                            self.advance().lexeme.clone()
                        )));
                    } else {
                        rest = Some(Box::new(Pattern::Wildcard));
                    }
                    break;
                } else {
                    let field_name = self.expect(
                        TokenKind::Identifier, 
                        "Expected field name"
                    )?.lexeme.clone();
                    
                    let pattern = if self.match_token(&[TokenKind::Colon]) {
                        // {name: n, age: a}
                        self.parse_pattern()?
                    } else {
                        // {name, age} - shorthand
                        Pattern::Variable(field_name.clone())
                    };
                    
                    fields.push((field_name, pattern));
                }
                
                if !self.match_token(&[TokenKind::Comma]) {
                    break;
                }
            }
        }
        
        self.expect(TokenKind::RightBrace, "Expected '}'")?;
        
        Ok(Pattern::Object { fields, rest })
    }
}
```

---

## 5. Tool Call Syntax

### HTTP Operations

```rust
// Syntax: GET api/users/:id
//         POST api/users {name, email}
//         PUT api/users/:id user_object
//         DELETE api/users/:id
fn parse_http_call(&mut self) -> Result<Expr, ParseError> {
    let method = self.advance().clone(); // GET, POST, PUT, DELETE
    
    // Parse URL (literal string or template)
    let url = if self.check(TokenKind::String) {
        self.parse_string()?
    } else {
        // Parse path: api/users/:id
        self.parse_url_path()?
    };
    
    // Optional request body (for POST, PUT)
    let body = if matches!(method.kind, TokenKind::POST | TokenKind::PUT) {
        if self.check(TokenKind::LeftBrace) {
            Some(Box::new(self.parse_object_or_block()?))
        } else if !self.is_statement_end() {
            Some(Box::new(self.parse_expression()?))
        } else {
            None
        }
    } else {
        None
    };
    
    Ok(Expr::ToolCall {
        kind: ToolCallKind::Http(method.kind.into()),
        endpoint: url,
        payload: body,
        span: method.span.to(self.previous().span),
    })
}

fn parse_url_path(&mut self) -> Result<String, ParseError> {
    let mut path = String::new();
    
    // Parse path segments: api/users/:id
    loop {
        if self.check(TokenKind::Identifier) {
            path.push_str(&self.advance().lexeme);
        } else if self.match_token(&[TokenKind::Colon]) {
            // Path parameter: :id
            path.push(':');
            path.push_str(&self.expect(TokenKind::Identifier, "Expected parameter name")?.lexeme);
        } else {
            break;
        }
        
        if self.match_token(&[TokenKind::Slash]) {
            path.push('/');
        } else {
            break;
        }
    }
    
    Ok(path)
}
```

### File Operations

```rust
// Syntax: read "file.txt"
//         write "file.txt" content
//         append "log.txt" message
fn parse_file_call(&mut self) -> Result<Expr, ParseError> {
    let operation = self.advance().clone(); // read, write, append
    
    let path = self.parse_expression()?; // File path
    
    let content = if matches!(operation.kind, TokenKind::Write | TokenKind::Append) {
        Some(Box::new(self.parse_expression()?))
    } else {
        None
    };
    
    Ok(Expr::ToolCall {
        kind: ToolCallKind::File(operation.kind.into()),
        endpoint: path,
        payload: content,
        span: operation.span.to(self.previous().span),
    })
}
```

---

## 6. Error Recovery

### Synchronization Strategy

```rust
impl Parser {
    fn synchronize(&mut self) {
        self.panic_mode = true;
        
        while !self.is_at_end() {
            // Stop at statement boundaries
            if matches!(
                self.peek().kind,
                TokenKind::Fn | TokenKind::Let | TokenKind::Type 
                | TokenKind::Return | TokenKind::If | TokenKind::Match
            ) {
                self.panic_mode = false;
                return;
            }
            
            // Skip to next potential statement
            self.advance();
        }
        
        self.panic_mode = false;
    }
    
    fn error(&mut self, message: &str) -> ParseError {
        let token = self.peek();
        
        ParseError {
            message: message.to_string(),
            span: token.span,
            suggestions: self.generate_suggestions(),
        }
    }
    
    fn generate_suggestions(&self) -> Vec<String> {
        // Context-aware suggestions based on current parsing state
        // E.g., "Did you mean 'fn' instead of 'func'?"
        vec![]
    }
}
```

### Error Types

```rust
#[derive(Debug, Clone)]
pub struct ParseError {
    pub message: String,
    pub span: Span,
    pub suggestions: Vec<String>,
}

impl ParseError {
    pub fn display(&self, source: &str) -> String {
        // Format error with source context
        format!(
            "error: {}\n  --> {}:{}:{}\n   |\n{}\n   |",
            self.message,
            self.span.file,
            self.span.start.line,
            self.span.start.column,
            self.get_source_context(source)
        )
    }
}
```

---

## 7. Testing Strategy

### Unit Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parse_function_decl() {
        let source = "fn double(x) => x * 2";
        let tokens = Lexer::new(source).tokenize();
        let mut parser = Parser::new(tokens);
        let program = parser.parse().unwrap();
        
        assert_eq!(program.statements.len(), 1);
        // ... more assertions
    }
    
    #[test]
    fn test_parse_match_expression() {
        let source = r#"
            match x {
                0 => "zero"
                n where n > 0 => "positive"
                _ => "negative"
            }
        "#;
        // ... test implementation
    }
    
    #[test]
    fn test_error_recovery() {
        let source = "fn incomplete(x => x * 2"; // Missing closing paren
        let tokens = Lexer::new(source).tokenize();
        let mut parser = Parser::new(tokens);
        let result = parser.parse();
        
        assert!(result.is_err());
        assert!(!parser.errors.is_empty());
    }
}
```

### Property-Based Testing

```rust
#[test]
fn property_parse_and_print_roundtrip() {
    // Any valid AST should parse → print → parse to same AST
    // Use quickcheck or proptest
}
```

---

## 8. Implementation Checklist

### Phase 1 (Weeks 1-2)

- [ ] Implement core Parser structure
- [ ] Token manipulation methods
- [ ] Error reporting infrastructure
- [ ] Statement parsing (let, fn, type, return)
- [ ] Expression parsing (Pratt parser)
  - [ ] Literals, identifiers
  - [ ] Binary operators
  - [ ] Unary operators
  - [ ] Function calls
  - [ ] Array/object literals
- [ ] Pattern parsing
  - [ ] Wildcards, literals, variables
  - [ ] Tuples, arrays, objects
  - [ ] Or patterns
- [ ] Tool call syntax (GET, POST, read, write)
- [ ] Match expressions
- [ ] If expressions
- [ ] Lambda expressions
- [ ] Error recovery and synchronization
- [ ] Unit tests for all expression forms
- [ ] Integration tests (full programs)

### Phase 2 (Week 3)

- [ ] Refine error messages
- [ ] Add context-aware suggestions
- [ ] Performance optimization (reduce allocations)
- [ ] Fuzz testing
- [ ] Documentation

---

## References

**Parser Design:**
- *Crafting Interpreters* - Ch. 6-8 (Parsing)
- *Compilers: Principles, Techniques, and Tools* (Dragon Book) - Ch. 4
- Pratt Parsing: http://journal.stuffwithstuff.com/2011/03/19/pratt-parsers-expression-parsing-made-easy/

**Rust Parsers:**
- `rustc_parse` (Rust compiler parser)
- `syn` (Rust proc-macro parser)

**Error Recovery:**
- Elm compiler error messages
- Rust compiler diagnostics

---

**Author:** Subagent 2 (Arc Compiler Architect)  
**Status:** Phase 0 - Implementation Blueprint  
**Ready for Implementation:** Phase 1
