# argd

**argd** is a lightweight, class-based argument and command parsing system for the D programming language. It allows for easy creation of complex command-line interfaces with nested subcommands, automated help generation, and argument validation.

## Features

- **Nested Subcommands**: Create hierarchical CLI tools (like `git` or `dub`).
- **Automated Help**: Automatically generates usage instructions and subcommand/option lists.
- **Argument Validation**: Specify expected argument counts and collection types.
- **Option Handling**: Simple registration and retrieval of long and short-form options.
- **Cross-Platform**: Built using standard D libraries (`std.*`).

## Installation

Add `argd` as a dependency in your `dub.json`:
```json
"dependencies": {
    "argd": "~>1.0.0"
}
```

## Quick Start

```d
import argd;
import std.stdio;

class GreetCommand : Command {
    this() {
        super("greet");
        description = "Greets a person";
        usage = "<name>";
        argCount = 1;
        argCollType = ArgCollectionType.exact;
        
        addOption("--formality", "-f", "Use formal greeting");
    }

    override protected CommandResult onExecute(string[] args, bool verbose, bool quiet) {
        string name = args[0];
        bool formal = hasOption("--formality", "-f");
        
        if (formal) {
            writeln("Greetings, ", name, ".");
        } else {
            writeln("Hello, ", name, "!");
        }
        
        return CommandResult.ok();
    }
}

void main(string[] args) {
    auto root = new GreetCommand();
    auto result = root.handle(args[1 .. $]);

    // Check if there is a message to display (like help or errors)
    if (result.message.length > 0) {
        if (result.success) {
            writeln(result.message);
        } else {
            stderr.writeln(result.message);
        }
    }
}
```

## Examples

Check out the `examples/` directory for a complete demonstration of a multi-command CLI. You can run it directly using Dub:

```powershell
dub run :basic -- greet "World" --formality
```

## License

This project is licensed under the MIT License.
