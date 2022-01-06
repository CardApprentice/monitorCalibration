function plotMultipleMeasurementsTogether()
    % Take in measurement files

    fileNames = uigetfile('.csv',...
                        'Select one or more measurements you want to plot',...
                        'MultiSelect','on');
    if iscellstr(fileNames) == 0
        fileNames = cellstr(fileNames);
    end
    nMeas = size(fileNames,2);

    % get parameters of each measurement files
    data = {};
    nRows = [];
    lumiCols = [];
    temperaCol = 11; % col 11 is the temperature
    for i = 1:nMeas
        temp = dlmread(fileNames{i});
        nRows(i) = size(temp,1);
        nCol = size(temp,2);
        if nCol == 11
            lumiCols(i) = 7;
        elseif nCol == 14
            lumiCols(i) = 12;
        end
        data = [data;temp];
    end

    % plot them
    fig = figure;
    for i = 1:nMeas
        nRow = nRows(i);
        secCut = nRow/4;
        currentData = data{i};
        contrast = currentData(1:secCut,1)';
        lumiCol = lumiCols(i);
        tempera = currentData(1,temperaCol); % temperature will all be same for a given file
        rLum = currentData(1:secCut,lumiCol);
        gLum = currentData(secCut+1:2*secCut, lumiCol);
        bLum = currentData(2*secCut+1:3*secCut, lumiCol);
        wLum = currentData(3*secCut+1:4*secCut, lumiCol);
        % make a group of labels that all repeats this file name
        nameLabels = cell(1,secCut);
        for k = 1:secCut
            nameLabels{k} = sprintf(fileNames{i});
        end
        thisPlot = plot(contrast,rLum,'r'); hold on
        theseLabels = dataTipTextRow('ID =',nameLabels);
        thisPlot.DataTipTemplate.DataTipRows = theseLabels;
        thisPlot.DataTipTemplate.DataTipRows(end+1).Label = num2str(tempera);
        
        thisPlot = plot(contrast,gLum,'g');
        theseLabels = dataTipTextRow('ID =',nameLabels);
        thisPlot.DataTipTemplate.DataTipRows = theseLabels;
        thisPlot.DataTipTemplate.DataTipRows(end+1).Label = num2str(tempera);

        thisPlot = plot(contrast,bLum,'b');
        theseLabels = dataTipTextRow('ID =',nameLabels);
        thisPlot.DataTipTemplate.DataTipRows = theseLabels;
        thisPlot.DataTipTemplate.DataTipRows(end+1).Label = num2str(tempera);
        
        thisPlot = plot(contrast,wLum,'k');
        theseLabels = dataTipTextRow('ID =',nameLabels);
        thisPlot.DataTipTemplate.DataTipRows = theseLabels;
        thisPlot.DataTipTemplate.DataTipRows(end+1).Label = num2str(tempera);
        legend('off');
    end
    title([num2str(nMeas),' Measurement(s)']);
end  