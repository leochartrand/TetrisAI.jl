"""
usage.jl

This is a script that provides an example of the current way to import and use the TetrisAI package in a script.
Of course, if the project is deployed to the Julia hub, using the package manager directly in the script won't
be necessary.

It can also be used as a conveniance script, as sometimes it's a bit cumbersome to manually start up a Julia
interactive session and run the commands you want manually. You can copy and customize this script to your
own needs and you can start it up with just the following line:

julia usage.jl

"""

using Pkg

# Activate the current project.
Pkg.activate(".")

# Precompile the package.
println("Precompiling...")
Pkg.precompile()
println("Precompiling DONE.")

print("Importing TetrisAI")
t = @elapsed begin
  using TetrisAI
end

################################
# Write your TetrisAI code below

demo_id = "DQN-Feature-Extraction-Final" # PPO-Final

model_demo(demo_id)
