using Pkg

Pkg.activate(".")

println("Precompiling...")
Pkg.precompile()
println("Precompiling DONE.")

print("Importing TetrisAI")
t = @elapsed begin
  using TetrisAI
end

demo_id = "DQN-Feature-Extraction-Final" # PPO-Final

model_demo(demo_id)
