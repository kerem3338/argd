/**
Argd

Argument parser/command system for the D Programming Language

License: MIT

Licensed under the MIT License

2026 © Kerem ATA (zoda)
*/
module argd;

import std.stdio;
import std.array;
import std.conv;
import std.algorithm;
import std.string;
import std.format;

enum ArgCollectionType { exact, minimum, any, none }

struct Option {
    string longName;
    string shortName;
    string description;
}


struct CommandResult {
    bool success;
    string message;
    int exitCode = 0;

    static CommandResult ok(string message = "") { return CommandResult(true, message, 0); }
    static CommandResult error(string message, int exitCode = 1) { return CommandResult(false, message, exitCode); }
}


class Command {
    string name;
    string description = "No description";
    string usage = "[options]";
    ArgCollectionType argCollType = ArgCollectionType.any;
    int argCount = 0;
    bool parseOptions = true;

protected:
    Command[string] subCommands;
    string[] options;
    Option[] registeredOptions;

    bool hasOption(string longName, string shortName = "") {
        return options.canFind(longName) || (shortName.length > 0 && options.canFind(shortName));
    }


public:
    this(string name, bool withHelp = true) {
        this.name = name;
        if (withHelp)
            registerSubCommand(new HelpSubCommand(this));
    }

    void registerSubCommand(Command cmd) {
        subCommands[cmd.name] = cmd;
    }

    void addOption(string longName, string shortName, string description) {
        registeredOptions ~= Option(longName, shortName, description);
    }

    final CommandResult handle(string[] inputArgs, string[] globalOpts = []) {
        string[] args;
        string[] opts;

        foreach (arg; inputArgs) {
            if (parseOptions && arg.length > 0 && arg[0] == '-') opts ~= arg;
            else args ~= arg;
        }

        this.options = opts ~ globalOpts;

        if (args.length > 0) {
            auto sub = args[0];
            if (sub in subCommands)
                return subCommands[sub].handle(args[1 .. $], this.options);
        }

        if (hasOption("--help", "-h"))
            return CommandResult.ok(buildHelp());


        if (!validateArgs(args))
            return CommandResult.error("Invalid arguments. Expected " ~
                argCount.to!string ~ " but got " ~ args.length.to!string ~
                "\n\n" ~ buildHelp());

        bool verbose = hasOption("--verbose", "-v");
        bool quiet = hasOption("--quiet", "-q");

        return onExecute(args, verbose, quiet);
    }

protected:
    bool validateArgs(string[] args) {
        final switch (argCollType) {
            case ArgCollectionType.exact: return args.length == argCount;
            case ArgCollectionType.minimum: return args.length >= argCount;
            case ArgCollectionType.any: return true;
            case ArgCollectionType.none: return args.length == 0;
        }
    }


    string buildHelp() {
        string out_;
        out_ ~= "Usage: " ~ (name.length > 0 ? name ~ " " : "") ~ usage ~ "\n\n";
        out_ ~= description ~ "\n\n";

        if (subCommands.length > 1) {
            out_ ~= "Subcommands:\n";
            foreach (cmd; subCommands) {
                if (cmd.name != "--help")
                    out_ ~= format("  %-20s %s\n", cmd.name, cmd.description);
            }
            out_ ~= "\n";
        }

        out_ ~= "Options:\n";
        out_ ~= format("  %-20s %s\n", "-h, --help", "Show this help message");
        foreach (opt; registeredOptions) {
            string flags = opt.longName;
            if (opt.shortName.length > 0)
                flags = opt.shortName ~ ", " ~ flags;
            out_ ~= format("  %-20s %s\n", flags, opt.description);
        }
        return out_;
    }

