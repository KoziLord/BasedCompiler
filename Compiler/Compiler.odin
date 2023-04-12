package BD

import "core:fmt"
import str "core:strings"
import "core:os"
import "core:io"

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
    //FIX: Need to handle errors here
    n, err := os.read(os.stdin, buf[:])

    text := string(buf[:n])        
    
    //NOTE: Put the REPL functions handling in a function? 
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
    if str.has_prefix(text, "#COMPILE") || str.has_prefix(text, "#COMP")
    {
        return .Recompile
    }
    
    reader := str.Reader{}
    str.reader_init(&reader, text)
    output := lex(reader)
    defer delete(output)
    for t in output do fmt.printf("%v\n", t)
    
    return .None
}

lex :: proc(input : str.Reader) -> (output : [dynamic]Token)
{
    input := input
    pos := TokenPos{1, 0}
    for r in read_rune(&input, &pos)
   {
        if is_whitespace(r) do continue
        if token := get_symbol_token(r, pos); token != nil
        {
            append(&output, token)
            continue
        }
    
        //Check if comment
        if r == '/'
        {
            r, ok := read_rune(&input, &pos)
            if !ok
            {
                panic("AAAAAAAAAAAAAAAAAAAAAAAAAA")
            }

            //Is comment
            if r == '/'
            {
                skip_to_eol(&input, &pos)
                continue
            }
            else
            {
                append(&output, ErrorToken{Position = pos, Message = "Stray / found. Were you perhaps trying to add a comment?"})
                continue
            }
        }

        //IsLiteral
        if is_digit(r)
        {
            number, error := get_number_token(&input, &pos)
            if error == nil
            {

                append(&output, number)
                continue
            }   
            errToken, ok := error.(ErrorToken)
            fmt.println(ok)
            append(&output, errToken)
            continue   
        }

        if word, wordPos, ok := read_word(&input, &pos); ok
        {
            //isKeyword
            if keyword := get_keyword_token(word, wordPos); keyword != nil
            {
                append(&output, keyword)
                continue
            }
           //Identifier
            append(&output, auto_cast IdentfierToken{Position = wordPos, Value = word})
            continue
        }
    }

    return
}
get_keyword_token :: proc(input : string, pos : TokenPos) -> KeywordToken
{
    switch input
    {
        case "package": return PackageToken{pos}
        case "struct":  return StructToken{pos}
        case "fn":      return FnToken{pos}
        case "mut":     return MutToken{pos}
        case "true":    return TrueToken{pos}
        case "false":   return FalseToken{pos}
        case:           return nil
    }
}

get_number_token :: proc(input : ^str.Reader, pos : ^TokenPos) -> (token : LiteralToken, error : Maybe(ErrorToken))
{
    copy := input^
    endPos := pos^
    isFloat := false
    for r in read_rune(&copy, &endPos)
    {
        sym := get_symbol_token(r, pos^)
        if _, ok := sym.(DiscardToken); ok
        {
            sym = nil
        }

        if _, ok := sym.(DotToken); ok
        {
            if isFloat
            {
                if error == nil
                {
                    error = ErrorToken{Position = {endPos.Line, endPos.Column - 1}, Message = "Extra \'.\' found in a float literal"}
                }
            }
            isFloat = true

            sym = nil
        }

        if is_whitespace(r) || sym != nil
        {
            break
        }
    }
    str.reader_unread_rune(input)
    unread_rune(&copy, &endPos)

    word, wordPos := input.s[input.i:copy.i], pos^
    switch isFloat
    {
        case true:  token = FloatLiteralToken{Position = pos^, Value = word}
        case false: token = IntegerLiteralToken{Position = pos^, Value = word}
    }
    input^ = copy
    pos^ = endPos

    return
}
read_word :: proc(input : ^str.Reader, pos : ^TokenPos) -> (word : string, wordPos : TokenPos, ok : bool)
{
    copy := input^
    endPos := pos^

    for r in read_rune(&copy, &endPos)
    {
        sym := get_symbol_token(r, pos^)
        if _, ok := sym.(DiscardToken); ok
        {
            continue
        } 

        if is_whitespace(r) || sym != nil
        {
            break
        }
    }

    str.reader_unread_rune(input)
    unread_rune(&copy, &endPos)
    word, wordPos, ok = input.s[input.i:copy.i], pos^, true
    input^ = copy
    pos^ = endPos

    return
}

is_whitespace :: proc(r : rune) -> bool
{
    return r == ' ' || r == '\n' || r == '\r'
}
is_digit :: proc(r : rune) -> bool
{
    return r >= '0' && r <= '9'
}
read_rune :: proc(input : ^str.Reader, pos : ^TokenPos) -> (rune, bool)
{
    r, size, error := str.reader_read_rune(input)
    if r == '\n'
    {
        pos.Line += 1
        pos.Column = 0
    }
    else
    {
        pos.Column += 1
    }
    return r, error == .None
}
unread_rune :: proc(input : ^str.Reader, pos : ^TokenPos)
{
    str.reader_unread_rune(input)
    pos.Column -= 1
}
skip_to_eol :: proc(input : ^str.Reader, pos : ^TokenPos)
{
    for r in read_rune(input, pos)
    {
        if r == '\n' do break
    }
}
get_symbol_token :: proc(r : rune, pos : TokenPos) -> SymbolToken
{
    switch r
    {
        case '{': return LeftBraceToken{pos}
        case '}': return RightBraceToken{pos}
        case '(': return LeftParenToken{pos}
        case ')': return RightParenToken{pos}
        case ',': return CommaToken{pos}
        case '.': return DotToken{pos}
        case ':': return ColonToken{pos}
        case ';': return SemicolonToken{pos}
        case '_': return DiscardToken{pos}
        case:     return nil
    }
}
TokenPos :: struct {Line, Column : i32}
Token :: union
{
    SymbolToken,
    ErrorToken,
    KeywordToken,
    LiteralToken,
    IdentfierToken,
}

TokenBase :: struct
{
    using Position : TokenPos,
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

//Keywords
KeywordToken :: union
{
    PackageToken,
    MutToken,
    StructToken,
    FnToken,
    TrueToken,
    FalseToken,
}

PackageToken :: distinct TokenBase
MutToken :: distinct TokenBase
StructToken :: distinct TokenBase
FnToken :: distinct TokenBase
TrueToken :: distinct TokenBase
FalseToken :: distinct TokenBase

//LITERALS
LiteralToken :: union
{
    IntegerLiteralToken,
    FloatLiteralToken,
    StringLiteralToken,
}
LiteralTokenBase :: struct
{
    using Base : TokenBase,
    Value : string,
}
IdentfierToken :: distinct LiteralTokenBase
IntegerLiteralToken :: distinct LiteralTokenBase
FloatLiteralToken :: distinct LiteralTokenBase
StringLiteralToken :: distinct LiteralTokenBase

ErrorToken :: struct
{
    using Base : TokenBase,
    Message : string,
}