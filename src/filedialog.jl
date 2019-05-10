abstract type AbstractDialog end
abstract type AbstractStatus end
mutable struct OpenFileDialog <: AbstractDialog
    opened_directory::String
    opened_file::String
    unconfirmed_directory::String
    unconfirmed_file::String
    visible::Bool
    unprocessed_action::Bool
end

struct ConfirmedStatus <: AbstractStatus end
struct UnconfirmedStatus <: AbstractStatus end

function get_directory(dialog::AbstractDialog, status::UnconfirmedStatus)
    dialog.unconfirmed_directory
end

function get_directory(dialog::AbstractDialog, status::ConfirmedStatus)
    dialog.opened_directory
end

function get_file(dialog::AbstractDialog, status::ConfirmedStatus)
    dialog.opened_file
end

function get_file(dialog::AbstractDialog, status::UnconfirmedStatus)
    dialog.unconfirmed_file
end

function set_directory!(dialog::AbstractDialog, directory_path::String, status::ConfirmedStatus)
    dialog.opened_directory = directory_path
end

function set_directory!(dialog::AbstractDialog, directory_path::String, status::UnconfirmedStatus)
    dialog.unconfirmed_directory = directory_path
end

function set_file!(dialog::AbstractDialog, file_name::String, status::ConfirmedStatus)
    dialog.opened_file = file_name
end
function set_file!(dialog::AbstractDialog, file_name::String, status::UnconfirmedStatus)
    dialog.unconfirmed_file = file_name
end

function isvisible(dialog::AbstractDialog)
    dialog.visible
end

function isconfirmed(dialog::AbstractDialog)
    dialog.confirmed
end

function set_visibility!(dialog::AbstractDialog, flag::Bool)
    dialog.visible = flag
end

function has_pending_action(dialog::AbstractDialog)
    dialog.unprocessed_action
end

function signal_action!(dialog::AbstractDialog)
    dialog.unprocessed_action = true
end

function consume_action!(dialog::AbstractDialog)
    dialog.unprocessed_action = false
end

function display_dialog!(dialog::OpenFileDialog)
    @c CImGui.Begin("Open File", &dialog.visible)
        display_path!(dialog)
        display_directory_file_listing!(dialog)
        display_unconfirmed_file(dialog)
        deal_with_file_confirmation!(dialog)
    CImGui.End()
end

function display_path!(dialog::AbstractDialog)
    path_directories = splitpath(get_directory(dialog, UnconfirmedStatus()))
    selected_directory = Cint(length(path_directories))
    # Draw a button for each directory that constitutes the current path.
    for (index, d) in enumerate(path_directories)
        CImGui.Button(d) && (selected_directory = Cint(index);)
        CImGui.SameLine()
    end
    # If a button is clicked then we keep only the path up-to and including the clicked button.
    path = selected_directory == 1 ? joinpath(first(path_directories)) : joinpath(path_directories[1:selected_directory]...)
    set_directory!(dialog, path, UnconfirmedStatus())
end

function display_directory_file_listing!(dialog::AbstractDialog)
    # Make a list of directories that are visibile from the current directory.
    CImGui.NewLine()
    CImGui.BeginChild("Directory and File Listing", CImGui.ImVec2(CImGui.GetWindowWidth() * 0.98, -CImGui.GetWindowHeight() * 0.2))
        CImGui.Columns(1)
        deal_with_directory_selection!(dialog)
        deal_with_file_selection!(dialog)
    CImGui.EndChild()
end

function display_unconfirmed_file(dialog::AbstractDialog)
    CImGui.Text("File Name:")
    CImGui.SameLine()
    file_name₀ = get_file(dialog, UnconfirmedStatus())
    file_name₁ = file_name₀*"\0"^(1)
    buffer = Cstring(pointer(file_name₁))
    CImGui.InputText("",buffer, length(file_name₁),  CImGui.ImGuiInputTextFlags_ReadOnly)
end


function deal_with_directory_selection!(dialog::AbstractDialog)
    path = get_directory(dialog, UnconfirmedStatus())
    #visible_directories = filter(p->isdir(joinpath(path, p)), readdir(path))
    visible_directories = filter(p->is_readable_dir(joinpath(path, p)), readdir(path))
    for (n, folder_name) in enumerate(visible_directories)
        # When the user clicks on a directory then change directory by appending the selected directory to the current path.
        if CImGui.Selectable("[Dir] " * "$folder_name")
            set_directory!(dialog, joinpath(path, folder_name), UnconfirmedStatus())
            set_file!(dialog, "", UnconfirmedStatus())
        end
    end
end

# The isdir function might not have permissions to query certan folders and
# will thus throw an ERROR: IOError: stat: permission denied (EACCES)
function is_readable_dir(path)
    flag = false
    try
        flag = isdir(path)
    catch x
        flag = false
    end
    return flag
end

function deal_with_file_selection!(dialog::AbstractDialog)
    path = get_directory(dialog, UnconfirmedStatus())
    #visible_files = filter(p->isfile(joinpath(path, p)), readdir(path))
    visible_files = filter(p->is_readable_file(joinpath(path, p)), readdir(path))
    selected_file = Cint(0)
    for (n, file_name) in enumerate(visible_files)
        if CImGui.Selectable("[File] " * "$file_name")
            set_file!(dialog, file_name, UnconfirmedStatus())
        end
    end
end

# The isfile function might not have permissions to query certan files and
# will thus throw an ERROR: IOError: stat: permission denied (EACCES)
function is_readable_file(path)
    flag = false
    try
        flag = isfile(path)
    catch x
        flag = false
    end
    return flag
end

function deal_with_file_confirmation!(dialog::AbstractDialog)
    CImGui.Button("Cancel") && (deal_with_cancellation!(dialog);)
    CImGui.SameLine()
    CImGui.Button("Open") && (deal_with_confirmation!(dialog);)
end

function deal_with_cancellation!(dialog::AbstractDialog)
    set_visibility!(dialog, false)
end

function deal_with_confirmation!(dialog::AbstractDialog)
    set_visibility!(dialog, false)
    set_directory!(dialog, get_directory(dialog, UnconfirmedStatus()), ConfirmedStatus())
    set_file!(dialog, get_file(dialog, UnconfirmedStatus()), ConfirmedStatus())
    signal_action!(dialog)
end
