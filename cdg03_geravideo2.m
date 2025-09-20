%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Gerar vídeos individuais e comparativo lado a lado
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc;

%% Configurações
frame_rate = 30; % fps
pasta_raiz = uigetdir('', 'Selecione a pasta raiz com todos os frames');
if pasta_raiz == 0
    error('Nenhuma pasta selecionada.');
end

% Pastas dos frames
folders = { ...
    pasta_raiz, ...
    fullfile(pasta_raiz, 'Subtracao'), ...
    fullfile(pasta_raiz, 'FaixasTemp', 'Gradiente'), ...
    fullfile(pasta_raiz, 'FaixasTemp', 'Sobreposto') ...
};

video_names = {'Video_Original.avi','Video_Subtracao.avi','Video_Gradiente.avi','Video_Sobreposto.avi'};

%% 1) Criar vídeos individuais
for f = 1:length(folders)
    frame_files = dir(fullfile(folders{f}, '*.png'));
    if isempty(frame_files)
        frame_files = dir(fullfile(folders{f}, '*.jpg'));
    end
    if isempty(frame_files)
        warning('Nenhum frame encontrado na pasta %s', folders{f});
        continue
    end
    
    % Ordenar arquivos
    [~, idx] = sort({frame_files.name});
    frame_files = frame_files(idx);
    
    % Criar vídeo
    vidObj = VideoWriter(fullfile(folders{f}, video_names{f}));
    vidObj.FrameRate = frame_rate;
    open(vidObj);
    
    for k = 1:length(frame_files)
        frame = imread(fullfile(folders{f}, frame_files(k).name));
        
        % Checar rotação e ajustar se necessário
        if size(frame,1) < size(frame,2)
            frame = imrotate(frame,90);
        end
        
        writeVideo(vidObj, frame);
    end
    close(vidObj);
    fprintf('Vídeo salvo: %s\n', fullfile(folders{f}, video_names{f}));
end

%% 2) Criar vídeo comparativo lado a lado
% Ler frames
num_frames = min(cellfun(@(p) length(dir(fullfile(p,'*.png'))), folders));
if num_frames == 0
    num_frames = min(cellfun(@(p) length(dir(fullfile(p,'*.jpg'))), folders));
end

vidComp = VideoWriter(fullfile(pasta_raiz,'Video_Comparativo.avi'));
vidComp.FrameRate = frame_rate;
open(vidComp);

for k = 1:num_frames
    frames = cell(1,4);
    for f = 1:4
        frame_files = dir(fullfile(folders{f}, '*.png'));
        if isempty(frame_files)
            frame_files = dir(fullfile(folders{f}, '*.jpg'));
        end
        [~, idx] = sort({frame_files.name});
        frame_files = frame_files(idx);
        frame = imread(fullfile(folders{f}, frame_files(k).name));
        if size(frame,1) < size(frame,2)
            frame = imrotate(frame,90);
        end
        frames{f} = frame;
    end
    
    % Ajustar tamanho para concatenar
    min_rows = min(cellfun(@(x) size(x,1), frames));
    min_cols = min(cellfun(@(x) size(x,2), frames));
    for f = 1:4
        frames{f} = imresize(frames{f}, [min_rows min_cols]);
    end
    
    % Concatenar horizontalmente
    comp_frame = cat(2, frames{:});
    writeVideo(vidComp, comp_frame);
end
close(vidComp);
fprintf('Vídeo comparativo salvo: %s\n', fullfile(pasta_raiz,'Video_Comparativo.avi'));
