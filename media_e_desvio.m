clear all;
close all;
clc;

%% Definir os diretórios dos arquivos
dir_1 = uigetdir('', 'Selecione a pasta com o mean_values_pontual do teste 1');
if dir_1 == 0
    error('Nenhuma pasta selecionada para referência.');
end
refPattern1 = fullfile(dir_1, '*.txt');
refFiles = dir(refPattern1);
if isempty(refFiles)
    error('Nenhuma imagem .jpg encontrada na pasta de referência.');
end

dir_2 = uigetdir('', 'Selecione a pasta com o mean_values_pontual do teste 2');
if dir_2 == 0
    error('Nenhuma pasta selecionada para referência.');
end
refPattern2 = fullfile(dir_2, '*.txt');
refFiles = dir(refPattern2);
if isempty(refFiles)
    error('Nenhuma imagem .jpg encontrada na pasta de referência.');
end

dir_3 = uigetdir('', 'Selecione a pasta com o mean_values_pontual do teste 3');
if dir_3 == 0
    error('Nenhuma pasta selecionada para referência.');
end
refPattern3 = fullfile(dir_3, '*.txt');
refFiles = dir(refPattern3);
if isempty(refFiles)
    error('Nenhuma imagem .jpg encontrada na pasta de referência.');
end

%% Construir os caminhos completos dos arquivos
file_1 = fullfile(dir_1, 'mean_values_pontual.txt');
file_2 = fullfile(dir_2, 'mean_values_pontual.txt');
file_3 = fullfile(dir_3, 'mean_values_pontual.txt');

% Verificar se os arquivos existem
if exist(file_1, 'file') ~= 2
    error('O arquivo %s não foi encontrado.', file_1);
end

if exist(file_2, 'file') ~= 2
    error('O arquivo %s não foi encontrado.', file_2);
end

if exist(file_3, 'file') ~= 2
    error('O arquivo %s não foi encontrado.', file_3);
end

% Importar os dados dos três arquivos
S1 = importdata(file_1);
S2 = importdata(file_2);
S3 = importdata(file_3);

% Garantir que só números sejam usados
if isstruct(S1), S1 = S1.data; end
if isstruct(S2), S2 = S2.data; end
if isstruct(S3), S3 = S3.data; end

% Limitar o número de linhas ao menor tamanho entre os três arquivos
min_linhas = min([size(S1,1), size(S2,1), size(S3,1)]);
S1 = S1(1:min_linhas, :);
S2 = S2(1:min_linhas, :);
S3 = S3(1:min_linhas, :);

%% Calcular a média e o desvio padrão entre os arquivos
media_S = (S1 + S2 + S3) / 3;
desvio_padrao_S = std(cat(3, S1, S2, S3), 0, 3);

% Fator multiplicativo para a primeira coluna (tempo)
F = 10 * media_S(:,1);

% Selecionar apenas uma coluna a cada duas (P2, P4, P6, P8, P10)
P2 = media_S(:,2); P4 = media_S(:,4); P6 = media_S(:,6);
P8 = media_S(:,8); P10 = media_S(:,10);

% Definir manualmente as cores da paleta viridis (5 cores)
viridis_colors = [
    0.267004, 0.004874, 0.329415;  % Cor 1
    0.229739, 0.322361, 0.545706;  % Cor 2
    0.65, 0.78, 0.93;  % Cor 3
    0.369214, 0.788888, 0.382914;  % Cor 4
    0.993248, 0.906157, 0.143936;  % Cor 5
];

% Reduzir a quantidade de dados a serem plotados (por exemplo, 1 a cada 5 pontos)
reducao = 10;
idx = 1:reducao:length(F);

% Reduzir a quantidade de barras de erro a serem plotadas (por exemplo, 1 a cada 10 pontos)
barras_erro_reducao = 30;
idx_barras_erro = 1:barras_erro_reducao:length(F);

hold on;

