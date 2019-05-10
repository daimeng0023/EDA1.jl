function launch()

    @static if Sys.isapple()
        # OpenGL 3.2 + GLSL 150
        glsl_version = 150
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
        GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
        GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
    else
        # OpenGL 3.0 + GLSL 130
        glsl_version = 130
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
        GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 0)
        # GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
        # GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # 3.0+ only
    end

    # setup GLFW error callback
    error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
    GLFW.SetErrorCallback(error_callback)

    # create window
    window = GLFW.CreateWindow(1280, 720, "ElectroDermal Activity Analysis")
    @assert window != C_NULL
    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(1)  # enable vsync

    # setup Dear ImGui context
    ctx = CImGui.CreateContext()

    # setup Dear ImGui style
    # CImGui.StyleColorsDark()
    # CImGui.StyleColorsClassic()
    CImGui.StyleColorsLight()

    # setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true)
    ImGui_ImplOpenGL3_Init(glsl_version)
    should_show_dialog = true
    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]


    open_file_dialog = OpenFileDialog(pwd(),"", pwd(),"", false, false)
    open_file_dialog2 = OpenFileDialog(pwd(),"",pwd(),"",false,false)
    open_files = false
    open_files2 = false
    data = DataFrame()
    dt = Float32[]
    while !GLFW.WindowShouldClose(window)

        GLFW.PollEvents()
        # start the Dear ImGui frame
        ImGui_ImplOpenGL3_NewFrame()
        ImGui_ImplGlfw_NewFrame()
        CImGui.NewFrame()

        if CImGui.BeginMainMenuBar()
            if CImGui.BeginMenu("File")
                populate_file_menu!(open_file_dialog) #visiblity = true
                CImGui.EndMenu()
            end
            CImGui.EndMainMenuBar()
        end

        if isvisible(open_file_dialog)
            display_dialog!(open_file_dialog)
            if has_pending_action(open_file_dialog)
                data = perform_dialog_action(open_file_dialog)
                consume_action!(open_file_dialog)
                dt = Cfloat.(data[3:end,1])
                Base.display(data)
                open_files = true
            end
        end
        if open_files
            begin
                CImGui.Begin("Plot")
                CImGui.Text("Plot")
                st = data[1,1]
                freq = data[2,1]
                CImGui.PlotLines("Result", dt, length(dt))

                CImGui.Text("Primitives")
                    sz, thickness, col = @cstatic sz=Cfloat(36.0) thickness=Cfloat(4.0) col=Cfloat[1.0,0.0,0.4,0.2] begin
                        @c CImGui.DragFloat("Size", &sz, 0.2, 2.0, 72.0, "%.0f")
                        @c CImGui.DragFloat("Thickness", &thickness, 0.05, 1.0, 8.0, "%.02f")
                        CImGui.ColorEdit4("Color", col)
                    end
                    p = CImGui.GetCursorScreenPos()
                    col32 = CImGui.ColorConvertFloat4ToU32(ImVec4(col...))
                    begin
                        width = 1000
                        height = 200
                        CImGui.PlotLines("EDA Measurements", dt, length(dt), 0 , "EDA", 0, 1.0, (width,height))
                        draw_list = CImGui.GetWindowDrawList()
                        #x::Cfloat = p.x + 4.0
                        #y::Cfloat = p.y + 4.0
                        x::Cfloat = p.x
                        y::Cfloat = p.y
                        spacing = 8.0
                        # Draws (almost transparent) horizontal bars
                        for yₙ in range(y, step = 40, stop = y + height - 40)
                            CImGui.AddRectFilled(draw_list, ImVec2(x, yₙ), ImVec2(x+width, yₙ+20), col32);
                        end
                    end
                    #draw the x axis
                    begin
                        p = CImGui.GetCursorScreenPos()
                        width = 1000
                        col = Cfloat[0.0,0.0,0.0,1.0]
                        col32 = CImGui.ColorConvertFloat4ToU32(ImVec4(col...))
                        draw_list = CImGui.GetWindowDrawList()
                        x = p.x
                        y = p.y
                        #CImGui.display(typeof(p))

                        time = Dates.unix2datetime(st)
                        # Base.display(time)
                        #min = minute(time)
                        #sec = second(time)
                        f = Cfloat(1 / freq)
                        CImGui.AddLine(draw_list, ImVec2(x, y), ImVec2(x+width, y), col32, Cfloat(1));
                        for xₙ in range(x, step = 40, stop = x + width)
                            CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32, Cfloat(1));
                            #p.x = xₙ;
                            min = minute(time);
                            sec = second(time);
                            mil = millisecond(time);
                            if mil ==0
                                CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                            end
                            next_time = time + Dates.Millisecond(250);
                            time = next_time;
                        end
                    end

                end
                CImGui.End()
            end




        # rendering
        CImGui.Render()
        GLFW.MakeContextCurrent(window)
        display_w, display_h = GLFW.GetFramebufferSize(window)
        glViewport(0, 0, display_w, display_h)
        glClearColor(clear_color...)
        glClear(GL_COLOR_BUFFER_BIT)
        ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

        GLFW.MakeContextCurrent(window)
        GLFW.SwapBuffers(window)
    end

    # cleanup
    ImGui_ImplOpenGL3_Shutdown()
    ImGui_ImplGlfw_Shutdown()
    CImGui.DestroyContext(ctx)

    GLFW.DestroyWindow(window)
