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

    # load Fonts
    # - If no fonts are loaded, dear imgui will use the default font. You can also load multiple fonts and use `CImGui.PushFont/PopFont` to select them.
    # - `CImGui.AddFontFromFileTTF` will return the `Ptr{ImFont}` so you can store it if you need to select the font among multiple.
    # - If the file cannot be loaded, the function will return C_NULL. Please handle those errors in your application (e.g. use an assertion, or display an error and quit).
    # - The fonts will be rasterized at a given size (w/ oversampling) and stored into a texture when calling `CImGui.Build()`/`GetTexDataAsXXXX()``, which `ImGui_ImplXXXX_NewFrame` below will call.
    # - Read 'fonts/README.txt' for more instructions and details.
    # fonts_dir = joinpath(@__DIR__, "..", "fonts")
    # fonts = CImGui.GetIO().Fonts
    # default_font = CImGui.AddFontDefault(fonts)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Cousine-Regular.ttf"), 15)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "DroidSans.ttf"), 16)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Karla-Regular.ttf"), 10)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "ProggyTiny.ttf"), 10)
    # CImGui.AddFontFromFileTTF(fonts, joinpath(fonts_dir, "Roboto-Medium.ttf"), 16)
    # @assert default_font != C_NULL

    # setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true)
    ImGui_ImplOpenGL3_Init(glsl_version)
    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]

    open_file_dialog = OpenFileDialog(pwd(),"", pwd(),"", false, false)
    open_file_dialog2 = OpenFileDialog(pwd(),"",pwd(),"",false,false)
    data = DataFrame()
    dt = Float32[]
    data2 = DataFrame()
    dt2 = Float32[]
    Open_files = false
    Open_files2 = false
    data_length = 0
    #eda_data = nothing
    #isnothing(eda_data)
    while !GLFW.WindowShouldClose(window)
        GLFW.PollEvents()
        # start the Dear ImGui frame
        ImGui_ImplOpenGL3_NewFrame()
        ImGui_ImplGlfw_NewFrame()
        CImGui.NewFrame()

        if CImGui.BeginMainMenuBar()
            if CImGui.BeginMenu("File")
                populate_file_menu!(open_file_dialog,open_file_dialog2) #visiblity = true
                #populate_file_menu!(open_file_dialog2)
                CImGui.EndMenu()
            end
            CImGui.EndMainMenuBar()
        end
        if isvisible(open_file_dialog)
            display_dialog!(open_file_dialog)
            if has_pending_action(open_file_dialog)
                # Check filename and perform different action.
                data = perform_dialog_action(open_file_dialog)
                # eda_data = ...
                # hr_data = ...
                consume_action!(open_file_dialog)
                #dt = Cfloat.(data[3:end,1])
                Base.display(data)
                Open_files = true
            end
        end

        if isvisible(open_file_dialog2)
            display_dialog!(open_file_dialog2)
            if has_pending_action(open_file_dialog2)
                data2 = perform_dialog_action(open_file_dialog2)
                consume_action!(open_file_dialog2)
                #dt = Cfloat.(data[3:end,1])
                Base.display(data2)
                Open_files2 = true
            end
        end
            #@c CImGui.Checkbox("Open files", &Open_files)
        if Open_files
            if !Open_files2
                # data_length = ...
                plotData(data)
            elseif Open_files2
                plotData2(data,data2)
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

function populate_file_menu!(dialog::AbstractDialog,dialog2::AbstractDialog)
    if CImGui.MenuItem("Open", "Ctrl+O")
        set_visibility!(dialog, true)
    end
    if CImGui.MenuItem("Open2", "Ctrl+O")
        set_visibility!(dialog2, true)
    end
    if CImGui.MenuItem("Save", "Ctrl+s")

    end
    if CImGui.MenuItem("Save as")

    end
    if CImGui.MenuItem("Quit", "Alt+F4")

    end
end

