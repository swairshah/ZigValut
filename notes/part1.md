
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

