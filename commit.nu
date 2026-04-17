#!/usr/bin/env nu

def main [message: string, --tag (-t)] {
    print "Running tests..."
    dub test
    if $env.LAST_EXIT_CODE != 0 {
        error make {msg: "Tests failed! Aborting."}
    }

    print "Committing changes..."
    git add .
    let status = (git status --porcelain)
    if ($status | str length) > 0 {
        git commit -m $message
    } else {
        print "No changes to commit."
    }

    if $tag {
        let tags = (git tag | lines)
        let next_version = if ($tags | is-empty) {
            "v0.1.0"
        } else {
            let last_tag = ($tags | last)
            let parts = ($last_tag | str replace 'v' '' | split row '.')
            if ($parts | length) != 3 {
                "v0.1.0"
            } else {
                let major = ($parts | get 0)
                let minor = ($parts | get 1)
                let patch = (($parts | get 2 | into int) + 1)
                $"v($major).($minor).($patch)"
            }
        }
        
        print $"Tagging version ($next_version)..."
        git tag $next_version
    }

    print "Pushing..."
    let branch = (git branch --show-current | str trim)
    git push origin $branch
    if $tag {
        git push origin --tags
    }
    
    print "Done!"
}