%% Plote os dados reduzidos e trace linhas retas entre os pontos
g2 = plot(F(idx), P2(idx), '-x', 'Color', viridis_colors(1, :), 'LineWidth', 1.5); % Cor 1
g4 = plot(F(idx), P4(idx), '-s', 'Color', viridis_colors(2, :), 'LineWidth', 1.5); % Cor 2
g6 = plot(F(idx), P6(idx), '-d', 'Color', viridis_colors(3, :), 'LineWidth', 1.5); % Cor 3
g8 = plot(F(idx), P8(idx), '-v', 'Color', viridis_colors(4, :), 'LineWidth', 1.5); % Cor 4
g10 = plot(F(idx), P10(idx), '-p', 'Color', viridis_colors(5, :), 'LineWidth', 1.5); % Cor 5

% Plotar o desvio padrão com linhas de erro (error bars) somente para os pontos selecionados
errorbar(F(idx_barras_erro), P2(idx_barras_erro), desvio_padrao_S(idx_barras_erro,3), 'x', 'Color', viridis_colors(1, :), 'CapSize', 10);
errorbar(F(idx_barras_erro), P4(idx_barras_erro), desvio_padrao_S(idx_barras_erro,5), 's', 'Color', viridis_colors(2, :), 'CapSize', 10);
errorbar(F(idx_barras_erro), P6(idx_barras_erro), desvio_padrao_S(idx_barras_erro,7), 'd', 'Color', viridis_colors(3, :), 'CapSize', 10);
errorbar(F(idx_barras_erro), P8(idx_barras_erro), desvio_padrao_S(idx_barras_erro,9), 'v', 'Color', viridis_colors(4, :), 'CapSize', 10);
errorbar(F(idx_barras_erro), P10(idx_barras_erro), desvio_padrao_S(idx_barras_erro,11), 'p', 'Color', viridis_colors(5, :), 'CapSize', 10);

% Criar a legenda com valores variando de 0.95 a cada 0.1
legenda = 0.95:-0.2:(0.95 - (length([g2 g4 g6 g8 g10]) - 1) * 0.2);
legend([g2 g4 g6 g8 g10], string(legenda), 'Location', 'best', 'Orientation', 'vertical', 'FontSize', 10, 'Interpreter', 'latex', 'Box', 'off');

% Configurar a legenda
lgd = legend;
lgd.NumColumns = 1;
title(lgd, '\textit{z/h}', 'Interpreter', 'latex');

% Configurações dos eixos
xlabel('t[s]', 'Fontname', 'Times', 'FontSize', 12, 'Interpreter', 'latex');
ylabel('C[v/v]', 'Fontname', 'Times', 'FontSize', 12, 'Interpreter', 'latex');
ylim([0, 0.100]);
xlim([0, 4500]);

% Configurações da figura
set(gcf, 'Units', 'Inches', 'Position', [0, 0, 4.72, 4.72], 'PaperUnits', 'Inches', 'PaperSize', [4.72, 4.72]);

box on;
hold off;

%% Gerar arquivo .txt com os dados

% Nome do arquivo de saída
output_file = 'media_e_desvio_viridis.txt';

% Abrir arquivo para escrita
fid = fopen(output_file, 'w');

% Escrever cabeçalho
fprintf(fid, 'Tempo (t[s]), P2, P4, P6, P8, P10, Desvio Padrão P2, Desvio Padrão P4, Desvio Padrão P6, Desvio Padrão P8, Desvio Padrão P10\n');

% Escrever os dados no arquivo
for i = 1:length(F)
    fprintf(fid, '%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n', F(i), P2(i), P4(i), P6(i), P8(i), P10(i), desvio_padrao_S(i,3), desvio_padrao_S(i,5), desvio_padrao_S(i,7), desvio_padrao_S(i,9), desvio_padrao_S(i,11));
end

% Fechar o arquivo
fclose(fid);

disp(['Arquivo salvo como: ', output_file]);
