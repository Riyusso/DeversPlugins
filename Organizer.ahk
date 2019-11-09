#NoEnv
#SingleInstance FORCE
SendMode Input
SetWorkingDir %A_ScriptDir%
Plugin.Properties() ; Pass true as a parameter if you wish to have a tray icon.
return

#Include *i Libraries\Functions.lib

/*
------ Example 1 ------
This hotkey(Win + 1) will organize all files and folders inside a folder of your choice.
Every file or folder older than the amount of hours specified(48) will be moved to a folder named "Stored". 
Parameter 1: Path to the folder you wish to sort.
Parameter 2: Hours since the files/folders were modified.
#1::
Organizer.Organize("D:\Latest", 48)
return

------ Example 2 ------
This hotkey(Win + 2) will clean a folder of your choice. Every file or folder older than the amount of hours specified(48) will be deleted.
Parameter 1: Path to the folder you wish to sort.
Parameter 2: Hours since the files/folders were modified.
#2::
Organizer.Clean("D:\Archives", 48)
return

------ Example 3 ------
Win + 3 will take all of the video files(movies and tv show episodes) from a folder and sort them in the folders you specify. In this case all movies from D:\Torrents will be moved to D:\Movies
and tv shows to D:\Shows.
Parameter 1: Path to the folder that contains the movies/shows.
Parameter 2: Path to the folder that the movies will be moved to.
Parameter 3: Path to the folder that the tv shows will be moved to.
Your Movies will go to D:\Movies and your tv show episodes will go to D:\Shows
#3::
Organizer.SortVideoFiles("D:\Torrents", "D:\Movies", "D:\Shows")
return
*/

; --------- User hotkeys here ----------



; Shortcut Win + O
#SC018::
Organizer.Organize("D:\Downloads", 48)
return






Class Organizer
{
    static extensions := "mp4,mkv,avi,wmv"    
    static toFolder := "Stored"
    static INCOMPLETE_FOLDER_NAME := "Incomplete Torrents"
    static ACTION_MOVE := 1
    static ACTION_DELETE := 2
    static EPISODE_FILESIZE_CAP := 2048
    static EPISODE_REGEX_PATTERN := "(\W)(S|s)\d{1,2}\D{1,2}\d{1,2}\D?"
    static TVSHOW_SEASON_REGEX_PATTERN := "(\W)(S|s)\d{1,2}"

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

    SortVideoFiles(path, toSortFolderMovies, toSortFolderEpisodes)
    {

        path := this.RemoveTrailingSlashes(path)
        toSortFolderMovies := this.RemoveTrailingSlashes(toSortFolderMovies)
        toSortFolderEpisodes := this.RemoveTrailingSlashes(toSortFolderEpisodes)

        Loop, %path%\*.*,, 1
        {
            if % (A_LoopFileExt = "nfo") || (InStr(A_LoopFileFullPath, "sample") && InStr(this.extensions, A_LoopFileExt))
            {
                FileDelete, %A_LoopFileFullPath%
                continue
            }

            if InStr(A_LoopFileFullPath, ".unwanted") || InStr(A_LoopFileFullPath, this.INCOMPLETE_FOLDER_NAME) || !InStr(this.extensions, A_LoopFileExt)
                continue

            if ((A_LoopFileSizeMB < this.EPISODE_FILESIZE_CAP) && RegExMatch(A_LoopFileName, this.EPISODE_REGEX_PATTERN)) || RegExMatch(A_LoopFileName, this.EPISODE_REGEX_PATTERN)
            {
                destination := this.GetEpisodeSortFolder(toSortFolderEpisodes, A_LoopFileName)
            }
            else if (A_LoopFileSizeMB > this.EPISODE_FILESIZE_CAP) && !RegExMatch(A_LoopFileName, this.EPISODE_REGEX_PATTERN)
            {
                destination := toSortFolderMovies
            }
            else
            {
                MsgBox, 3, Is this file a tv show episode?, %A_LoopFileName%, 15

                IfMsgBox, Yes
                    destination := this.GetEpisodeSortFolder(toSortFolderEpisodes, A_LoopFileName) 
                else IfMsgBox, No
                    destination := toSortFolderMovies
                else IfMsgBox, Cancel
                    continue
                else
                    destination := (A_LoopFileSizeMB < this.EPISODE_FILESIZE_CAP) ? this.GetEpisodeSortFolder(toSortFolderEpisodes, A_LoopFileName) : toSortFolderMovies ; DEFAULT
            }

            IfNotExist, %destination%
                FileCreateDir, %destination%

            FileMove, %A_LoopFileFullPath%, %destination%
        }

        this.CleanUpEmptyFolders(path)

    }

    GetShowNameAndSeason(fileName)
    {
        RegExMatch(fileName, "O)" . this.EPISODE_REGEX_PATTERN, Match)
        tvShowName := SubStr(fileName, 1, Match.Pos)
        tvShowName := StrReplace(tvShowName, ".", A_Space)
        tvShowName := Trim(tvShowName)

        RegExMatch(fileName, "O)" . this.TVSHOW_SEASON_REGEX_PATTERN, SE)
        tvShowSeason := StrReplace(SE[0], ".", A_Space)
        tvShowSeason := Trim(tvShowSeason)

        if !(tvShowName && tvShowSeason)
            return

        return tvShowName . " " . tvShowSeason
    }

    GetEpisodeSortFolder(toSortFolderEpisodes, fileName)
    {
        return toSortFolderEpisodes . "\" . this.GetShowNameAndSeason(fileName)
    }

    CleanUpEmptyFolders(path)
    {
        Loop %path%\*.*, 2
            this.CleanAndDeleteIfEmpty(A_LoopFileFullPath)
    }

    CleanAndDeleteIfEmpty(path)
    {
        Loop %path%\*.*, 2
            this.CleanAndDeleteIfEmpty(A_LoopFileFullPath)

        if (this.IsEmpty(path) || InStr(path, ".unwanted")) && !InStr(path, this.INCOMPLETE_FOLDER_NAME)
        {
            FileRemoveDir, %path%, 1
        }
    }

    IsEmpty(Dir)
    {
        Loop %Dir%\*.*, 0, 1
            return 0
        return 1
    }

    RemoveTrailingSlashes(string)
    {
        return RTrim(string, " `\")
    }

    ; Please refrain from using this method directly if you don't know what you're doing.
    MoveOrDeleteFiles(path, action, hoursSinceModification)
    {
        Loop, %path%\*.*
        {
            if % A_LoopFileName = "desktop.ini"
                continue

            currentItemHours := A_Now
            EnvSub, currentItemHours, %A_LoopFileTimeModified%, minutes
            if (currentItemHours > hoursSinceModification*60)
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
            EnvSub, currentItemHours, %A_LoopFileTimeModified%, minutes
            if (currentItemHours > hoursSinceModification*60)
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
}