    string buildMarkdown(int depth = 1) {
        string h = "";
        foreach (i; 0 .. depth) h ~= "#";
        
        string out_;
        out_ ~= h ~ " `" ~ (name.length > 0 ? name : "Command") ~ "`\n\n";
        out_ ~= description ~ "\n\n";
        
        out_ ~= "**Usage:** `" ~ (name.length > 0 ? name ~ " " : "") ~ usage ~ "`\n\n";

        bool hasOpts = registeredOptions.length > 0;
        out_ ~= h ~ "# Options\n\n";
        out_ ~= "| Option | Description |\n";
        out_ ~= "|--------|-------------|\n";
        out_ ~= "| `-h, --help` | Show this help message |\n";
        foreach (opt; registeredOptions) {
            string flags = opt.longName;
            if (opt.shortName.length > 0) flags = opt.shortName ~ ", " ~ flags;
            out_ ~= "| `" ~ flags ~ "` | " ~ opt.description ~ " |\n";
        }
        out_ ~= "\n";

        if (subCommands.length > 1) {
            out_ ~= h ~ "# Subcommands\n\n";
            foreach (cmdName, cmd; subCommands) {
                if (cmd.name != "--help") {
                    out_ ~= cmd.buildMarkdown(depth + 1);
                }
            }
        }
        
        return out_;
    }

    private string escapeHTML(string s) {
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
                .replace("'", "&apos;");
    }

    string buildHTML(bool fullPage = true) {
        string html;
        if (fullPage) {
            html ~= "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n";
            html ~= "    <meta charset=\"UTF-8\">\n";
            html ~= "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n";
            html ~= "    <title>Documentation - " ~ (name.length > 0 ? name : "App") ~ "</title>\n";
            html ~= "    <style>\n";
            html ~= "        :root { --bg: #0f172a; --card: #1e293b; --text: #f8fafc; --accent: #38bdf8; --dim: #94a3b8; }\n";
            html ~= "        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: var(--bg); color: var(--text); line-height: 1.6; margin: 0; padding: 2rem; }\n";
            html ~= "        .container { max-width: 900px; margin: 0 auto; }\n";
            html ~= "        .command-card { background: var(--card); padding: 1.5rem; border-radius: 12px; margin-bottom: 2rem; border-left: 4px solid var(--accent); shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1); }\n";
            html ~= "        h1, h2, h3 { color: var(--accent); margin-top: 0; }\n";
            html ~= "        code { background: #000; padding: 0.2rem 0.4rem; border-radius: 4px; font-family: monospace; color: #ef4444; }\n";
            html ~= "        .usage { background: #000; padding: 1rem; border-radius: 8px; font-family: monospace; overflow-x: auto; margin: 1rem 0; border: 1px solid #334155; }\n";
            html ~= "        table { width: 100%; border-collapse: collapse; margin-block: 1rem; }\n";
            html ~= "        th { text-align: left; border-bottom: 2px solid var(--dim); padding: 0.5rem; color: var(--accent); }\n";
            html ~= "        td { padding: 0.5rem; border-bottom: 1px solid #334155; }\n";
            html ~= "        .subcommands { margin-left: 1.5rem; border-left: 2px dashed #334155; padding-left: 1.5rem; }\n";
            html ~= "        .tag { font-size: 0.8rem; background: var(--accent); color: var(--bg); padding: 0.1rem 0.5rem; border-radius: 1rem; font-weight: bold; }\n";
            html ~= "    </style>\n</head>\n<body>\n<div class=\"container\">\n";
        }

        html ~= "    <div class=\"command-card\">\n";
        html ~= "        <h1>" ~ escapeHTML(name.length > 0 ? name : "Command") ~ " <span class=\"tag\">v1.0</span></h1>\n";
        html ~= "        <p>" ~ escapeHTML(description) ~ "</p>\n";
        html ~= "        <div class=\"usage\"><strong>Usage:</strong> " ~ escapeHTML((name.length > 0 ? name ~ " " : "") ~ usage) ~ "</div>\n";

        html ~= "        <h3>Options</h3>\n";
        html ~= "        <table>\n";
        html ~= "            <tr><th>Flag</th><th>Description</th></tr>\n";
        html ~= "            <tr><td><code>-h, --help</code></td><td>Show this help message</td></tr>\n";
        foreach (opt; registeredOptions) {
            string flags = opt.longName;
            if (opt.shortName.length > 0) flags = opt.shortName ~ ", " ~ flags;
            html ~= format("            <tr><td><code>%s</code></td><td>%s</td></tr>\n", escapeHTML(flags), escapeHTML(opt.description));
        }
        html ~= "        </table>\n";
        html ~= "    </div>\n";

        if (subCommands.length > 1) {
            html ~= "    <div class=\"subcommands\">\n";
            html ~= "        <h2>Subcommands</h2>\n";
            foreach (cmdName, cmd; subCommands) {
                if (cmd.name != "--help") {
                    html ~= cmd.buildHTML(false);
                }
            }
            html ~= "    </div>\n";
        }

        if (fullPage) {
            html ~= "</div>\n</body>\n</html>";
        }
        return html;
    }

