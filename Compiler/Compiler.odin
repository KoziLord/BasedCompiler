package BD

import "core:fmt"
import str "core:strings"
import stc "core:strconv"
import "core:reflect"
import "core:os"
import "core:io"
import win "core:sys/windows"
import i "core:bufio"

ReplSignal :: enum
{
    None,
    Quit,
    Recompile,
}
@(export)
repl :: proc() -> ReplSignal
{   
    buf := [256]byte{}
    n, err := os.read(os.stdin, buf[:])
    //fmt.printf("Error code: %i\n", err)
    /*
    if err > 0
    {
        fmt.printf("Error occured when reading the input. Error code: %i\n", err)
        continue
    }
    */
    text := string(buf[:n])        
    
    if str.has_prefix(text, "#STOP") 
    {
        fmt.println("Stopping the compiler loop...")
        return .Quit
    }
    
    if str.has_prefix(text, "#FILE")
    {
        s := str.trim_left(text, "#FILE ")
        s = str.trim_right_space(s)
        
        file, ok := os.read_entire_file_from_filename(s)
        if !ok
        {
            fmt.println("Could not open file.")
            return .None
        }
        fmt.printf("\\\\Printing the file %s\n", s)
        fmt.println(string(file))
        fmt.print("\\\\File end\n")
        text = string(file)
    }
    if str.has_prefix(text, "#COMPILE")
    {
        fmt.println("Recompiling the compiler...")
        return .Recompile
    }
    

    output := lex(text)
    defer delete(output)
    for t in output do fmt.printf("This is a token: %v\n", t)
    
    return .None
}

lex :: proc(input : string) -> (output : [dynamic]Token)
{
    input := input
    line := i32(1)
    column := i32(0)
    for r in input
    {
        column += 1
        if r == '\n'
        {
            line += 1
            column = 0
            continue
        }
        if token := get_symbol_token(r, line, column); token != nil
        {
            append(&output, token)
            continue
        }
    }

    return
}

get_symbol_token :: proc(r : rune, line, column : i32) -> SymbolToken
{
    switch r
    {
        case '{': return LeftBraceToken{line, column}
        case '}': return RightBraceToken{line, column}
        case '(': return LeftParenToken{line, column}
        case ')': return RightParenToken{line, column}
        case ',': return CommaToken{line, column}
        case '.': return DotToken{line, column}
        case ':': return ColonToken{line, column}
        case ';': return SemicolonToken{line, column}
        case '_': return DiscardToken{line, column}
        case: return nil
    }
}

Token :: union
{
    SymbolToken,

}
TokenBase :: struct
{
    Line, Column : i32,
}
//Symbols
SymbolToken :: union
{
    LeftBraceToken,
    RightBraceToken,
    LeftParenToken,
    RightParenToken,
    CommaToken,
    DotToken,
    ColonToken,
    SemicolonToken,
    DiscardToken,
}

LeftBraceToken :: distinct TokenBase
RightBraceToken :: distinct TokenBase

LeftParenToken :: distinct TokenBase
RightParenToken :: distinct TokenBase

CommaToken :: distinct TokenBase
DotToken :: distinct TokenBase
SemicolonToken :: distinct TokenBase
ColonToken :: distinct TokenBase
DiscardToken :: distinct TokenBase

LiteralTokenBase :: struct
{
    using Base : TokenBase,
    Value : string,
}
IdentfierToken :: distinct LiteralTokenBase
IntegerLiteralToken :: distinct LiteralTokenBase
FloatLiteralToken :: distinct LiteralTokenBase
StringLiteralToken :: distinct LiteralTokenBase
LiteralToken :: union
{
    IdentfierToken,
    IntegerLiteralToken,
    FloatLiteralToken,
    StringLiteralToken,
}

TokenType :: enum
{
    Invalid,
    //Symbols
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    Comma,
    Dot,
    Semicolon,
    Colon,
    Discard,

    //Literals
    Identifier,
    IntLiteral,
    FloatLiteral,
    StringLiteral,


    //Binary operators
    Assign,
    Add,
    Subtract,
    Multiply,
    Divide,
    ShiftLeft,
    ShiftRight,

    //Keywords
    Fn,
    Struct,
    Mut,
    True,
    False,
    For,
    Package,
}