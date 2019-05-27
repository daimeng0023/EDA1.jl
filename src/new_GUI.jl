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
    window = GLFW.CreateWindow(1600, 1200, "ElectroDermal Activity Analysis")
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
                if occursin("eda",lowercase(get_file(open_file_dialog,ConfirmedStatus())))&& occursin("csv",lowercase(get_file(open_file_dialog,ConfirmedStatus())))
                    data = perform_dialog_action(open_file_dialog)
                    # eda_data = ...
                    # hr_data = ...
                    consume_action!(open_file_dialog)
                    #dt = Cfloat.(data[3:end,1])

                    Base.display(data)
                    Open_files = true
                    # status = ConfirmedStatus();
                else
                    # CImGui.Begin("Error!")
                    # CImGui.Text("This is not the target file!")
                    Base.display(get_file(open_file_dialog,ConfirmedStatus()))
                    CImGui.OpenPopup("Incorrect File?")
                    consume_action!(open_file_dialog)
                end
            end
        end

        if isvisible(open_file_dialog2)
            display_dialog!(open_file_dialog2)
            if has_pending_action(open_file_dialog2)
                if occursin("hr",lowercase(get_file(open_file_dialog2,ConfirmedStatus())))&&occursin("csv",lowercase(get_file(open_file_dialog2,ConfirmedStatus())))
                    data2 = perform_dialog_action(open_file_dialog2)
                    consume_action!(open_file_dialog2)
                    #dt = Cfloat.(data[3:end,1])
                    Base.display(data2)
                    Open_files2 = true
                    #status2 = ConfirmedStatus()
                else
                    Base.display(get_file(open_file_dialog2,UnconfirmedStatus()))
                    consume_action!(open_file_dialog2)
                    CImGui.OpenPopup("Incorrect File?")
                end
                # data2 = perform_dialog_action(open_file_dialog2)
                # consume_action!(open_file_dialog2)
                # #dt = Cfloat.(data[3:end,1])
                # Base.display(data2)
                # Open_files2 = true
            end
        end
        if CImGui.BeginPopupModal("Incorrect File?", C_NULL, CImGui.ImGuiWindowFlags_AlwaysAutoResize)
            CImGui.Text("File does not conform to expected schema.\nPlease verify that: \n   (1) the file exists; \n   (2) you have permission to access the file; \n (3) you have chosen the right file type. \n \n")
            CImGui.Separator()
            CImGui.Button("OK", (120, 0)) && CImGui.CloseCurrentPopup()
            CImGui.SetItemDefaultFocus()
            CImGui.EndPopup()
        end

        #@c CImGui.Checkbox("Open files", &Open_files)
        if Open_files || Open_files2
            if !Open_files2 && Open_files
                # data_length = ...
                plotData(data,"EDA Measurements")
            elseif !Open_files && Open_files2
                plotData(data2,"HR Measurements")
            elseif Open_files && Open_files2
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
    data = CSV.File(path ; header= [get_file(dialog,ConfirmedStatus())]) |> DataFrame
end

function populate_file_menu!(dialog::AbstractDialog,dialog2::AbstractDialog)
    if CImGui.BeginMenu("Import")
        if CImGui.MenuItem("Open EDA")
            set_visibility!(dialog, true)
        end
        if CImGui.MenuItem("Open HR")
            set_visibility!(dialog2, true)
        end
        CImGui.EndMenu()
    end
    if CImGui.MenuItem("Save", "Ctrl+s")
    end
    if CImGui.MenuItem("Save as")
    end
    if CImGui.MenuItem("Quit", "Alt+F4")
    end
end

function extract_string(buffer)
     first_nul = findfirst(isequal('\0'), buffer) - 1
     buffer[1:first_nul]
end

