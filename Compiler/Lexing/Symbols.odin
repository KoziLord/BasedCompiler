package Lexing

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
    DollarToken,
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
DollarToken :: distinct TokenBase

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
        case '$': return DollarToken{pos}
        case:     return nil
    }
}