end

function perform_dialog_action(dialog::OpenFileDialog)
    directory = get_directory(dialog, ConfirmedStatus())
    file_name = get_file(dialog, ConfirmedStatus())
    path = joinpath(directory, file_name)
    data = CSV.File(path ; header= ["EDA"]) |> DataFrame
end

function populate_file_menu!(dialog::AbstractDialog)
    if CImGui.MenuItem("Open", "Ctrl+O")
        set_visibility!(dialog, true)
    end
    if CImGui.MenuItem("Save", "Ctrl+s")

    end
    if CImGui.MenuItem("Save as")

    end
    if CImGui.MenuItem("Quit", "Alt+F4")

    end
end


# function display_file_dialog(should_show_dialog::Bool, path::String)
#     if should_show_dialog
#         @c CImGui.Begin("Open Dialog", &should_show_dialog)
#         path_directories = splitpath(path)
#         selected_directory = Cint(length(path_directories))
#         # Draw a button for each directory that constitutes the current path.
#         for (index, d) in enumerate(path_directories)
#             CImGui.Button(d) && (selected_directory = Cint(index);)
#             CImGui.SameLine()
#         end
#         # If a button is clicked then we truncate the path up to and including the directory that was clicked.
#         path = selected_directory == 1 ? joinpath(first(path_directories)) : joinpath(path_directories[1:selected_directory]...)
#         CImGui.NewLine()
#         CImGui.BeginChild("Directory and File Listing", CImGui.ImVec2(CImGui.GetWindowWidth() * 0.98, -CImGui.GetWindowHeight() * 0.2))
#         CImGui.Columns(1)
#         # Make a list of directories that are visibile from the current directory.
#         visible_directories = filter(p->isdir(joinpath(path, p)), readdir(path))
#         for (n, folder_name) in enumerate(visible_directories)
#             # When the user clicks on a directory then change directory by appending it to the current path.
#             if CImGui.Selectable("[Dir] " * "$folder_name")
#                 @info "Trigger Item $n | find me here: $(@__FILE__) at line $(@__LINE__)"
#                 path = joinpath(path, folder_name)
#             end
#         end
#         # Make a list of files that are visible in the current directory.
#         visible_files = filter(p->isfile(joinpath(path, p)), readdir(path))
#         selected_file = Cint(0)
#         for (n, file_name) in enumerate(visible_files)
#             if CImGui.Selectable("[File] " * "$file_name")
#                 @info "Trigger Item $n | find me here: $(@__FILE__) at line $(@__LINE__)"
#             end
#         end
#         CImGui.EndChild()
#         CImGui.Text("File Name:")
#         CImGui.SameLine()
#         @show
#         #file_name₀ =  "\0"*"\0"^(255)
#         # Reserve 255 characters to receive input text. In the extreme
#         # case where a file is selected that exceeds 255 characters we will append
#         # the filename with a C_NULL character.
#         N = selected_file == 0 ? 255 : max(255 - length(visible_files[selected_file]), 1)
#         file_name₀ =  selected_file == 0 ?  "\0"*"\0"^(N)  : visible_files[selected_file]*"\0"^(N)
#         buf = Cstring(pointer(file_name₀))
#         CImGui.InputText("",buf, length(file_name₀))
#         #@show file_name₀
#         @show selected_file
#
#         #@cstatic  str0="Hello, world! " * "\0"^115 begin
#         # str0="Hello, world! "
#         # @show typeof(str0), str0
#         # ImGui.InputText("input text", str0, length(str0))
#
#
#         #CImGui.InputText("input text", str0, length(str0))
#         # Print the name of the selected file in the textbox.
#         CImGui.Button("Cancel") && (should_show_dialog = false;)
#         CImGui.SameLine()
#         CImGui.Button("Open") && (should_show_dialog = false;)
#
#         #@show current_directory
#         #CImGui.Button("Close Me") && (should_show_dialog = false;)
#         CImGui.End()
#     end
#
#     should_show_dialog, path
# end
