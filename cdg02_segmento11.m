%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sedimentação - Segmentação + Gradiente com legendas estilo científico
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; close all; clc;

%% Setup
folder = uigetdir('', 'Selecione a pasta que contém a pasta Subtracao');
if folder == 0
    error('Nenhuma pasta selecionada.');
end

subFolder = fullfile(folder, 'Subtracao');
if ~exist(subFolder, 'dir')
    error('Pasta Subtracao não encontrada.');
end

% Carregar função de conversão
if ~exist('gray2conc.m','file')
    error('Arquivo gray2conc.m não encontrado na pasta atual!');
end

% Definição de faixas de intensidade (segmentação)
intensity_bins = [0 10 20 30 40 50 75 100 125 190 255];
num_faixas = length(intensity_bins) - 1;

% Cores para as faixas (sequência visualmente aproximada do gradiente)
faixa_colors = uint8([
    0   0   128;      % azul escuro
    0   0   255;      % azul
    0   128 255;      % azul claro
    0   255 255;      % ciano
    0   255 128;      % verde água
    0   255 0;        % verde
    255 255 0;        % amarelo
    255 128 0;        % laranja
    255 0   0;        % vermelho
    128 0   0;        % vermelho escuro
]);

% LUT fixo do gradiente de concentração (0 a 255)
LUT = jet(256);

% Pastas para salvar frames
tempFaixasFolder = fullfile(folder, 'FaixasTemp');
if ~exist(tempFaixasFolder,'dir'); mkdir(tempFaixasFolder); end
sobrepostoFolder = fullfile(tempFaixasFolder,'Sobreposto'); if ~exist(sobrepostoFolder,'dir'); mkdir(sobrepostoFolder); end
gradFolder = fullfile(tempFaixasFolder,'Gradiente'); if ~exist(gradFolder,'dir'); mkdir(gradFolder); end

% Pastas por faixa
for i = 1:num_faixas
    pasta_i = fullfile(tempFaixasFolder,sprintf('Faixa_%02d',i));
    if ~exist(pasta_i,'dir'); mkdir(pasta_i); end
end

% Lista de imagens
subFiles = dir(fullfile(subFolder,'*.jpg'));
numSubFiles = length(subFiles);
if numSubFiles==0, error('Nenhuma imagem na pasta Subtracao'); end

disp('Processando imagens...');

parfor k = 1:numSubFiles
    imgPath = fullfile(subFolder, subFiles(k).name);
    img = imread(imgPath);
    if size(img,3)>1, img = rgb2gray(img); end
    
    % --- Gradiente de concentração fixo ---
    grad_frame = ind2rgb(double(img)+1, LUT); % LUT de 0 a 255
    imwrite(grad_frame, fullfile(gradFolder, sprintf('frame_%04d.png',k)));
    
    % --- Segmentação por faixas ---
    frame_sobreposto = zeros([size(img),3],'uint8');
    for i = 1:num_faixas
        v_min = intensity_bins(i);
        v_max = intensity_bins(i+1);
        if i<num_faixas
            faixa_mask = img>=v_min & img<v_max;
        else
            faixa_mask = img>=v_min & img<=v_max;
        end
        faixa_img = zeros([size(img),3],'uint8');
        for ch = 1:3
            faixa_img(:,:,ch) = uint8(faixa_mask) * faixa_colors(i,ch);
        end
 %       outPath = fullfile(tempFaixasFolder,sprintf('Faixa_%02d',i),sprintf('frame_%04d.png',k));
 %       imwrite(faixa_img,outPath);
        frame_sobreposto = uint8(min(double(frame_sobreposto)+double(faixa_img),255));
    end
    imwrite(frame_sobreposto, fullfile(sobrepostoFolder,sprintf('frame_%04d.png',k)));
    
    fprintf('Imagem %d de %d processada.\n', k,numSubFiles);
end

disp('Frames processados.');

%% --- Criar legendas estilo barras horizontais ---
% 
% % 1) Segmentação
% figSeg = figure('Name','Legenda Segmentação','Color','w');
% hold on;
% for i = 1:num_faixas
%     y = i; height = 0.8;
%     rectangle('Position',[0 y-0.4,1,height],'FaceColor',double(faixa_colors(i,:))/255,'EdgeColor','k');
% 
%     % rectangle('Position',[0 y-0.4,1,height],'FaceColor',faixa_colors(i,:)/255,'EdgeColor','k');
%     text(1.1,y-0.1,sprintf('%d-%d',intensity_bins(i),intensity_bins(i+1)),'FontSize',12);
% end
% xlim([0 2]); ylim([0 num_faixas+1]);
% axis off; title('Legenda Segmentação','FontSize',14);
% saveas(figSeg, fullfile(sobrepostoFolder,'Legenda_Segmentacao.fig'));
% saveas(figSeg, fullfile(sobrepostoFolder,'Legenda_Segmentacao.jpeg'));
% Criar figura da legenda de segmentação
fig_seg = figure('Color','w','Position',[100 100 300 400]);
hold on;
axis off

