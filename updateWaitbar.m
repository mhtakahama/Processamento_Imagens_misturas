%% Função auxiliar para atualizar barra de progresso
function updateWaitbar(i)
    % Esta função é chamada a cada imagem processada para atualizar a barra
    
    persistent count total h msg  % variáveis persistentes (mantêm valor entre chamadas)
    
    if isempty(count)
        % Inicializa os valores na primeira chamada
        count = 0;
        total = evalin('base', 'numberOfFiles');  % obtém o número total do workspace base
        h = findall(0, 'Type', 'figure', 'Tag', 'TMWWaitbar');  % encontra barra de progresso
        msg = get(get(h, 'CurrentAxes'), 'Title');
    end
    
    count = count + 1;
    
    % Atualiza a barra com a fração concluída
    waitbar(count / total, h);
end
