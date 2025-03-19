clear; clc; close all; warning('off');

%% 参数配置区域（宏定义）
NUM_UAV = 20;             % 无人机数量
MAP_SIZE = 100;           % 地图大小（正方形区域边长）
CENTER_POSITION = [50, 50, 15]; % 环形编队的中心坐标 (x, y, z)
CENTER_RADIUS = 45;       % 环形编队的半径
CIRCLE_COLOR = [200, 200, 200]/255; % 目标圆颜色（默认淡灰色）
EXTRA_DISPLAY_MARGIN = 20; % 额外显示范围边距

% 势场参数
SAFE_DISTANCE = 5;        % 无人机之间的安全距离
LEADER_ATTRACT = 5;       % 领导者吸引力增益
FOLLOWER_ATTRACT = 3;     % 跟随者吸引力增益
K_REPULSE = 1;            % 避碰斥力增益
MAX_VELOCITY_LEADER = 3;  % 领导者最大速度
MAX_VELOCITY_FOLLOWER = 2;% 跟随者最大速度

% 动画和仿真参数
TIME_STEP = 0.1;          % 时间步长（影响无人机移动速度）
MAX_ITERATIONS = 500;     % 最大迭代次数
PAUSE_TIME = 0.05;        % 每步动画的暂停时间（影响动画播放速度）

% 收敛条件
POSITION_THRESHOLD = 0.2; % 位置误差阈值（无人机距离目标点的范围）

% GIF 文件保存路径
GIF_FILENAME = 'ring_uav_formation_3D.gif';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 初始化无人机的位置、速度和轨迹
position = cell(NUM_UAV, 1); % 无人机位置 (x, y, z)
velocity = zeros(NUM_UAV, 3); % 无人机速度初始化为零 (vx, vy, vz)
trajectories = cell(NUM_UAV, 1); % 起飞阶段的轨迹
formation_trajectories = cell(NUM_UAV, 1); % 编队阶段的轨迹
for i = 1:NUM_UAV
    % 随机生成初始位置（范围在地图内）
    init_position = [rand(1, 2) * MAP_SIZE - MAP_SIZE / 2 + CENTER_POSITION(1:2), 0]; % 初始 z=0
    position{i} = init_position;
    trajectories{i} = init_position; % 初始化起飞阶段轨迹
end

% 初始化距离记录
leader_distances = zeros(MAX_ITERATIONS, NUM_UAV - 1);
%% 创建保存帧的父目录和子目录

parent_dir = 'uav_ring_formation3D'; % 父目录
if ~exist(parent_dir, 'dir') % 如果父目录不存在，则创建
    mkdir(parent_dir);
end
frame_dirs = dir(fullfile(parent_dir, 'frames_*')); % 查找以 frames_ 开头的文件夹
frame_count = numel(frame_dirs); % 获取现有子文件夹的数量
new_frame_dir = fullfile(parent_dir, sprintf('frames_%d', frame_count + 1)); % 创建新的子文件夹名称
mkdir(new_frame_dir); % 创建新文件夹
%% 起飞动画
figure('Position', [100, 100, 1000, 800]);
% set(gcf,'defaultLegendAutoUpdate','off');

