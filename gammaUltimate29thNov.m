    % NOTE: nSteps=32, all 4 guns, takes about 30 min per repetition

    sca;
    close all;
    clearvars;
    Screen('Preference', 'SkipSyncTests', 0);
    startStr=datestr(now);
    PsychDataPixx('Open'); % 
    PsychDataPixx('SetDummyMode', 0); % 0 is for normal DataPixx operation, 1 bypasses DataPixx
    PsychDefaultSetup(2);

    %%%%%%%%%%%% Choices %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    list = {'Check', 'Measurement'}; % don't change keyword order
    [indx, tf] = listdlg('ListString',list, 'SelectionMode','single');
    if indx == 1
        gammacheck = true;
        gammaName = 'GammaCheck';
    elseif indx == 2
        gammacheck = false;
        gammaName = 'GammaMeasure';
    end

    list = {'Mean Method', 'Not MM'}; % don't change keyword order
    [indx, tf] = listdlg('ListString',list, 'SelectionMode','single');
    if indx == 1
        meanMethod = true;
        methodName = 'Mean Method';
    elseif indx == 2
        meanMethod = false;
        methodName = '';
    end
    
    list = {'PR650','I1(XRITE)'};
    [indx, tf] = listdlg('ListString',list, 'SelectionMode','single');
    if indx == 1
        usingPR650Flag = true; 
        usingI1Flag = false;
        deviceName = 'PR650';
    elseif indx == 2
        usingPR650Flag = false;  
        usingI1Flag = true;
        I1('IsConnected'); %% NT added 23Nov2021
        I1('GetTriStimulus'); %% NT added 23Nov2021
        deviceName = 'I1';
    end

    % short (focus on center) or complete?
    list = {'Complete','Short'};
    [indx, tf] = listdlg('ListString',list, 'SelectionMode','single');
    if indx == 1
        complete = true; 
        typeName = 'Complete';
    elseif indx == 2
        complete = false;
        typeName = 'Short';
    end

    prompt = {'Repetition number:', 'Lab name:'};
    dlgtitle = 'Input';
    dims = [1 35];
    definput = {'1','NON3Dfrank'};
    answer = inputdlg(prompt,dlgtitle,dims,definput);
    nreps = str2num(answer{1});
    labName = answer{2};

    
    
    

  


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if nreps>1
        Speak('warning multiple repetitions')
    end
    nBitFlag=false ; % only if testing for 10 bits or more...
    stepsize=2^-11;  % only use this for nBit test   otherwise set to very large 2^100
    %  stepsize=2^-8;  % for debugging so can see what's up
    minGun=1;
    maxGun=4;  % normally 1 and 4 for 3 guns and white
    nSteps=50;  % actually will do nSteps+1, counting zero.  Normally this should be 16 or more (up to full resolution -- 1023, for example)
    % contrastList=[.2 .6 1.];  % must be nSteps+1 inlength if it is used!
    delayTime = 1; %adaptation time use 0 for debug and 10 for measurements
    randContrasts=false;  % will still do nSteps contr(asts, but the values will be chosen randomly
    global EXPWINDOW
    blankPix=200;         %  rectangular area where the test will appear defined by blankPix
    
    AssertOpenGL;

    % Set higher DebugLevel, so that you don't get all kinds of messages flashed
    % at you each time you start the experiment:
    olddebuglevel=Screen('Preference', 'VisualDebuglevel', 3);
    % rte: this sets the new screen preference to VisualDebuglevel=3, and
    % saves the original preference setting in olddebuglevel so it can be
    % restored at the end of this script.


    % prepare output matrix:
    % colHeaders = ['machine contrast', 'r', 'g', 'b', ...
    %     'quality 0=good',  'X', 'Y', 'Z', 'x','y']  % not currently using these
    nCols=14; % number of values to save in pData  NOW INCLUDING tempF!

    %trying to call this outside of the loop to better troubleshoot
    %I replaced PsychDatapixx calls with Datapixx calls (12:00 7/7/2020 -AN
    % Datapixx('Open');
    % selectedDevice = Datapixx('SelectDevice', 4);
    % isViewpixx = Datapixx('IsViewpixx');
    % isReady = Datapixx('IsReady');


    try
    % Enable unified mode of KbName, so KbName accepts identical key names on
        % all operating systems (not absolutely necessary, but good practice):
        KbName('UnifyKeyNames');  % shouldn't be necessary since did PsychDefaultSetup(2)
        KbCheck;
    %find screens
        screenNumber=max(Screen('Screens'));
        PsychImaging('PrepareConfiguration');
    % Require a 32 bpc float framebuffer: This would be the default anyway, but
    % just here to be explicit about it:
        PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');
    
    % Make sure we run with our default color correction mode for this test:
    % 'ClampOnly' is the default, but we set it here explicitely, so no state
    % from previously running scripts can bleed through:
    % % PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'ClampOnly');
        PsychImaging('AddTask', 'General', 'EnableDataPixxC48Output', 0); %added for Viewpixx compatibility 
        PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'LookupTable');% RTE 7-7-12:06
    %PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');
    %PsychImaging('AddTask','General','EnableBits++Color++Output',0);
    
    
    
    
    % Open a connection to Bits#/Display++. This will happen anyway when we
    % open the window but if we do it explicitly here, PTB will switch back
    % to the desktop friendly Bits++ Video mode when executing the command 
    % BitsPlusPlus('Close') at the end of the script.
    %OpenQ=BitsPlusPlus('OpenBits#', '/dev/cu.usbmodem72124141')  % specifying port is required since have PR650 driver loaded 
    % OpenQ=BitsPlusPlus('OpenBits#')
    % PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'LookupTable');
    %PsychImaging('AddTask','General','UseBits#');
    
    % BitsPlusPlus('SetColorConversionMode', 0);
    
    
        if gammacheck==true
                    meanfactor = 0.5;
                else
                    meanfactor = 0.6; % use .6 if not gamma checking, to approx get mean luminance
        end
        midGrey=meanfactor*[1 1 1];   %  use .6ish if not gamma corrected to start with 
        [EXPWINDOW, expWindowRect] = PsychImaging('OpenWindow', screenNumber,midGrey);
    % [EXPWINDOW, expWindowRect] = PsychImaging('OpenWindow', screenNumber,midGrey, [0 0 2*1080 800]);  % mid gray but Gamma correction
    % [originalGammaClut,dacbits,reallutsize]=Screen('ReadNormalizedGammaTable',EXPWINDOW);
        originalGammaClut=repmat((linspace(1,1024,1024)'),1,3)/1024;
        dacbits=10;
        Screen('Flip', EXPWINDOW);
       
    % specify blend mode for anti-aliasing...  NOT SURE about this
        Screen('BlendFunction', EXPWINDOW, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
        HideCursor

        testpatch=CenterRect([ 0 0 blankPix blankPix], expWindowRect); % rte 7-10-20
    % testpatch=testpatch+[0 (960-expWindowRect(RectBottom))/2 0 (960-expWindowRect(RectBottom)/2) ]  % center at old position
    % testpatch=[(1080/2-blankPix/2-100) (960/2-blankPix/2-50) (1080/2+blankPix/2-50) (960/2 +blankPix/2) ]  % brute force it to old position
    % can't seem to get this exactly right so screw it!
     %disable output of keypresses to Matlab. !!!use with care!!!!!!
        %if the program gets stuck you might end up with a dead keyboard
        %if this happens, press CTRL-C to reenable keyboard handling -- it is
        %the only key still recognized.
        ListenChar(2);
        Screen('FillRect', EXPWINDOW,midGrey, expWindowRect);
        Screen('FillRect', EXPWINDOW, [0 0 0], testpatch);  % for line up
        Screen('Flip', EXPWINDOW);
        
        %  %  turn on PR650 no more than 5 secs before initialization, otherwise
    %  it will revert to manual mode
        if usingPR650Flag==true
        %  CMCheckInit(1, 'USB0') ; % this initializes the serial port use with
        %  pr650
         % CMCheckInit(1, '/dev/cu.usbserial')
        %  CMCheckInit(1, 'ACM0')
           CMCheckInit(1)
        % CMCheckInit(5)   % this is for the PR670  (frances)
        end
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %this is where we will load in our gamma table\          % IMPORTANT NOTE:
    %                        may need to try different sized normalized gamma
    %                        tables!  using the biggest possible here
    %                        now...rte10/14/16
    
        if gammacheck==true
            format long g
            gammaTable=dlmread('invGammaviewNON3DFrank17Dec21.csv');
            gammaTable=gammaTable ./ [max(gammaTable(:,1)) max(gammaTable(:,2)) max(gammaTable(:,3))]; % normalize it
            PsychColorCorrection('SetLookupTable', EXPWINDOW, gammaTable);
        else
            PsychColorCorrection('SetLookupTable', EXPWINDOW, originalGammaClut);  % use linear clut otherwise
        end
    
        Screen('FillRect', EXPWINDOW, midGrey,  expWindowRect);  % set to mean field after gamma (potentially)
        Screen('Flip', EXPWINDOW);  %  
    
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 
    % allow for lineup of PR650
        Screen('FillRect', EXPWINDOW, [0 0 0],  testpatch);  % set to mean field after gamma (potentially)
        Screen('Flip', EXPWINDOW);  %  
        Speak('Press y to go on')
        while 1                 % wait here until 'Y' pressed
        [a,b,keyCode] = KbCheck;
            if keyCode(KbName('Y'))
                break;
            end
        end
        feedBeep(1);
        WaitSecs(6);
        feedBeep(1);
    % %%%%%%% for debugging set these here to constant so don't need to hook up
    % the PR650.  (comment out the similar lines in the loop below)
        if usingPR650Flag==false
            xyzmeas=-999*[1 1 1];qual=-999;         % get XYZ and quality code
            xyzmeas=xyzmeas';
            xyChrom=[xyzmeas(1)/sum(xyzmeas) xyzmeas(2)/sum(xyzmeas)];
        end
    % %%%%%%%%%%
        testDirection=[ 0 0 0]; % just for debugging
        patchMat=zeros(blankPix, blankPix, 3); % 
        patchMat=double(patchMat);
    
    % now have 3 nested loops:
    % outer is repetitions, middle is guns, inner is contrast
    
    % here make the list of contrasts and guns we will use in random order!
        
        if complete == 1
            cons = [0:1/nSteps:1];
        elseif complete == 0
            cons=[0, .1, .2, .3, .35, .4, .45, .475, .5, .525, .55, .6, .65, .7, .8, .85, .9, .95, 1]; %% NT updated 27Nov2021
        end
        
        
        
        
        for repetition=1:nreps
            redRows=[];
            greRows=[];
            bluRows=[];
            whiRows=[];
            counter=1;   % using counter makes things simpler
    
            whenStr=datestr(now);

            OutFileName = strcat(labName,deviceName,gammaName,methodName,typeName, whenStr,'.csv');

            conOrder=randperm(length(cons), length(cons));
            for conCounter=1:length(conOrder) %default i=1, if modified this is to measure only a range in the curve 'i=(nSteps -16):nSteps+1'
                gunOrder=randperm(4);
                contrastVal=cons(conOrder(conCounter));  
                for gunCount=1:4 % modulate guns; if only want white, gun=4:4
                    gun=gunOrder(gunCount);  % do guns in random order at one contrast
                    switch gun
                        case 1
                            redRows=cat(1, redRows,counter);
                        case 2
                            greRows=cat(1, greRows, counter);
                        case 3
                            bluRows=cat(1, bluRows, counter);
                        case 4
                            whiRows=cat(1,whiRows,counter);
                    end

                    if meanMethod==false
                        testDirection=[0 0 0]; % reset it  
                    else
                        testDirection=meanfactor* [1 1 1];  % set to midpoint if using meanMethod; 
                    end
        
                    if gun==4
                        testDirection=contrastVal*[1 1 1];  % use white for last
                    else
                        testDirection(gun)=contrastVal;
                    end

                    stimRGB=testDirection;  % keeping name stimRGB for compatibility

                    if meanMethod==true 
                        patchMat=meanfactor*ones(blankPix, blankPix, 3);
                    else 
                        patchMat=zeros(blankPix, blankPix, 3);
                    end

                    if gun==4
                        patchMat(:,:,1)=stimRGB(1);
                        patchMat(:,:,2)=stimRGB(2);
                        patchMat(:,:,3)=stimRGB(3);
                    else
                        patchMat(:,:,gun)=stimRGB(gun);
                    end

                    patchMat=double(patchMat);
                    myTexture=Screen('MakeTexture',EXPWINDOW,patchMat, [],[],2);  % the final '2' is for high-resolution intensities; see Bits# manual p 82
                    Screen('DrawTexture', EXPWINDOW, myTexture, [],testpatch);  % put it explicitly to testpatch so it won't necessarily be centered!
                    Screen('DrawTexture', EXPWINDOW, myTexture);  

                    presentTime=Screen('Flip', EXPWINDOW);  %  start time  -- not needed here
                    WaitSecs(1.5);
        %         %%%%%%%%%%%%%%% PR650 READING DONE HERE
                % DON'T USE THIS SECTION IFF NOT USING PR650 (ie, for debugging )
                    if usingPR650Flag==true        %
                        xyzmeas=[-999 -999 -999]'; % in case it doesn't measure, still can keep going
                        [xyzmeas,qual]=myPR655measxyz;          % get XYZ and quality code
                        xyzmeas=xyzmeas';
                        xyChrom=[xyzmeas(1)/sum(xyzmeas)   xyzmeas(2)/sum(xyzmeas)];
                        WaitSecs(1)
                    end
                %%%%%%%%%%%%%%% PR650 READING DONE HERE
                
                    if usingI1Flag==true        %
                        XX=I1('GetTriStimulus');
                        WaitSecs(1);
                    end
                
                
                %%%%%%%%%%  GET TEMPERATURE HERE %%%%%%%%%%%%%%%%%%%%%
                    Datapixx('RegWrRd'); % Nov 30th added
                    tempFarenheit = Datapixx('GetTempFarenheit');
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                    xtime=clock;
        %         outputData(counter,:)=[contrastVal, stimRGB(1), stimRGB(2), stimRGB(3),qual, xyzmeas(1), xyzmeas(2), xyzmeas(3),xyChrom(1),xyChrom(2)];  %#ok<SAGROW> % let it print?  replace 'pi' with PR650 reading
                    if usingI1Flag==true
                       outputData(counter,:)=[contrastVal, stimRGB(1), stimRGB(2), stimRGB(3),qual, xyzmeas(1), xyzmeas(2), xyzmeas(3), xyChrom(1), xyChrom(2), tempFarenheit, XX(1), XX(2), XX(3)]; 
                    else
                       outputData(counter,:)=[contrastVal, stimRGB(1), stimRGB(2), stimRGB(3),qual, xyzmeas(1), xyzmeas(2), xyzmeas(3), xyChrom(1), xyChrom(2), tempFarenheit];
                    end

                    counter=counter+1;  % this allows for multiple repetitions, only using 1  gun, etc.
        %      
        %         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               %  
               %  no need to wait around if using PR650
        %        if usingPR650Flag==false
        %            feedBeep(1);WaitSecs(.1)
        %            Speak(num2str(i))
        % %            KbStrokeWait(-1);
        %                Speak('Press y')
        %                 while 1                 % wait here until 'Y' pressed
        %                 [a,b,keyCode] = KbCheck;
        %                     if keyCode((KbName('Y')))
        %                         break;
        %                     end
        %                 end
        %                 
        %        end  % end if for pr650 flag
        %        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % Screen('Close', patchTexture);          % I think this should be done...?
                    feedBeep(0);
                end  % end of gun loop
            
            end % contrast loop
            WaitSecs(1);
            % here, reorganize the data into gun blocks, sorted by contrast
            reds=sortrows(outputData(redRows,:),1);
            gres=sortrows(outputData(greRows,:),1);
            blus=sortrows(outputData(bluRows,:),1);
            whis=sortrows(outputData(whiRows,:),1);
          
            outputdata=cat(1,reds,gres,blus,whis) ; % now they are grouped for output.
        
            % here save the data 
            writematrix(outputdata, OutFileName);
            if repetition == 1
                saveTemp = outputdata;
            end
        end % repetition loop
    
    
        
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        FlushEvents('keyDown');	% discard all the chars from the Event Manager queue.
        PsychColorCorrection('SetLookupTable', EXPWINDOW, originalGammaClut);  % put back original linear gamma
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% output the readings to a text file
    % if we are really measuring
    %         if usingPR650Flag==true
    %                 whenStr=datestr(now);
    %                 OutFileName = strcat('frank','Gamma','CheckMeanMethod', whenStr,'.tsv');    % create the new file name as a concantenation
    %                             % of the string 'gammaMeas' and the current date and time
    %                 fileId = fopen(OutFileName, 'w');              % Open file to write
    %                 tabsOut = repmat('%f\t',1,(nCols-1));             % will put a tab after each floating
    %                                                             % point except last
    %                 % fprintf(fid,[tabsOut,'%s\n'],colHeaders)        % first put in the header
    %                 % text  FIX THIS LATER
    % 
    %                 for row=1:size(outputData,1)
    %                     fprintf(fileId,[tabsOut,'%f\n'],outputData(row,:));  % use fprintf to write data file
    %                 end                                         % the \n is a "newline" or return
    %                 fclose(fileId);
    %         end
    % %%%%%%%%%%%%%%%%%%%%%%%
    
    %  plot the measurements
    
                
                
       
    % 
    
                
                
        ListenChar(0);
        %return to olddebuglevel
        Screen('Preference', 'VisualDebuglevel', olddebuglevel);
    %     Screen('LoadNormalizedGammaTable', EXPWINDOW, originalGammaClut);  % put it back the way it was
        
        Screen('FillRect', EXPWINDOW, [0 0 0], expWindowRect);  % black the screen and wait here until Y is pressed
        Screen('Flip', EXPWINDOW);
        
        ShowCursor;
        sca
        Screen('CloseAll'); %or sca
        Datapixx('Close');
        IOPort('CloseAll');
        
        % If we are doing gamma check then plot the results.
        if gammacheck == 1
            % make sure you only do one repetition...
            gammaCheckResidual();
        elseif gammacheck == 0
            % if measurements, you can choose several measurements to plot
            % together, input required
            % Nov 18th 2021 added
            plotMultipleMeasurementsTogether();
        end
        

        

    catch
        % This section is executed only in case an error happens in the
        % experiment code implemented between try and catch...

        ListenChar(0);

        %output the error message
        ShowCursor;
        Screen('CloseAll'); %or sca
        Datapixx('Close');
        psychrethrow(psychlasterror);
    end
