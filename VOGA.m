%% VOGA.m
% This script should be used to segment, filter data, select cycles, and
% parameterize batches of files. 
% It needs to initially run from the file that it's in (so that it can add
% all code to path).
% Click cancel to end the loop
% Updated on 2021-01-25

opts = {'Initialize','Set Data Path','Segment','Cycle Average','Summary Table','Generate Figures','Set Version'};
ind = 1; %Run the start procedure first
tf1 = 1;
while tf1
    if strcmp(opts{ind},'Initialize')        
        code_Path = [userpath,filesep,'VOGA']; %Don't assume you start in the codepath
        addpath(genpath(code_Path))
    elseif strcmp(opts{ind},'Set Data Path') 
        %% Set Path
        % Assumes you are in the right directory already
        path = cd;
        Raw_Path = [path,filesep,'Raw Files'];
        Seg_Path = [path,filesep,'Segmented Files'];
        Cyc_Path = [path,filesep,'Cycle Averages'];
        %See if the folders already exist or need to be renamed/created
        path_folders = extractfield(dir,'name',find(extractfield(dir,'isdir')));
        if any(contains(path_folders,'Raw LD VOG Files'))
            movefile('Raw LD VOG Files','Raw Files')
        elseif ~any(contains(path_folders,'Raw Files'))
            mkdir('Raw Files')
        end
        if any(contains(path_folders,'CycAvg')) 
            movefile('CycAvg','Cycle Averages')
        elseif any(contains(path_folders,'Cyc_Avg')) 
            movefile('Cyc_Avg','Cycle Averages')
        elseif ~any(contains(path_folders,'Cycle Averages'))
            mkdir('Cycle Averages')
        end
        if ~any(contains(path_folders,'Segmented Files'))
            mkdir('Segmented Files')
        end
    elseif strcmp(opts{ind},'Segment') 
        %% Segment
        if ~exist(path,'var')
            path = cd;
            Raw_Path = [path,filesep,'Raw Files'];
            Seg_Path = [path,filesep,'Segmented Files'];
            Cyc_Path = [path,filesep,'Cycle Averages'];
        end
        % Prepare to Segment
        %Transfer NKI Raw Files from their subfolders if they exist
        moveNKIfiles(Raw_Path)
        %Detect and process log files and austoscan files
        logtoNotes(Raw_Path)
        % Select files to segment
        all_files = extractfield(dir(Raw_Path),'name',find(~extractfield(dir(Raw_Path),'isdir')));
        VOG_files = all_files(((contains(all_files,'SESSION')&contains(all_files,'.txt'))|contains(all_files,'.dat'))...
            &~contains(all_files,'-Notes.txt'));
        if isempty(VOG_files) 
            uiwait(msgbox('No VOG files found in the Raw Files folder.'))
        else
            [indx,tf] = nmlistdlg('PromptString','Select files to segment:','ListSize',[300 300],'ListString',VOG_files);
            if tf == 1
                sel_files = VOG_files(indx);
                for i = 1:length(sel_files)
                    In_Path = [Raw_Path,filesep,sel_files{i}];
                    Segment(In_Path,Seg_Path)
                end
            end
        end
    elseif strcmp(opts{ind},'Cycle Average')
        %% Filter and select cycles
        if ~exist(path,'var')
            path = cd;
            Raw_Path = [path,filesep,'Raw Files'];
            Seg_Path = [path,filesep,'Segmented Files'];
            Cyc_Path = [path,filesep,'Cycle Averages'];
        end
        % Get version and experimenter info from the file
        try 
            data = readtable([code_Path,filesep,'VerInfo.txt'],'ReadVariableNames',false);
        catch
            writeInfoFile(code_Path);
            data = readtable([code_Path,filesep,'VerInfo.txt'],'ReadVariableNames',false);
        end
        version = data{1,2}{:};
        Experimenter = data{2,2}{:};
        done = false;
        while(~done) %run until the user hits cancel on analyzing a file
            done = MakeCycAvg(path,Seg_Path,Cyc_Path,Experimenter,version);
        end
    elseif strcmp(opts{ind},'Set Version')
        writeInfoFile(code_Path);
    end
    %% Poll for new reponse
    [ind,tf1] = nmlistdlg('PromptString','Select an action:',...
                       'SelectionMode','single',...
                       'ListSize',[100 100],...
                       'ListString',opts,...
                       'Position',[0,7.75,2,2.75]);    
end
disp('VOGA instance ended.')