function plotData(data::DataFrame)
    begin
        #df = CSV.read("F:\\julia\\CSV\\EDA.csv", header = ["EDA"])
        #df = CSV.read("C:\\Users\\msi-\\Desktop\\EDA\\EDA.jl\\src\\HR.csv", header = ["HR"])
        CImGui.Begin("Plot")
        CImGui.Text("Plot")

        df_data =sort(Cfloat.(data[3:end,1]))
        max_value = df_data[end,1]
        #max = Cfloat(max_value)
        #length = size(df,1)-2
        len = size(data,1)-2
        #@show typeof(len)

        st = data[1,1]
        freq = data[2,1]
        start_time, end_time = @cstatic start_time=Cint(1) end_time=Cint(2) begin
            @c CImGui.SliderInt("Start Time", &start_time, 1,len)
            CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
            time1=Dates.unix2datetime(st+(start_time-1)/freq)
            CImGui.Text(string(Time(time1)))
            @c CImGui.SliderInt("End Time", &end_time, 2,len)
            CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
            time2=Dates.unix2datetime(st+(end_time-1)/freq)
            CImGui.Text(string(Time(time2)))
            if start_time > end_time -1
                start_time = end_time - Cint(1)
            elseif start_time < end_time - 2000*freq
                start_time = end_time - Cint(2000*freq)
            end
        end

        plot_data = Cfloat.(data[(start_time+2):(end_time+2),1])
        # st = data[1,1]
        # freq = data[2,1]

        CImGui.Text("Primitives")
            sz, thickness, col = @cstatic sz=Cfloat(36.0) thickness=Cfloat(4.0) col=Cfloat[1.0,0.0,0.4,0.2] begin
                CImGui.ColorEdit4("Color", col)
            end
            p = CImGui.GetCursorScreenPos()
            col32 = CImGui.ColorConvertFloat4ToU32(ImVec4(col...))

            begin
                width = 1200
                height = 200

                CImGui.PlotLines("EDA Measurements", plot_data, length(plot_data), 0 , "EDA", 0, Cfloat(max_value*1.2), (width,height))
                draw_list = CImGui.GetWindowDrawList()
                x::Cfloat = p.x
                y::Cfloat = p.y
                spacing = 8.0
                    # Draws (almost transparent) horizontal bars
                for yₙ in range(y, step = 40, stop = y + height - 40)
                    CImGui.AddRectFilled(draw_list, ImVec2(x, yₙ), ImVec2(x+width, yₙ+20), col32);
                end
            end

            #draw the x axis
            p = CImGui.GetCursorScreenPos()
            begin
                width = 1200
                col = Cfloat[0.0,0.0,0.0,1.0]
                col32 = CImGui.ColorConvertFloat4ToU32(ImVec4(col...))
                draw_list = CImGui.GetWindowDrawList()
                x = p.x
                y = p.y

                time = Dates.unix2datetime(st+ (start_time-1)/freq)
                f = Cfloat(1 / freq)
                CImGui.AddLine(draw_list, ImVec2(x, y), ImVec2(x+width, y), col32, Cfloat(1));
                for xₙ in range(x, step = 1200/ (end_time-start_time+1), stop = x + width)
                    hou = hour(time);
                    min = minute(time);
                    sec = second(time);
                    mil = millisecond(time);
                    if sec ==0 && mil ==0
                        CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32, Cfloat(1));
                    end
                        #if mil ==0
                    if sec ==0 && mil ==0
                            #CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                        CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(hou), ":", string(min)));
                    end
                    next_time = time + Dates.Millisecond(f*1000);
                    time = next_time;
                end
            end
    end
end

