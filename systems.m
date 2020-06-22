classdef systems < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        SystemsDynamicsProjectUIFigure  matlab.ui.Figure
        StateRepresentionMatricesPanel  matlab.ui.container.Panel
        ALabel                          matlab.ui.control.Label
        BLabel                          matlab.ui.control.Label
        CLabel                          matlab.ui.control.Label
        DLabel                          matlab.ui.control.Label
        A_state_field                   matlab.ui.control.Table
        B_state_field                   matlab.ui.control.Table
        C_state_field                   matlab.ui.control.Table
        D_state_field                   matlab.ui.control.Table
        InputFieldsPanel                matlab.ui.container.Panel
        CalcButton                      matlab.ui.control.Button
        RandomButton                    matlab.ui.control.Button
        EnterakvaluesEditFieldLabel     matlab.ui.control.Label
        A_field                         matlab.ui.control.EditField
        EnterbivaluesLabel              matlab.ui.control.Label
        B_field                         matlab.ui.control.EditField
        feedback                        matlab.ui.control.Label
        InputButtonGroup                matlab.ui.container.ButtonGroup
        UnitstepfunctionButton          matlab.ui.control.RadioButton
        UnitimpulsefunctionButton       matlab.ui.control.RadioButton
        CustomfuctionButton             matlab.ui.control.RadioButton
        utEditFieldLabel                matlab.ui.control.Label
        fn_field                        matlab.ui.control.EditField
        MyOwnSystemSimulatorLabel       matlab.ui.control.Label
        TabGroup                        matlab.ui.container.TabGroup
        InputOutputTab                  matlab.ui.container.Tab
        input_plot                      matlab.ui.control.UIAxes
        output_plot                     matlab.ui.control.UIAxes
        tab                             matlab.ui.container.Tab
        x1_plot                         matlab.ui.control.UIAxes
        x2_plot                         matlab.ui.control.UIAxes
        
    end
    properties (Access = private)
        a_values
        b_values
        a_1
        custom_fn
        fn
        tabs
        x_plots
        busy
        last_m
    end
    
    methods (Access = private)
        
        function calc_state_vars(app)
            a = app.a_values;
            b = app.b_values;
            m = length(a)-1;
            n = length(b);
            
            A_state = zeros(m,m-1);
            B_state = zeros(m,1);
            C_state = zeros(1,m);
            
            for i = 1:m
                for j = 1:m-1
                    if j == i - 1
                        A_state(i,j) = 1;
                    end
                end
            end
            
            A_state = [A_state -flip(a(2:end))'];
            bb = flip([b zeros(1,m-n+1)]);
            
            for i = 1:m
                B_state(i) = bb(end-i+1) - a(end-i+1)*bb(1);
            end
            
            C_state(end) = 1;
            C_state = C_state / app.a_1;
            D_state = bb(1) / app.a_1 ;
            
            app.A_state_field.Data = A_state;
            app.B_state_field.Data = B_state;
            app.C_state_field.Data = C_state;
            app.D_state_field.Data = D_state;
        end
        
        function draw_ouput(app)
            
            m = length(app.a_values)-1;
            nb = length(app.b_values);
            t_sim = 30;
            
            %% Draw Input
            t = -1:0.01:10;
            step = t > 0;
            impulse = t == 0;
            app.input_plot.YLim = [0 1.2];
            
            if app.UnitstepfunctionButton.Value
                plot(app.input_plot,t, step);
            elseif app.custom_fn
                t = 0:0.1:t_sim;
                try
                    ft = app.fn(t);
                    if length(ft) == 1
                        ft = polyval(ft(1), t);
                    end
                catch
                    app.feedback.Text = ['Please use scaler operator. eg: .' char('*')  '   .' char('^') ];
                    app.feedback.FontColor = [1 0 0];
                    return
                end
                plot(app.input_plot,t, ft);
                ylim(app.input_plot, 'auto');
            else
                plot(app.input_plot,t, impulse);
            end
            
            %% Calculate Output & State Variables 
            dt = 0.01;
            t = 0:dt:t_sim;
            n = length(t);
            x = zeros(m,n);
            bb = [app.b_values zeros(1,m-nb+1)];
            
            % using Runga-Kutta Method
            for i = 2:n
                k1 = dt*app.evaluate_t(x(:,i-1), t(i-1));
                k2 = dt*app.evaluate_t(x(:,i-1) + 0.5*k1, t(i-1)+dt/2);
                k3 = dt*app.evaluate_t(x(:,i-1) + 0.5*k2, t(i-1)+dt/2);
                k4 = dt*app.evaluate_t(x(:,i-1) + k3, t(i-1)+dt);
                x(:,i) = x(:,i-1) + (1/6)*(k1+2*k2+2*k3+k4);
            end
            
            y = (x(m,:)+(bb(end)*app.fn(t))) / app.a_1;
            
            % calculate the impu;se response 
            % using the dervative of step response
            if app.UnitimpulsefunctionButton.Value
                x_impulse = zeros(m,n);
                y_impulse = zeros(n,1) ;
                
                for j = 1:m
                    for i =2:n-1
                        x_impulse(j,i) = (x(j,i+1)-x(j,i-1))/(2*dt);
                    end
                    x_impulse(j,1) = (x(j,2)-x(j,1))  /dt;
                    x_impulse(j,n) = (x(j,n)-x(j,n-1))/dt;
                end
                
                for i =2:n-1
                    y_impulse(i) = (y(i+1)-y(i-1))/(2*dt);
                end
                y_impulse(1) = (y(2)-y(1))  /dt;
                y_impulse(n) = (y(n)-y(n-1))/dt;
                
                y = y_impulse;
                x = x_impulse;
            end
    
            %% Plot Output & State Variables 
            plot(app.output_plot, t, y);
           
            % Remove the last tabs
            for i = 1:round(app.last_m/2)
                app.tabs(i).Parent = [];
            end

            app.last_m = m;
            app.tab.Parent = [];
            
            % Create new tabs
            for i = 1:round(m/2)
                app.tabs(i) =  uitab(app.TabGroup);
                app.tabs(i).Title = ['State Variables x' num2str(i*2 - 1) '(t)/x' num2str(i*2) '(t)'];
            end
            
            % Create new plots
            for i = 1:m
                app.x_plots(i) = uiaxes(app.tabs(round(i/2)));
                title(app.x_plots(i), ['x' num2str(i) '(t)']);
                xlabel(app.x_plots(i), 'Time(t)');
                ylabel(app.x_plots(i), ['x' num2str(i) '(t)']);
                app.x_plots(i).XGrid = 'on';
                app.x_plots(i).YGrid = 'on';
                
                if rem(i,2)
                    app.x_plots(i).Position =   [1 14 405 328];
                else
                    app.x_plots(i).Position = [421 14 542 328];
                end
            end
            
            drawnow; pause(0.01);
            
            % draw state variables
            try
                for i = 1:m
                    plot(app.x_plots(i), t, x(i,:));
                end
            catch
                disp('state variables plot error')
            end
        end
        
        function result = evaluate_t(app, x, t)
            try
                % x' = A*x + B*u 
                result = app.A_state_field.Data*x + app.B_state_field.Data*app.fn(t);
            catch
                disp('Error in the evaluate function')
            end
        end
    end
    
    methods (Access = private)
        
        % Code that executes after component creation
        function startupFcn(app)
            try
                app.busy = 0;
                app.last_m = 0;
                
                app.fn_field.Visible = 'off';
                
                app.x_plots = [app.x1_plot];
                app.tabs = [app.tab];
                
                app.fn = @(t)1;
            catch
                disp('Error: in the startup function, please restart the app')
            end
        end
        
        % Button pushed function: CalcButton
        function SimulateButtonPushed(app, event)
            % check if there any pending simultion
            if app.busy
                app.feedback.Text = 'Please wait until the current simulation ends';
                app.feedback.FontColor = [1 0 0];
                return
            end
            
            app.busy = 1;
            app.feedback.Text = ['Running'];
            app.feedback.FontColor = [0 0.5 0];
            
            pause(0.01); drawnow;
            app.a_values = str2num(app.A_field.Value);
            app.b_values = str2num(app.B_field.Value);
            m = length(app.a_values);
            n = length(app.b_values);
            
            % check the data is vaild
            if m >= n && m > 1 && n > 0 && app.a_values(1) ~= 0
                try
                    % check if the input function is valid
                    if app.CustomfuctionButton.Value
                        app.fn = str2func(['@(t)' app.fn_field.Value]);
                        x = app.fn(1);
                    end
                catch
                    app.feedback.Text = 'Error in the input function';
                    app.feedback.FontColor = [1 0 0];
                    app.busy = 0;
                    return
                end
                
                % normalize the inputs & simulate the system
                app.a_1 =  app.a_values(1);
                app.a_values = app.a_values / app.a_1;
                app.calc_state_vars();
                app.draw_ouput();
            
            else
                app.feedback.Text = 'Error in input, check the data again';
                app.feedback.FontColor = [1 0 0];
                app.busy = 0;
                return
            end
            
            pause(0.01); drawnow;
            
            app.busy = 0;
            app.feedback.Text = '';
        end
        
        function RandomButtonPushed(app, event)
            % Check if there any pending simultion
            if app.busy
                app.feedback.Text = ['Please wait until the current simulion ends'];
                app.feedback.FontColor = [1 0 0];
                return
            end
            
            % Generate random numbers
            max_order = 5;
            max_value = 20;
            m = round(2+max_order*rand);
            n = round(2+max_order*rand);
            if n > m
                n = m;
            end
            app.A_field.Value = num2str(1+round(rand(1,m)*max_value));
            app.B_field.Value = num2str(1+round(rand(1,n)*max_value));
           
            app.SimulateButtonPushed();
        end
        
        % Selection changed function: InputButtonGroup
        function InputButtonGroupSelectionChanged(app, event)
            if app.CustomfuctionButton.Value
                app.custom_fn = 1;
                app.fn_field.Visible = 'on';
                app.utEditFieldLabel.Visible = 'on';
            else
                app.custom_fn = 0;
                app.fn = @(t)1;
                app.fn_field.Visible = 'off';
                app.utEditFieldLabel.Visible = 'off';
            end
        end
    end
    
    % App initialization and construction
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            
            % Create SystemsDynamicsProjectUIFigure
            app.SystemsDynamicsProjectUIFigure = uifigure;
            app.SystemsDynamicsProjectUIFigure.Position = [100 100 1029 643];
            app.SystemsDynamicsProjectUIFigure.Name = 'Systems Dynamics Project';
            
            % Create StateRepresentionMatricesPanel
            app.StateRepresentionMatricesPanel = uipanel(app.SystemsDynamicsProjectUIFigure);
            app.StateRepresentionMatricesPanel.BorderType = 'none';
            app.StateRepresentionMatricesPanel.TitlePosition = 'centertop';
            app.StateRepresentionMatricesPanel.Title = 'State Represention Matrices';
            app.StateRepresentionMatricesPanel.Position = [446 394 558 205];
            
            % Create ALabel
            app.ALabel = uilabel(app.StateRepresentionMatricesPanel);
            app.ALabel.Position = [17 118 25 15];
            app.ALabel.Text = 'A';
            
            % Create BLabel
            app.BLabel = uilabel(app.StateRepresentionMatricesPanel);
            app.BLabel.Position = [359 118 25 15];
            app.BLabel.Text = 'B';
            
            % Create CLabel
            app.CLabel = uilabel(app.StateRepresentionMatricesPanel);
            app.CLabel.Position = [17 29 25 15];
            app.CLabel.Text = 'C';
            
            % Create DLabel
            app.DLabel = uilabel(app.StateRepresentionMatricesPanel);
            app.DLabel.Position = [359 29 25 15];
            app.DLabel.Text = 'D';
            
            % Create A_state_field
            app.A_state_field = uitable(app.StateRepresentionMatricesPanel);
            app.A_state_field.ColumnName = '';
            app.A_state_field.RowName = {};
            app.A_state_field.Position = [41 85 302 90];
            
            % Create B_state_field
            app.B_state_field = uitable(app.StateRepresentionMatricesPanel);
            app.B_state_field.ColumnName = '';
            app.B_state_field.RowName = {};
            app.B_state_field.Position = [383 85 140 90];
            
            % Create C_state_field
            app.C_state_field = uitable(app.StateRepresentionMatricesPanel);
            app.C_state_field.ColumnName = '';
            app.C_state_field.RowName = {};
            app.C_state_field.Position = [41 21 302 37];
            
            % Create D_state_field
            app.D_state_field = uitable(app.StateRepresentionMatricesPanel);
            app.D_state_field.ColumnName = '';
            app.D_state_field.RowName = {};
            app.D_state_field.Position = [383 21 140 37];
            
            % Create InputFieldsPanel
            app.InputFieldsPanel = uipanel(app.SystemsDynamicsProjectUIFigure);
            app.InputFieldsPanel.BorderType = 'none';
            app.InputFieldsPanel.TitlePosition = 'centertop';
            app.InputFieldsPanel.Title = 'Input Fields';
            app.InputFieldsPanel.Position = [41 394 373 204];
            
            % Create CalcButton
            app.CalcButton = uibutton(app.InputFieldsPanel, 'push');
            app.CalcButton.ButtonPushedFcn = createCallbackFcn(app, @SimulateButtonPushed, true);
            app.CalcButton.Position = [219 65 99 29];
            app.CalcButton.Text = 'Simulate';
            
            % Create RandomButton
            app.RandomButton = uibutton(app.InputFieldsPanel, 'push');
            app.RandomButton.ButtonPushedFcn = createCallbackFcn(app, @RandomButtonPushed, true);
            app.RandomButton.Position = [219 30 99 29];
            app.RandomButton.Text = 'Random';
            
            % Create EnterakvaluesEditFieldLabel
            app.EnterakvaluesEditFieldLabel = uilabel(app.InputFieldsPanel);
            app.EnterakvaluesEditFieldLabel.HorizontalAlignment = 'right';
            app.EnterakvaluesEditFieldLabel.Position = [31 156 100 15];
            app.EnterakvaluesEditFieldLabel.Text = 'Enter a(k)  values';
            
            % Create A_field
            app.A_field = uieditfield(app.InputFieldsPanel, 'text');
            app.A_field.FontSize = 14;
            app.A_field.Position = [147 152 162 22];
            app.A_field.Value = '[am am-1 am-2 ... a0]';
            
            % Create EnterbivaluesLabel
            app.EnterbivaluesLabel = uilabel(app.InputFieldsPanel);
            app.EnterbivaluesLabel.HorizontalAlignment = 'right';
            app.EnterbivaluesLabel.Position = [31 123 100 15];
            app.EnterbivaluesLabel.Text = 'Enter b(i)  values ';
            
            % Create B_field
            app.B_field = uieditfield(app.InputFieldsPanel, 'text');
            app.B_field.FontSize = 14;
            app.B_field.Position = [147 119 162 22];
            app.B_field.Value = '[b0 b1 b2 ... bn]';
            
            % Create feedback
            app.feedback = uilabel(app.InputFieldsPanel);
            app.feedback.HorizontalAlignment = 'center';
            app.feedback.FontSize = 14;
            app.feedback.FontWeight = 'bold';
            app.feedback.FontColor = [1 0 0];
            app.feedback.Position = [1 97 373 18];
            app.feedback.Text = '';
            
            % Create InputButtonGroup
            app.InputButtonGroup = uibuttongroup(app.InputFieldsPanel);
            app.InputButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @InputButtonGroupSelectionChanged, true);
            app.InputButtonGroup.BorderType = 'none';
            app.InputButtonGroup.Title = 'Input';
            app.InputButtonGroup.Position = [31 3 154 95];
            
            % Create UnitstepfunctionButton
            app.UnitstepfunctionButton = uiradiobutton(app.InputButtonGroup);
            app.UnitstepfunctionButton.Text = 'Unit step function';
            app.UnitstepfunctionButton.Position = [11 50 116 15];
            app.UnitstepfunctionButton.Value = true;
            
            % Create UnitimpulsefunctionButton
            app.UnitimpulsefunctionButton = uiradiobutton(app.InputButtonGroup);
            app.UnitimpulsefunctionButton.Text = 'Unit impulse function';
            app.UnitimpulsefunctionButton.Position = [11 28 136 15];
            
            % Create CustomfuctionButton
            app.CustomfuctionButton = uiradiobutton(app.InputButtonGroup);
            app.CustomfuctionButton.Text = 'Custom fuction';
            app.CustomfuctionButton.Position = [11 6 103 15];
            
            % Create utEditFieldLabel
            app.utEditFieldLabel = uilabel(app.InputFieldsPanel);
            app.utEditFieldLabel.HorizontalAlignment = 'right';
            app.utEditFieldLabel.Visible = 'off';
            app.utEditFieldLabel.Position = [180 15 36 15];
            app.utEditFieldLabel.Text = 'u(t) = ';
            
            % Create fn_field
            app.fn_field = uieditfield(app.InputFieldsPanel, 'text');
            app.fn_field.FontSize = 14;
            app.fn_field.Visible = 'off';
            app.fn_field.Position = [219 5 99 22];
            
            % Create MyOwnSystemSimulatorLabel
            app.MyOwnSystemSimulatorLabel = uilabel(app.SystemsDynamicsProjectUIFigure);
            app.MyOwnSystemSimulatorLabel.FontSize = 26;
            app.MyOwnSystemSimulatorLabel.FontWeight = 'bold';
            app.MyOwnSystemSimulatorLabel.FontAngle = 'italic';
            app.MyOwnSystemSimulatorLabel.FontColor = [0 0 1];
            app.MyOwnSystemSimulatorLabel.Position = [41 605 337 35];
            app.MyOwnSystemSimulatorLabel.Text = 'My Own System Simulator';
            
            % Create TabGroup
            app.TabGroup = uitabgroup(app.SystemsDynamicsProjectUIFigure);
            app.TabGroup.Position = [41 12 963 374]
            
            % Create InputOutputTab
            app.InputOutputTab = uitab(app.TabGroup);
            app.InputOutputTab.Title = 'Input/Output';
            
            % Create input_plot
            app.input_plot = uiaxes(app.InputOutputTab);
            title(app.input_plot, 'Input');
            xlabel(app.input_plot, 'Time(t)');
            ylabel(app.input_plot, 'u(t)');
            app.input_plot.XGrid = 'on';
            app.input_plot.YGrid = 'on';
            app.input_plot.Position = [1 14 405 328];
            
            % Create output_plot
            app.output_plot = uiaxes(app.InputOutputTab);
            title(app.output_plot, 'Output');
            xlabel(app.output_plot, 'Time(t)');
            ylabel(app.output_plot, 'y(t)');
            app.output_plot.XGrid = 'on';
            app.output_plot.YGrid = 'on';
            app.output_plot.Position = [421 14 542 328];
            
            % Create tab
            app.tab = uitab(app.TabGroup);
            app.tab.Title = 'State Variables x1(t)/x2(t)';
            
            % Create x1_plot
            app.x1_plot = uiaxes(app.tab);
            title(app.x1_plot, 'x1(t)')
            xlabel(app.x1_plot, 'Time(t)');
            ylabel(app.x1_plot, 'x1(t)');
            app.x1_plot.XGrid = 'on';
            app.x1_plot.YGrid = 'on';
            app.x1_plot.Position = [1 14 405 328];
            
            % Create x2_plot
            app.x2_plot = uiaxes(app.tab);
            title(app.x2_plot, 'x2(t)')
            xlabel(app.x2_plot, 'Time(t)');
            ylabel(app.x2_plot, 'x2(t)');
            app.x2_plot.XGrid = 'on';
            app.x2_plot.YGrid = 'on';
            app.x2_plot.Position = [421 14 542 328];
            
        end
    end
    
    methods (Access = public)
        % Construct app
        function app = systems
            createComponents(app)
            registerApp(app, app.SystemsDynamicsProjectUIFigure)
            runStartupFcn(app, @startupFcn)
            if nargout == 0
                clear app
            end
        end
        % Code that executes before app deletion
        function delete(app)
            delete(app.SystemsDynamicsProjectUIFigure)
        end
    end
end

