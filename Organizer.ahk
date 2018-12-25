#NoEnv
#SingleInstance FORCE
SendMode Input
SetWorkingDir %A_ScriptDir%
Plugin.Properties() ; Pass true as a parameter if you wish to have a tray icon.
return

#Include *i Libraries\Functions.lib

; ------ Example 1 ------
; This hotkey(Win + 1) will organize all files and folders inside a folder of your choice.
; Every file or folder older than the amount of hours specified(48) will be moved to a folder named "Organized". 
; Parameter 1: Path to the folder you wish to sort.
; Parameter 2: Hours since the file was modified.
; #1::
; Organizer.Organize("D:\Latest", 48)
; return

; ------ Example 2 ------
; This hotkey(Win + 2) will clean a folder of your choice. Every file or folder older than the amount of hours specified(48) will be deleted.
; Parameter 1: Path to the folder you wish to sort.
; Parameter 2: Hours since the file was modified.
; #2::
; Organizer.Clean("D:\Archives", 48)
; return

; ------ Example 3 ------
; Win + 3 will take all of the video files(movies and tv show episodes and sort them in a folder of your choice which in this case is Movies)
; Your Movies will go to D:\Sorted\Movies and your tv show episodes will go to D:\Sorted\Episodes
; #3::
; Organizer.SortVideoFiles("D:\Torrents", "D:\Sorted")
; return

; ----------- User functions here ------------






Class Organizer
{
    static extensions := "mp4,mkv,avi,wmv"    
    static toFolder := "Organized"
    static INCOMPLETE_FOLDER_NAME := "Incomplete Torrents"
    static ACTION_MOVE := 1
    static ACTION_DELETE := 2
    static EPISODE_FILESIZE_CAP := 2048
    static EPISODE_REGEX_PATTERN := "(\W)(S|s)\d{1,2}\D{1,2}\d{1,2}\D?"

    Organize(path, hoursSinceModification="0")
    {
        this.MoveOrDeleteFiles(path, this.ACTION_MOVE, hoursSinceModification)
        this.MoveOrDeleteFolders(path, this.ACTION_MOVE, hoursSinceModification)

        this.CleanUpEmptyFolders(path)
    }

    Clean(path, hoursSinceModification="0")
    {
        this.MoveOrDeleteFiles(path, this.ACTION_DELETE, hoursSinceModification)
        this.MoveOrDeleteFolders(path, this.ACTION_DELETE, hoursSinceModification)

        this.CleanUpEmptyFolders(path)
    }

    SortVideoFiles(path, toSortFolder)
    {
        Loop, %path%\*.*,, 1
        {
            if % (A_LoopFileExt = "nfo") || (InStr(A_LoopFileFullPath, "sample") && InStr(this.extensions, A_LoopFileExt))
            {
                FileDelete, %A_LoopFileFullPath%
                continue
            }

            if InStr(A_LoopFileFullPath, ".unwanted") || InStr(A_LoopFileFullPath, this.INCOMPLETE_FOLDER_NAME) || !InStr(this.extensions, A_LoopFileExt)
                continue


            if (A_LoopFileSizeMB < this.EPISODE_FILESIZE_CAP) && RegExMatch(A_LoopFileName, this.EPISODE_REGEX_PATTERN)
            {
                destination := toSortFolder "\Episodes" 
            }
            else if (A_LoopFileSizeMB > this.EPISODE_FILESIZE_CAP) && !RegExMatch(A_LoopFileName, this.EPISODE_REGEX_PATTERN)
            {
                destination := toSortFolder "\Movies" 
            }
            else
            {
                MsgBox, 3, Is this file a tv show episode?, %A_LoopFileName%, 5

                IfMsgBox, Yes
                    destination := toSortFolder "\Episodes"
                else IfMsgBox, No
                    destination := toSortFolder "\Movies"
                else IfMsgBox, Cancel
                    continue
                else
                    destination := (A_LoopFileSizeMB < this.EPISODE_FILESIZE_CAP) ? toSortFolder "\Episodes" : toSortFolder "\Movies" ; DEFAULT
            }

            IfNotExist, %destination%
                FileCreateDir, %destination%

            FileMove, %A_LoopFileFullPath%, %destination%
        }
    }

    ; Please refrain from using this method directly if you don't know what you're doing.
    MoveOrDeleteFiles(path, action, hoursSinceModification)
    {
        Loop, %path%\*.*
        {
            if % A_LoopFileName = "desktop.ini"
                continue

            currentItemHours := A_Now
            EnvSub, currentItemHours, %A_LoopFileTimeModified%, hours
            if (currentItemHours > hoursSinceModification)
            {
                if (action=this.ACTION_MOVE)
                {
                    destination := path "\" this.toFolder

                    IfNotExist, %destination%
                        FileCreateDir, %destination%

                    FileMove, %A_LoopFileFullPath%, % destination "\" A_LoopFileName
                }
                else if (action=this.ACTION_DELETE)
                    FileDelete, %A_LoopFileFullPath%
            }
        }
    }

    ; Please refrain from using this method directly if you don't know what you're doing.
    MoveOrDeleteFolders(path, action, hoursSinceModification)
    {
        Loop, %path%\*, 2
        {
            if % (A_LoopFileName = "desktop.ini") || (A_LoopFileName = this.toFolder) || InStr(A_LoopFileName, this.INCOMPLETE_FOLDER_NAME)
                continue

            currentItemHours := A_Now
            EnvSub, currentItemHours, %A_LoopFileTimeModified%, hours
            if (currentItemHours > hoursSinceModification)
            {
                if (action=this.ACTION_MOVE)
                {
                    destination := path "\" this.toFolder
                    
                    IfNotExist, %destination%
                        FileCreateDir, %destination%
                        
                    FileMoveDir, %A_LoopFileFullPath%, % destination "\" A_LoopFileName
                }
                else if (action=this.ACTION_DELETE)
                    FileDelete, %A_LoopFileFullPath%
            }
        }
    }

    IsEmpty(Dir)
    {
        Loop %Dir%\*.*, 0, 1
            return 0
        return 1
    }

    CleanUpEmptyFolders(path)
    {
        Loop, %path%\*, 2
        {
            if this.IsEmpty(A_LoopFileFullPath) && !InStr(A_LoopFileFullPath, this.INCOMPLETE_FOLDER_NAME)
            {
                FileRemoveDir, %A_LoopFileFullPath%
            }
        }
    }
}