function plotData(data::DataFrame,name::String)
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
        buf="1"*"\0"^(15)
        hou_arr = [ string(s) for s = 0:23]
        min_arr = [ string(s) for s = 0:59]
        sec_arr = [ string(s) for s = 0:59]

        #buf2="00:00:00"*"\0"^(8)
        start_time, end_time, SorE, in_hou, in_min, in_sec = @cstatic start_time=Cint(1) end_time=Cint(2) SorE=false in_hou=Cint(1) in_min=Cint(1) in_sec=Cint(1) begin
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
            #elseif start_time < end_time - 2000*freq
            #    start_time = end_time - Cint(2000*freq)
            end
            @c CImGui.Checkbox("start or end",&SorE)
            if SorE==true
                CImGui.Text("Start time:")
                CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                CImGui.InputText("",buf,length(buf))
                CImGui.Text(string("Start time:",extract_string(buf)))
            else
                CImGui.Text("End time:")
                CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                CImGui.PushItemWidth(50)
                # CImGui.InputText("",buf,length(buf))
                @c CImGui.Combo(":###1", &in_hou, hou_arr,length(hou_arr))
                CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                @c CImGui.Combo(":###2", &in_min, min_arr,length(min_arr))
                CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                @c CImGui.Combo("", &in_sec, sec_arr,length(sec_arr))
                CImGui.PopItemWidth()
                # CImGui.Text(string("End time:",extract_string(buf)))

            end
            # CImGui.SameLine(5.0,CImGui.GetStyle().ItemInnerSpacing.x)
            # CImGui.Text("End time:")
            # CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
            # CImGui.InputText("",buf2,length(buf2))
            # CImGui.Text(extract_string(buf2))
        end

        plot_data = Cfloat.(data[(start_time+2):(end_time+2),1])
        # st = data[1,1]
        # freq = data[2,1]
        mean1= mean(plot_data)

        CImGui.Text("Color")
            sz, thickness, col = @cstatic sz=Cfloat(36.0) thickness=Cfloat(4.0) col=Cfloat[1.0,0.0,0.4,0.2] begin
                CImGui.ColorEdit4("Color", col)
            end
            p = CImGui.GetCursorScreenPos()
            col32 = CImGui.ColorConvertFloat4ToU32(ImVec4(col...))

            begin
                width = 1200
                height = 200

                CImGui.PlotLines("EDA Measurements", plot_data, length(plot_data), 0 , string("EDA Mean:",string(mean1)), 0, Cfloat(max_value*1.2), (width,height))
                draw_list = CImGui.GetWindowDrawList()
                x::Cfloat = p.x
                y::Cfloat = p.y
                spacing = 8.0
                # Draws (almost transparent) horizontal bars
                for yₙ in range(y, step = 40, stop = y + height - 40)
                    CImGui.AddRectFilled(draw_list, ImVec2(x, yₙ), ImVec2(x+width, yₙ+20), col32);
                end
            end

            #draw the x axis of EDA data
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
                for xₙ in range(x, step = 120, stop = x + width)
                    hou = hour(time);
                    min = minute(time);
                    sec = second(time);
                    mil = millisecond(time);
                    #if sec ==0 && mil ==0
                    CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32_, Cfloat(1));   ###################################
                    #if mil ==0
                    #CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                    CImGui.AddText(draw_list, ImVec2(xₙ, y), col32_, string(string(hou), ":", string(min), ":", string(sec)));   ###############################
                    next_time = time + Dates.Millisecond(Cint((end_time-start_time+1)*f*100));
                    time = next_time;
                end
            end

            #draw the EDA overview
            CImGui.NewLine()
            overview_data = Cfloat.(data[3:end,1])
            begin
                width = 1200
                height = 100
                CImGui.PlotLines("EDA Overview", overview_data, length(overview_data), 0 , "EDA", 0, Cfloat(max_value*1.2), (width,height))
                draw_list = CImGui.GetWindowDrawList()
                p = CImGui.GetCursorScreenPos()
                x = p.x
                y = p.y
                spacing = 8.0
                time = Dates.unix2datetime(st)
                f = Cfloat(1 / freq)
                CImGui.AddLine(draw_list, ImVec2(x, y), ImVec2(x+width, y), col32_, Cfloat(1));
                for xₙ in range(x, step = 60, stop = x + width)
                    hou = hour(time);
                    min = minute(time);
                    sec = second(time);
                    mil = millisecond(time);
                    #if sec ==0 && mil ==0
                    CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32_, Cfloat(1));   ###################################
                    #if mil ==0
                    #CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                    CImGui.AddText(draw_list, ImVec2(xₙ, y), col32_, string(string(hou), ":", string(min), ":", string(sec)));   ###############################
                    next_time = time + Dates.Millisecond(Cint(len*f*50));
                    time = next_time;
                end
                CImGui.AddLine(draw_list, ImVec2(x+Cfloat(1200/(len-1)*(start_time-1)), y), ImVec2(x+Cfloat(1200/(len-1)*(start_time-1)), y-105), col32_, Cfloat(3));
                CImGui.AddLine(draw_list, ImVec2(x+Cfloat(1200/(len-1)*(end_time-1)), y), ImVec2(x+Cfloat(1200/(len-1)*(end_time-1)), y-105), col32_, Cfloat(3));
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
        # buf="type sth here"*"\0"^(127)

        start_time, end_time, syn, start_time2, end_time2 = @cstatic start_time=Cint(1) end_time=Cint(2) syn=false start_time2=Cint(1) end_time2=Cint(2) begin
            if syn==false
                @c CImGui.SliderInt("Start Time", &start_time, 1,len)
                CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                time1=Dates.unix2datetime(st+(start_time-1)/freq)
                CImGui.Text(string(Time(time1)))
                CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                @c CImGui.Checkbox("synchronize",&syn)
                @c CImGui.SliderInt("End Time", &end_time, 2,len)
                CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                time2=Dates.unix2datetime(st+(end_time-1)/freq)
                CImGui.Text(string(Time(time2)))
                if start_time > end_time -1
                    start_time = end_time - Cint(1)
                # elseif start_time < end_time - 2000*freq
                #    start_time = end_time - Cint(2000*freq)
                end
                # CImGui.InputText("",buf,length(buf))
                # CImGui.Text(extract_string(buf))

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
                # elseif start_time2 < end_time2 - 2000*freq2
                #    start_time2 = end_time2 - Cint(2000*freq2)
                end
            else
                if freq2>=freq
                    @c CImGui.SliderInt("Start Time", &start_time, 1,len)
                    CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                    time1=Dates.unix2datetime(st+(start_time-1)/freq)
                    CImGui.Text(string(Time(time1)))
                    CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                    @c CImGui.Checkbox("synchronize",&syn)
                    @c CImGui.SliderInt("End Time", &end_time, 2,len)
                    CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                    time2=Dates.unix2datetime(st+(end_time-1)/freq)
                    CImGui.Text(string(Time(time2)))
                    if start_time > end_time -1
                        start_time = end_time - Cint(1)
                    # elseif start_time < end_time - 2000*freq
                    #    start_time = end_time - Cint(2000*freq)
                    end
                    start_time2=Cint((st-st2+(start_time-1)/freq)*freq2+1)
                    if start_time2>len2-1
                        start_time2=Cint(len2-1)
                    end
                    end_time2=Cint((st-st2+(end_time-1)/freq)*freq2+1)
                    if end_time2>len2
                        end_time2=Cint(len2)
                    end
                else
                    @c CImGui.SliderInt("Start Time", &start_time2, 1,len2)
                    CImGui.SameLine()
                    time3=Dates.unix2datetime(st2+(start_time2-1)/freq2)
                    CImGui.Text(string(Time(time3)))
                    CImGui.SameLine(0.0,CImGui.GetStyle().ItemInnerSpacing.x)
                    @c CImGui.Checkbox("synchronize",&syn)
                    @c CImGui.SliderInt("End Time", &end_time2, 2,len2)
                    CImGui.SameLine()
                    time4=Dates.unix2datetime(st2+(end_time2-1)/freq2)
                    CImGui.Text(string(Time(time4)))
                    if start_time2 > end_time2 -1
                        start_time2 = end_time2 - Cint(1)
                    # elseif start_time2 < end_time2 - 2000*freq2
                    #    start_time2 = end_time2 - Cint(2000*freq2)
                    end
                    start_time=Cint((st2-st+(start_time2-1)/freq2)*freq+1)
                    if start_time>len-1
                        start_time=Cint(len-1)
                    end
                    end_time=Cint((st2-st+(end_time2-1)/freq2)*freq+1)
                    if end_time>len
                        end_time=Cint(len)
                    end
                end
            end
        end

        plot_data = Cfloat.(data[(start_time+2):(end_time+2),1])
        # st = data[1,1]
        # freq = data[2,1]
        mean1= mean(plot_data)
        #CImGui.Text(string(mean1))
        plot_data2 = Cfloat.(data2[(start_time2+2):(end_time2+2),1])
        mean2= mean(plot_data2)
        # st2 = data2[1,1]
        # freq2 = data2[2,1]


        CImGui.Text("Color")
            sz, thickness, col = @cstatic sz=Cfloat(36.0) thickness=Cfloat(4.0) col=Cfloat[1.0,0.0,0.4,0.2] begin
                CImGui.ColorEdit4("Color", col)
            end
            p = CImGui.GetCursorScreenPos()
            col32 = CImGui.ColorConvertFloat4ToU32(ImVec4(col...))

        #Plotting Data 1(EDA data)
        begin
            width = 1200
            height = 200
            CImGui.PlotLines("EDA Measurements", plot_data, length(plot_data), 0 , string("EDA Mean:",string(mean1)), 0, Cfloat(max_value*1.2), (width,height))
            draw_list = CImGui.GetWindowDrawList()
            x::Cfloat = p.x
            y::Cfloat = p.y
            spacing = 8.0
            # Draws (almost transparent) horizontal bars
            for yₙ in range(y, step = 40, stop = y + height - 40)
                CImGui.AddRectFilled(draw_list, ImVec2(x, yₙ), ImVec2(x+width, yₙ+20), col32);
            end
        end

        #draw the x axis of EDA data
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
            for xₙ in range(x, step = 120, stop = x + width)
                hou = hour(time);
                min = minute(time);
                sec = second(time);
                mil = millisecond(time);
                #if sec ==0 && mil ==0
                CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32_, Cfloat(1));   ###################################
                #if mil ==0
                #CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                CImGui.AddText(draw_list, ImVec2(xₙ, y), col32_, string(string(hou), ":", string(min), ":", string(sec)));   ###############################
                next_time = time + Dates.Millisecond(Cint((end_time-start_time+1)*f*100));
                time = next_time;
            end
        end

        #draw the EDA overview
        CImGui.NewLine()
        overview_data = Cfloat.(data[3:end,1])
        begin
            width = 1200
            height = 100
            CImGui.PlotLines("EDA Overview", overview_data, length(overview_data), 0 , "EDA", 0, Cfloat(max_value*1.2), (width,height))
            draw_list = CImGui.GetWindowDrawList()
            p = CImGui.GetCursorScreenPos()
            x = p.x
            y = p.y
            spacing = 8.0
            time = Dates.unix2datetime(st)
            f = Cfloat(1 / freq)
            CImGui.AddLine(draw_list, ImVec2(x, y), ImVec2(x+width, y), col32_, Cfloat(1));
            for xₙ in range(x, step = 60, stop = x + width)
                hou = hour(time);
                min = minute(time);
                sec = second(time);
                mil = millisecond(time);
                #if sec ==0 && mil ==0
                CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32_, Cfloat(1));   ###################################
                #if mil ==0
                #CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                CImGui.AddText(draw_list, ImVec2(xₙ, y), col32_, string(string(hou), ":", string(min), ":", string(sec)));   ###############################
                next_time = time + Dates.Millisecond(Cint(len*f*50));
                time = next_time;
            end
            CImGui.AddLine(draw_list, ImVec2(x+Cfloat(1200/(len-1)*(start_time-1)), y), ImVec2(x+Cfloat(1200/(len-1)*(start_time-1)), y-105), col32_, Cfloat(3));
            CImGui.AddLine(draw_list, ImVec2(x+Cfloat(1200/(len-1)*(end_time-1)), y), ImVec2(x+Cfloat(1200/(len-1)*(end_time-1)), y-105), col32_, Cfloat(3));
        end

        CImGui.NewLine()
        CImGui.Separator()
        #plotting Date 2(HR data)
        CImGui.NewLine()
        p = CImGui.GetCursorScreenPos()
        begin
            width = 1200
            height = 200
            CImGui.PlotLines("HR Measurements", plot_data2, length(plot_data2), 0 , string("HR Mean:",string(mean2)), 0, Cfloat(max_value2*1.2), (width,height))
            draw_list2 = CImGui.GetWindowDrawList()
            x = p.x
            y = p.y
            spacing = 8.0
            # Draws (almost transparent) horizontal bars
            for yₙ in range(y, step = 40, stop = y + height - 40)
                CImGui.AddRectFilled(draw_list2, ImVec2(x, yₙ), ImVec2(x+width, yₙ+20), col32);
            end
        end

        #draw the x axis of HR
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
            for xₙ in range(x, step = 120, stop = x + width)
                hou = hour(time);
                min = minute(time);
                sec = second(time);
                mil = millisecond(time);
                CImGui.AddLine(draw_list2, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32_, Cfloat(1));
                #if mil ==0
                #CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                CImGui.AddText(draw_list2, ImVec2(xₙ, y), col32_, string(string(hou), ":", string(min), ":", string(sec)));
                next_time = time + Dates.Millisecond(Cint((end_time2-start_time2+1)*f*100));
                time = next_time;
            end
        end

        #draw the overview HR
        CImGui.NewLine()
        overview_data2 = Cfloat.(data2[3:end,1])
        begin
            width = 1200
            height = 100
            CImGui.PlotLines("HR Overview", overview_data2, length(overview_data2), 0 , "HR", 0, Cfloat(max_value2*1.2), (width,height))
            draw_list = CImGui.GetWindowDrawList()
            # for yₙ in range(y, step = 50, stop = y + height)
            #     CImGui.AddRectFilled(draw_list, ImVec2(x, yₙ), ImVec2(x+width, yₙ+20), Cfloat[255.0,255.0,255.0,0.5]);
            # end
            p = CImGui.GetCursorScreenPos()
            x = p.x
            y = p.y
            spacing = 8.0
            time = Dates.unix2datetime(st2)
            f = Cfloat(1 / freq2)
            CImGui.AddLine(draw_list, ImVec2(x, y), ImVec2(x+width, y), col32_, Cfloat(1));
            for xₙ in range(x, step = 60, stop = x + width)
                hou = hour(time);
                min = minute(time);
                sec = second(time);
                mil = millisecond(time);
                #if sec ==0 && mil ==0
                CImGui.AddLine(draw_list, ImVec2(xₙ, y), ImVec2(xₙ, y-5), col32_, Cfloat(1));   ###################################
                #if mil ==0
                #CImGui.AddText(draw_list, ImVec2(xₙ, y), col32, string(string(min), ":", string(sec)));
                CImGui.AddText(draw_list, ImVec2(xₙ, y), col32_, string(string(hou), ":", string(min), ":", string(sec)));   ###############################
                next_time = time + Dates.Millisecond(Cint(len2*f*50));
                time = next_time;
            end
            CImGui.AddLine(draw_list, ImVec2(x+Cfloat(1200/(len2-1)*(start_time2-1)), y), ImVec2(x+Cfloat(1200/(len2-1)*(start_time2-1)), y-105), col32_, Cfloat(3));
            CImGui.AddLine(draw_list, ImVec2(x+Cfloat(1200/(len2-1)*(end_time2-1)), y), ImVec2(x+Cfloat(1200/(len2-1)*(end_time2-1)), y-105), col32_, Cfloat(3));
        end
    end
end