height = 1; % altura de cada barra
num_bars = num_faixas;
for i = 1:num_faixas
    y = num_bars - i + 1; % inverter eixo vertical para cima
    rectangle('Position',[0 y-0.5,1,height],'FaceColor',double(faixa_colors(i,:))/255,'EdgeColor','k');
    
    % Converter valores da faixa de escala de cinza para concentração
    conc_min = gray2conc(intensity_bins(i));
    conc_max = gray2conc(intensity_bins(i+1));
    text(1.05,y-0.25,sprintf('%.3f - %.3f %%', conc_min, conc_max),'VerticalAlignment','middle','FontSize',10);
end
xlim([0 2])
ylim([0 num_bars])
title('Segmentação por faixas (Concentração)')

% Salvar figura
saveas(fig_seg, fullfile(folder,'Legenda_Segmentacao.jpg'));
savefig(fig_seg, fullfile(folder,'Legenda_Segmentacao.fig'));
close(fig_seg);

% % 2) Gradiente de concentração
% figGrad = figure('Name','Legenda Gradiente Concentração','Color','w');
% hold on;
% num_bins = 20; % número de divisões para plot
% for i = 0:num_bins-1
%     g_idx = round(i*(255/(num_bins-1)))+1;
%     y = num_bins-i; height = 0.8;
%     conc_val = gray2conc(g_idx-1); % converter para concentração
%     rectangle('Position',[0 y-0.4,1,height],'FaceColor',LUT(g_idx,:),'EdgeColor','k');
%     text(1.1,y-0.1,sprintf('%.2',conc_val),'FontSize',12);
% end
% xlim([0 2]); ylim([0 num_bins+1]);
% axis off; title('Legenda Gradiente Concentração','FontSize',14);
% saveas(figGrad, fullfile(gradFolder,'Legenda_Gradiente.fig'));
% saveas(figGrad, fullfile(gradFolder,'Legenda_Gradiente.jpeg'));
% 2) Gradiente de concentração
figGrad = figure('Name','Legenda Gradiente Concentração','Color','w');
hold on;
num_bins = 20; % número de divisões para plot
for i = 0:num_bins-1
    g_idx = round(i*(255/(num_bins-1)))+1;
    y = num_bins-i; 
    height = 0.8;
    
    % Converter para concentração
    conc_val = gray2conc(g_idx-1); % escala 0-255
    
    % Desenhar barra do gradiente
    rectangle('Position',[0 y-0.4,1,height],'FaceColor',LUT(g_idx,:),'EdgeColor','k');
    
    % Texto com 3 casas decimais
    text(1.1,y-0.1,sprintf('%.3f', conc_val),'FontSize',12);
end

xlim([0 2]); 
ylim([0 num_bins+1]);
axis off; 
title('Legenda Gradiente Concentração','FontSize',14);

% Salvar figura
saveas(figGrad, fullfile(gradFolder,'Legenda_Gradiente.fig'));
saveas(figGrad, fullfile(gradFolder,'Legenda_Gradiente.jpeg'));
close(figGrad);

disp('Legendas salvas com sucesso.');

%% --- Plot da curva gray2conc.m ---
x_gray = 0:255;
y_conc = gray2conc(x_gray);

figCurve = figure('Color','w','Position',[100 100 600 400]);
plot(x_gray, y_conc,'-','LineWidth',2,'Color',[0 0.4470 0.7410]); % azul estilo MATLAB
grid on; box on;
xlabel('Escala de Cinza (0-255)','FontSize',12,'FontWeight','bold');
ylabel('Concentração (%)','FontSize',12,'FontWeight','bold');
title('Curva de conversão Gray \rightarrow Concentração','FontSize',14,'FontWeight','bold');

% Ajustar limites
xlim([0 255]);
ylim([0 max(y_conc)*1.1]);

% Salvar figura
saveas(figCurve, fullfile(folder,'Curva_gray2conc.jpeg'));
savefig(figCurve, fullfile(folder,'Curva_gray2conc.fig'));
close(figCurve);

disp('Curva gray2conc salva com sucesso.');
