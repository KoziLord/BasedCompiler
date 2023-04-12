package BD

import "core:fmt"
import str "core:strings"
import "core:os"
import "core:io"
import "Lexing"

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

    output := Lexing.lex(reader)
    defer delete(output)
    
    for t in output do fmt.printf("%v\n", t)
    
    return .None
}