import argd;
import std.stdio;

class GreetCommand : Command {
    this() {
        super("greet");
        description = "Greets a person";
        usage = "<name>";
        argCollType = ArgCollectionType.exact;
        argCount = 1;
        
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

class MainCommand : Command {
    this() {
        super("app", false);
        description = "A simple example app using argd";
    }

    override protected CommandResult onExecute(string[] args, bool verbose, bool quiet) {
        if (args.length == 0) {
            writeln(buildHelp());
        }
        return CommandResult.ok();
    }
}

void main(string[] args) {
    auto root = new MainCommand();
    root.registerSubCommand(new GreetCommand());
    
    // Pass everything after the executable name
    auto result = root.handle(args[1 .. $]);
    
    if (!result.success && result.message.length > 0) {
        writeln("Error: ", result.message);
    }
}