    protected abstract CommandResult onExecute(string[] args, bool verbose, bool quiet);
}

class HelpSubCommand : Command {
    private Command parent;
    this(Command parent) {
        super("--help", false);
        this.parent = parent;
        description = "Show help for " ~ parent.name;
    }

    override protected CommandResult onExecute(string[] args, bool verbose, bool quiet) {
        return CommandResult.ok(parent.buildHelp());
    }
}

string[] parseArgs(string cmd) {
    string[] result;
    string buf;
    bool inQuotes = false;

    foreach (c; cmd) {
        if (c == '"') {
            inQuotes = !inQuotes;
            continue;
        }
        if (c == ' ' && !inQuotes) {
            if (buf.length > 0) {
                result ~= buf;
                buf = "";
            }
        } else {
            buf ~= c;
        }
    }
    if (buf.length > 0)
        result ~= buf;
    return result;
}

// ----------------------------------------------------------------------------
// Unit Tests
// ----------------------------------------------------------------------------

unittest {
    import std.algorithm.searching : canFind;

    auto res = CommandResult.ok("Success");
    assert(res.success == true);
    assert(res.message == "Success");

    auto err = CommandResult.error("Failed", 2);
    assert(err.success == false);
    assert(err.message == "Failed");
    assert(err.exitCode == 2);

    class MockCmd : Command {
        this() { super("mock"); }
        override protected CommandResult onExecute(string[] args, bool verbose, bool quiet) { return CommandResult.ok(); }
    }
    auto cmd = new MockCmd();
    cmd.options = ["--verbose", "-v", "--force"];
    
    assert(cmd.hasOption("--verbose"));
    assert(cmd.hasOption("--force"));
    assert(cmd.hasOption("", "-v"));
    assert(cmd.hasOption("--verbose", "-v"));
    assert(!cmd.hasOption("--quiet"));
    assert(!cmd.hasOption("", "-q"));

    cmd.argCollType = ArgCollectionType.exact;
    cmd.argCount = 2;
    assert(cmd.validateArgs(["a", "b"]));
    assert(!cmd.validateArgs(["a"]));
    assert(!cmd.validateArgs(["a", "b", "c"]));

    cmd.argCollType = ArgCollectionType.minimum;
    cmd.argCount = 1;
    assert(cmd.validateArgs(["a"]));
    assert(cmd.validateArgs(["a", "b"]));
    assert(!cmd.validateArgs([]));

    cmd.argCollType = ArgCollectionType.any;
    assert(cmd.validateArgs([]));
    assert(cmd.validateArgs(["a", "b", "c"]));

    cmd.argCollType = ArgCollectionType.none;
    assert(cmd.validateArgs([]));
    assert(cmd.validateArgs(["a"]));

    class SubCmd : Command {
        this() { super("sub"); }
        override protected CommandResult onExecute(string[] args, bool verbose, bool quiet) {
            return CommandResult.ok("sub_executed");
        }
    }

    auto root = new class Command {
        this() { super("root"); }
        override protected CommandResult onExecute(string[] args, bool verbose, bool quiet) {
            return CommandResult.ok("root_executed");
        }
    };
    root.registerSubCommand(new SubCmd());

    auto res1 = root.handle([]);
    assert(res1.success);
    assert(res1.message == "root_executed");

    auto res2 = root.handle(["sub"]);
    assert(res2.success);
    assert(res2.message == "sub_executed");

    auto res3 = root.handle(["--help"]);
    assert(res3.success);
    assert(res3.message.canFind("Usage: root"));
    assert(res3.message.canFind("sub"));
}