legend_handle = [];
for t = 1:30 % 起飞阶段，30步
    clf;
    theta = linspace(0, 2 * pi, 100);
    x_circle = CENTER_RADIUS * cos(theta) + CENTER_POSITION(1);
    y_circle = CENTER_RADIUS * sin(theta) + CENTER_POSITION(2);
    z_circle = ones(size(x_circle)) * CENTER_POSITION(3);
    plot3(x_circle, y_circle, z_circle, 'color', CIRCLE_COLOR, 'LineWidth', 1.5,'DisplayName','目标圆'); % 目标圆
    hold on;
    % 绘制地面标记（无人机初始点）
    for i = 1:NUM_UAV
        if i==1
            plot3(position{i}(1), position{i}(2), 0, 'ks', 'MarkerSize', 6, 'MarkerFaceColor', 'k','DisplayName','地面起点'); % 地面起点
        else
            plot3(position{i}(1), position{i}(2), 0, 'ks', 'MarkerSize', 6, 'MarkerFaceColor', 'k','HandleVisibility','off');
        end
        
    end
    
    % 更新无人机位置
    for i = 1:NUM_UAV
        % 起飞逻辑：从地面（z=0）缓慢上升到 CENTER_POSITION(3)
        z_increment = CENTER_POSITION(3) / 30; % 每步的 z 增量
        position{i}(3) = position{i}(3) + z_increment;
        trajectories{i} = [trajectories{i}; position{i}]; % 记录起飞轨迹

        % 绘制无人机
        if i == 1
            plot_leader = plot3(position{i}(1), position{i}(2), position{i}(3), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r','DisplayName', 'Leader'); % 领导者     
        else
            if i == 2 % 只为第一个 Follower 设置图例
                plot_follower = plot3(position{i}(1), position{i}(2), position{i}(3), 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'b', 'DisplayName', 'Follower'); % 跟随者
            else
                plot3(position{i}(1), position{i}(2), position{i}(3), 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'b','HandleVisibility', 'off'); % 跟随者
            end
        end
        
        % 绘制起飞轨迹为绿色
        traj = trajectories{i};
        plot3(traj(:, 1), traj(:, 2), traj(:, 3), 'g-', 'LineWidth', 1.0,'HandleVisibility','off'); % 起飞轨迹，绿色线
        
    end

    % 手动更新图例
    legend_handle = legend('show','AutoUpdate','off'); % 仅显示 Leader 和 Follower
    set(legend_handle, 'Location', 'northeast', 'FontSize', 18); % 调整图例位置

    % 控制显示区域
    axis equal;
    xlim([CENTER_POSITION(1) - MAP_SIZE / 2 - EXTRA_DISPLAY_MARGIN, CENTER_POSITION(1) + MAP_SIZE / 2 + EXTRA_DISPLAY_MARGIN]);
    ylim([CENTER_POSITION(2) - MAP_SIZE / 2 - EXTRA_DISPLAY_MARGIN, CENTER_POSITION(2) + MAP_SIZE / 2 + EXTRA_DISPLAY_MARGIN]);
    zlim([0, CENTER_POSITION(3) + 25]); % 增加 z 轴显示范围
    grid on;
    xlabel('x/m','FontSize', 16);
    ylabel('y/m','FontSize', 16);
    zlabel('z/m','FontSize', 16);
    title(sprintf('无人机起飞动画: Step %d', t),'FontSize', 20);

     % 保存帧到 GIF
    frame = getframe(gcf); % 捕获当前帧
    img = frame2im(frame);
    [imind, cm] = rgb2ind(img, 256);
    if t == 1
        imwrite(imind, cm, GIF_FILENAME, 'gif', 'LoopCount', Inf, 'DelayTime', PAUSE_TIME);
    else
        imwrite(imind, cm, GIF_FILENAME, 'gif', 'WriteMode', 'append', 'DelayTime', PAUSE_TIME);
    end
    
    % 保存帧到本地文件夹
    frame_filename = fullfile(new_frame_dir, sprintf('takeoff_%04d.png', t)); % 保存为PNG文件
    imwrite(img, frame_filename); % 写入帧到本地文件

    pause(PAUSE_TIME);
end

%% 动画仿真
for step = 1:MAX_ITERATIONS
    clf; % 清除当前绘图

    % 绘制目标圆形
    plot3(x_circle, y_circle, z_circle, 'color', CIRCLE_COLOR, 'LineWidth', 1.5,'DisplayName','目标圆'); % 目标圆
    hold on;

    all_converged = true; % 检查是否所有无人机收敛

    % 动态计算目标位置（确保均匀分布）
    for i = 1:NUM_UAV
        angle = 2 * pi * (i - 1) / NUM_UAV;
        target_position = CENTER_POSITION + [CENTER_RADIUS * cos(angle), CENTER_RADIUS * sin(angle), 0];

        % 势场计算
        if i == 1
            attract_force = LEADER_ATTRACT * (target_position - position{i});
            velocity(i, :) = velocity(i, :) + attract_force * TIME_STEP;
        else
            attract_force = FOLLOWER_ATTRACT * (target_position - position{i});
            repulse_force = [0, 0, 0];
            for j = 1:NUM_UAV
                if i ~= j
                    diff = position{i} - position{j};
                    distance = norm(diff);
                    if distance < SAFE_DISTANCE
                        repulse_force = repulse_force + K_REPULSE * (1 / distance - 1 / SAFE_DISTANCE) * (diff / distance^2);
                    end
                end
            end
            total_force = attract_force + repulse_force;
            velocity(i, :) = velocity(i, :) + total_force * TIME_STEP;
        end

        % 限制速度并更新位置
        speed = norm(velocity(i, :));
        if i == 1
            max_speed = MAX_VELOCITY_LEADER; % 领导者的最大速度
        else
         max_speed = MAX_VELOCITY_FOLLOWER; % 跟随者的最大速度
        end
        speed = norm(velocity(i, :));
        if speed > max_speed
            velocity(i, :) = velocity(i, :) * (max_speed / speed);
        end
        position{i} = position{i} + velocity(i, :) * TIME_STEP;
        formation_trajectories{i} = [formation_trajectories{i}; position{i}]; % 记录编队轨迹

        % 判断是否收敛
        if norm(position{i} - target_position) > POSITION_THRESHOLD
            all_converged = false;
        end

        % 绘制无人机
        if i == 1
            plot3(position{i}(1), position{i}(2), position{i}(3), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r','DisplayName','Leader');
        else
            if i == 2 % 只为第一个 Follower 设置图例
                plot_follower = plot3(position{i}(1), position{i}(2), position{i}(3), 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'b','DisplayName', 'Follower');
            else
                plot3(position{i}(1), position{i}(2), position{i}(3), 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'b','HandleVisibility','off');
            end
        end
        % 绘制轨迹
        traj = trajectories{i};
        plot3(traj(:, 1), traj(:, 2), traj(:, 3), 'g-', 'LineWidth', 1.0, 'HandleVisibility','off'); % 起飞轨迹
        formation_traj = formation_trajectories{i};
        plot3(formation_traj(:, 1), formation_traj(:, 2), formation_traj(:, 3), 'b-', 'LineWidth', 0.5, 'HandleVisibility','off'); % 编队轨迹
    end

    % 控制显示区域
    axis equal;
    xlim([CENTER_POSITION(1) - MAP_SIZE / 2 - EXTRA_DISPLAY_MARGIN, CENTER_POSITION(1) + MAP_SIZE / 2 + EXTRA_DISPLAY_MARGIN]);
    ylim([CENTER_POSITION(2) - MAP_SIZE / 2 - EXTRA_DISPLAY_MARGIN, CENTER_POSITION(2) + MAP_SIZE / 2 + EXTRA_DISPLAY_MARGIN]);
    zlim([0, CENTER_POSITION(3) + 25]);
    grid on;
    xlabel('x/m','FontSize', 16);
    ylabel('y/m','FontSize', 16);
    zlabel('z/m','FontSize', 16);
    title(sprintf('3D 环形编队仿真: Step %d', step),'FontSize', 20);
    
    % 手动更新图例
    legend_handle = legend('show','AutoUpdate','off'); % 仅显示 Leader 和 Follower
    set(legend_handle, 'Location', 'northeast', 'FontSize', 18); % 调整图例位置


    % 保存帧到 GIF
    frame = getframe(gcf); % 捕获当前帧
    img = frame2im(frame);
    [imind, cm] = rgb2ind(img, 256);
    if step == 1
        % imwrite(imind, cm, GIF_FILENAME, 'gif', 'LoopCount', Inf, 'DelayTime', PAUSE_TIME);
    else
        imwrite(imind, cm, GIF_FILENAME, 'gif', 'WriteMode', 'append', 'DelayTime', PAUSE_TIME);
    end
    
    % 保存帧到本地文件夹
    frame_filename = fullfile(new_frame_dir, sprintf('formation_%04d.png', step)); % 保存为PNG文件
    imwrite(img, frame_filename); % 写入帧到本地文件

    pause(PAUSE_TIME);

    % 如果所有无人机都收敛，结束仿真
    if all_converged
        disp('所有无人机已形成环形编队！');
        break;
    end
end