function plotData2(data::DataFrame,data2::DataFrame)
    begin
        CImGui.Begin("Plot")
        CImGui.Text("Plot")

        df_data =sort(Cfloat.(data[3:end,1]))
        df_data2 =sort(Cfloat.(data2[3:end,1]))
        max_value = df_data[end,1]
        max_value2 = df_data2[end,1]
        len = size(data,1)-2
        len2 = size(data2,1) -2
        st = data[1,1]
        freq = data[2,1]
        st2 = data2[1,1]
        freq2 = data2[2,1]

        start_time, end_time = @cstatic start_time=Cint(1) end_time=Cint(2) begin
            @c CImGui.SliderInt("Start Time", &start_time, 1,len)
            CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
            time1=Dates.unix2datetime(st+(start_time-1)/freq)
            CImGui.Text(string(Time(time1)))
            @c CImGui.SliderInt("End Time", &end_time, 2,len)
            CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
            time2=Dates.unix2datetime(st+(end_time-1)/freq)
            CImGui.Text(string(Time(time2)))
            if start_time > end_time -1
                start_time = end_time - Cint(1)
            elseif start_time < end_time - 2000*freq
                start_time = end_time - Cint(2000*freq)
            end
        end

        start_time2, end_time2 = @cstatic start_time2=Cint(1) end_time2=Cint(2) begin
            @c CImGui.SliderInt("Start Time2", &start_time2, 1,len2)
            CImGui.SameLine()
            time3=Dates.unix2datetime(st2+(start_time2-1)/freq2)
            CImGui.Text(string(Time(time3)))
            @c CImGui.SliderInt("End Time2", &end_time2, 2,len2)
            CImGui.SameLine()
            time4=Dates.unix2datetime(st2+(end_time2-1)/freq2)
            CImGui.Text(string(Time(time4)))
            if start_time2 > end_time2 -1
                start_time2 = end_time2 - Cint(1)
            elseif start_time2 < end_time2 - 2000*freq2
                start_time2 = end_time2 - Cint(2000*freq2)
            end
        end

        plot_data = Cfloat.(data[(start_time+2):(end_time+2),1])
        # st = data[1,1]
        # freq = data[2,1]

        plot_data2 = Cfloat.(data2[(start_time2+2):(end_time2+2),1])
        # st2 = data2[1,1]
        # freq2 = data2[2,1]


        CImGui.Text("Primitives")
            sz, thickness, col = @cstatic sz=Cfloat(36.0) thickness=Cfloat(4.0) col=Cfloat[1.0,0.0,0.4,0.2] begin
                CImGui.ColorEdit4("Color", col)
            end
            p = CImGui.GetCursorScreenPos()
            col32 = CImGui.ColorConvertFloat4ToU32(ImVec4(col...))
        begin
            width = 1200
            height = 200

            CImGui.PlotLines("EDA Measurements", plot_data, length(plot_data), 0 , "EDA", 0, Cfloat(max_value*1.2), (width,height))
            draw_list = CImGui.GetWindowDrawList()
            x::Cfloat = p.x
            y::Cfloat = p.y
            spacing = 8.0
            # Draws (almost transparent) horizontal bars
            for yₙ in range(y, step = 40, stop = y + height - 40)
                CImGui.AddRectFilled(draw_list, ImVec2(x, yₙ), ImVec2(x+width, yₙ+20), col32);
            end
        end

        #draw the x axis
        p = CImGui.GetCursorScreenPos()
        begin
            width = 1200
            col_ = Cfloat[0.0,0.0,0.0,1.0]
            col32_ = CImGui.ColorConvertFloat4ToU32(ImVec4(col_...))
            draw_list = CImGui.GetWindowDrawList()
            x = p.x
            y = p.y

            time = Dates.unix2datetime(st+ (start_time-1)/freq)
            f = Cfloat(1 / freq)
            CImGui.AddLine(draw_list, ImVec2(x, y), ImVec2(x+width, y), col32_, Cfloat(1));
            for xₙ in range(x, step = 1200/ (end_time-start_time+1), stop = x + width)
                hou = hour(time);
                min = minute(time);
                sec = second(time);
                mil = millisecond(time);
                if sec ==0 && mil ==0
                    CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32_, Cfloat(1));
                end
                    #if mil ==0
                if sec ==0 && mil ==0
                        #CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                    CImGui.AddText(draw_list, ImVec2(xₙ, y), col32_, string(string(hou), ":", string(min)));
                end
                next_time = time + Dates.Millisecond(f*1000);
                time = next_time;
            end
        end

        CImGui.NewLine()
        p = CImGui.GetCursorScreenPos()
        begin
            width = 1200
            height = 200
            CImGui.PlotLines("HR Measurements", plot_data2, length(plot_data2), 0 , "HR", 0, Cfloat(max_value2*1.2), (width,height))
            draw_list2 = CImGui.GetWindowDrawList()
            x = p.x
            y = p.y
            spacing = 8.0
            # Draws (almost transparent) horizontal bars
            for yₙ in range(y, step = 40, stop = y + height - 40)
                CImGui.AddRectFilled(draw_list2, ImVec2(x, yₙ), ImVec2(x+width, yₙ+20), col32);
            end
        end

        #draw the x axis
        p = CImGui.GetCursorScreenPos()
        begin
            width = 1200
            col_ = Cfloat[0.0,0.0,0.0,1.0]
            col32_ = CImGui.ColorConvertFloat4ToU32(ImVec4(col_...))
            draw_list2 = CImGui.GetWindowDrawList()
            x = p.x
            y = p.y

            time = Dates.unix2datetime(st2+ (start_time2-1)/freq2)
            f = Cfloat(1 / freq2)
            CImGui.AddLine(draw_list2, ImVec2(x, y), ImVec2(x+width, y), col32_, Cfloat(1));
            for xₙ in range(x, step = 1200/ (end_time2-start_time2+1), stop = x + width)
                hou = hour(time);
                min = minute(time);
                sec = second(time);
                mil = millisecond(time);
                if sec ==0 && mil ==0
                    CImGui.AddLine(draw_list2, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32_, Cfloat(1));
                end
                    #if mil ==0
                if sec ==0 && mil ==0
                        #CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                    CImGui.AddText(draw_list2, ImVec2(xₙ, y), col32_, string(string(hou), ":", string(min)));
                end
                next_time = time + Dates.Millisecond(f*1000);
                time = next_time;
            end
        end



    end
end
