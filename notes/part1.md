
## Part 1: The REPL

Corresponding part in the C version of this book is [here](https://cstack.github.io/db_tutorial/parts/part1.html). We will also need to know a little bit about memory allocation in Zig. One of the features of the language is that when we need to allocate memory on heap (a la malloc in C) we need to pass around an instance of an allocator to the function that needs to allocate memory. This helps in debugging the progrem, if a function doesn't accept allocater as an argument then its not allocating any memory on the heap. This is an nice introduction to memory management in Zig : https://pedropark99.github.io/zig-book/Chapters/01-memory.html .


### Implementing the REPL
SQLite (and the toy C version that we are basic this implementation off of) is roughly stuctured this way:

```
+---------------+
|   Tokenizer   |
+-------v-------+
        |
+---------------+
|    Parser     |
+-------v-------+
        |
+---------------+
| Code Generator|
+-------v-------+
        |
+---------------+
| Virtual Machine|
+-------v-------+
        |
+---------------+
|    B-Tree     |
+-------v-------+
        |
+---------------+
|    Pager      |
+-------v-------+
        |
+---------------+
| OS Interface  |
+---------------+
```

Starting from the user interface we first implement repl (the thing you get when you hit `sqlite3` and get `>` to type your sql queries into).

So the c code creates a struct to store the user input to the repl:
```
typedef struct {
  char* buffer;
  size_t buffer_length;
  ssize_t input_length;
} InputBuffer;
```

In zig it turns out the we need to do 
```
const InputBuffer = struct {
    buffer: []u8,
    buffer_length: isize,
    input_length: isize,
};
```

Zig does not have a native string type. Instead we use arrays of bytes, which is why we need to define `buffer: []u8`.  

In C in order to create functions to initialize the struct we need to do something like this:
```
InputBuffer* new_input_buffer() {
    InputBuffer* input_buffer = malloc(sizeof(InputBuffer));
    input_buffer->buffer = NULL;
    input_buffer->buffer_length = 0;
    input_buffer->input_length = 0;
    return input_buffer;
}
```

Constrast it with Zig, we define functions for a struct inside a struct definition. 

```
const InputBuffer = struct {
    // previous code to declare struct fields
    pub fn init(allocator: *const std.mem.Allocator) !InputBuffer {
        const buffer = try allocator.alloc(u8, 1024);
        return InputBuffer{
            .buffer = buffer,
            .buffer_length = 0,
            .input_length = 0,
        };
    }

    pub fn read_line(self: *InputBuffer) ![]u8 {
        // code to read line from stdin
        // see the src directory for the full implementation
    }
};

```


_______________

Full zig code for part 1:

```
const std = @import("std");

const InputBuffer = struct {
    buffer: []u8,
    buffer_length: usize,
    input_length: usize,

    pub fn init(allocator: *const std.mem.Allocator) !InputBuffer {
        const buffer = try allocator.alloc(u8, 1024);
        return InputBuffer{
            .buffer = buffer,
            .buffer_length = 0,
            .input_length = 0,
        };
    }

    pub fn read_line(self: *InputBuffer) ![]u8 {
        const stdin = std.io.getStdIn().reader();

        const line = try stdin.readUntilDelimiterOrEof(self.buffer, '\n');

        if (line) |l| {
            self.input_length = l.len;
            self.buffer_length = l.len;
            return l;
        } else {
            return error.EndOfStream;
        }
    }
};

pub fn main() !void {

    const allocator = std.heap.page_allocator;
    var input_buffer = try InputBuffer.init(&allocator);
    defer allocator.free(input_buffer.buffer);

    while (true) {
        std.debug.print("db > ", .{});
        const line = try input_buffer.read_line();
        
        if (std.mem.eql(u8, std.mem.trim(u8, line, &std.ascii.whitespace), "exit") or
            std.mem.eql(u8, std.mem.trim(u8, line, &std.ascii.whitespace), "quit")) {
            std.debug.print("Exiting...\n", .{});
            break;
        }
        
        std.debug.print("{s}\n", .{line});
    }

}
```
