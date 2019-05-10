module ElectrodermalActivity

using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using Printf
using DataFrames
using CSV

include("filedialog.jl")
include("gui.jl")

export launch

end # module
