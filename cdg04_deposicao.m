% ================================================================
% Separação do tubo + sobreposição do contorno em branco
% ================================================================

clear; close all; clc;

% --- 1) Selecionar pasta principal ---
pastaPrincipal = uigetdir(pwd, 'Selecione a pasta do experimento');
if pastaPrincipal == 0
    error('Nenhuma pasta selecionada. Encerrando.');
end

% Subpasta com as imagens
pastaImagens = fullfile(pastaPrincipal, 'GrayscaleImages');
padrao = 'grayscale_*.jpg';
arquivos = dir(fullfile(pastaImagens, padrao));
if isempty(arquivos)
    error('Nenhuma imagem encontrada em %s', pastaImagens);
end

% Ordenar
[~, idx] = sort({arquivos.name});
arquivos = arquivos(idx);

% --- 3) Último frame ---
ultimoFrame = fullfile(pastaImagens, arquivos(end).name);
fprintf('Processando último frame: %s\n', arquivos(end).name);

% --- 4) Ler imagem ---
Igray = imread(ultimoFrame);

% --- 5) Seleção ROI ---
figure; imshow(Igray); 
title('Selecione ROI sobre o tubo (duplo clique p/ finalizar)');
roi = drawrectangle; wait(roi);
roiMask = roi.createMask;

% --- 6) Loop interativo (ajustar sensibilidade) ---
sens = 0.95;
ok = false;

while ~ok
    BW = imbinarize(Igray, 'adaptive', 'Sensitivity', sens);
    BW = ~BW;            
    BWroi = BW & roiMask;
    
    % Mostrar
    figure(10); clf;
    subplot(1,2,1); imshow(Igray); title('Imagem original');
    subplot(1,2,2); imshow(BWroi); 
    title(sprintf('ROI binária - Sens = %.2f', sens));
    
    % Perguntar novo valor
    prompt = sprintf('Sensibilidade atual = %.2f. Digite novo valor (0-1) ou Enter p/ aceitar: ', sens);
    str = input(prompt,'s');
    
    if isempty(str)
        ok = true;
    else
        sens = str2double(str);
        if isnan(sens) || sens<0 || sens>1
            fprintf('Valor inválido! Digite número entre 0 e 1.\n');
            sens = 0.45;
        end
    end
end

fprintf('Sensibilidade final = %.2f\n', sens);

% --- 7) Segmentação apenas dentro da ROI ---
BW = imbinarize(Igray, 'adaptive', 'Sensitivity', sens);
BW = ~BW;
BW = imopen(BW, strel('disk',5));
BW = imclose(BW, strel('disk',5));
BW = imfill(BW, 'holes');
BWroi = BW & roiMask;

% --- 8) Extrair contorno dentro da ROI ---
contornos = bwboundaries(BWroi);
if isempty(contornos)
    error('Nenhum contorno encontrado dentro da ROI.');
end

% Seleciona maior contorno
numPixels = cellfun(@numel, contornos);
[~, idxMax] = max(numPixels);
contornoGlobal = contornos{idxMax};

% --- 9) Carregar imagem de fundo (sobreposição) ---
pastaSobreposto = fullfile(pastaPrincipal, 'FaixasTemp', 'Sobreposto');
arquivosSobreposto = dir(fullfile(pastaSobreposto, '*.png')); % ajuste extensão se necessário
if isempty(arquivosSobreposto)
    error('Nenhum arquivo encontrado em %s', pastaSobreposto);
end

[~, idx] = sort({arquivosSobreposto.name});
imagemFundo = imread(fullfile(pastaSobreposto, arquivosSobreposto(end).name));

% --- 10) Converter fundo para RGB (caso seja grayscale) ---
if size(imagemFundo,3) == 1
    imagemFundo = repmat(imagemFundo, 1,1,3);
end

% --- 11) Sobrepor contorno em branco na imagem de fundo ---
fig1 = figure; imshow(imagemFundo); hold on;
plot(contornoGlobal(:,2), contornoGlobal(:,1), 'w', 'LineWidth', 2);
title('Contorno da deposição sobreposto (imagem de fundo)');
frame1 = getframe(gca);
saidaImg1 = fullfile(pastaPrincipal, 'Contorno_da_deposicao.png');
imwrite(frame1.cdata, saidaImg1);

% --- 12) Sobrepor contorno em branco na imagem em escala de cinza ---
fig2 = figure; imshow(Igray); hold on;
plot(contornoGlobal(:,2), contornoGlobal(:,1), 'w', 'LineWidth', 2);
title('Contorno sobre o último frame em escala de cinza');
frame2 = getframe(gca);
saidaImg2 = fullfile(pastaPrincipal, 'Contorno_no_ultimoFrame.png');
imwrite(frame2.cdata, saidaImg2);

% --- 13) Salvar coordenadas e workspace ---
saidaMat = fullfile(pastaPrincipal, 'contorno_tubo_ROIglobal.mat');
saidaTxt = fullfile(pastaPrincipal, 'contorno_tubo_ROIglobal.txt');

save(saidaMat, 'contornoGlobal');
dlmwrite(saidaTxt, contornoGlobal, 'delimiter', '\t');

% Salvar workspace inteira
saidaWS = fullfile(pastaPrincipal, 'workspace_contorno.mat');
save(saidaWS);

fprintf('Resultados salvos em:\n  %s\n  %s\n  %s\n  %s\n  %s\n', ...
    saidaImg1, saidaImg2, saidaMat, saidaTxt, saidaWS);
