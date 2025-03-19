clear; clc; close all; warning('off');

%% 参数配置区域（宏定义）
NUM_UAV = 20;             % 无人机数量
MAP_SIZE = 100;           % 地图大小（正方形区域边长）
CENTER_POSITION = [50, 50]; % 环形编队的中心坐标
CENTER_RADIUS = 45;       % 环形编队的半径
GIF_FILENAME = 'uav_ring_formation_2D_test.gif'; % 保存 GIF 的文件名
FRAME_DIR = 'frames/'; % 保存帧图像的文件夹

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
POSITION_THRESHOLD = 0.5; % 位置误差阈值
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 绘制目标圆形
theta = linspace(0, 2 * pi, 100);
x = CENTER_RADIUS * cos(theta) + CENTER_POSITION(1);
y = CENTER_RADIUS * sin(theta) + CENTER_POSITION(2);
figure;
plot(x, y, 'color', [96, 96, 96]/255, 'LineWidth', 1.5); % 绘制目标圆
hold on;
axis equal;
xlim([CENTER_POSITION(1) - MAP_SIZE / 2, CENTER_POSITION(1) + MAP_SIZE / 2]);
ylim([CENTER_POSITION(2) - MAP_SIZE / 2, CENTER_POSITION(2) + MAP_SIZE / 2]);
grid on;

%% 初始化无人机的位置、速度和轨迹
position = cell(NUM_UAV, 1); % 无人机位置
velocity = zeros(NUM_UAV, 2); % 无人机速度初始化为零
trajectories = cell(NUM_UAV, 1); % 记录每个无人机的轨迹
for i = 1:NUM_UAV
    % 随机生成初始位置（范围在地图内）
    init_position = CENTER_POSITION + rand(1, 2) * MAP_SIZE - MAP_SIZE / 2;
    position{i} = init_position;
    trajectories{i} = init_position; % 初始化轨迹
    plot(init_position(1), init_position(2), 'o', 'MarkerSize', 6);
end
hold on;

%% 禁用自动更新 legend
legend('AutoUpdate', 'off');
set(gcf, 'Units', 'normalized', 'OuterPosition', [0, 0, 1, 1]);
%% 创建新的保存帧目录
parent_dir = 'uav_ring_formation2D'; % 父目录
frame_dirs = dir(fullfile(parent_dir, 'frames_*')); % 查找以 frames_ 开头的文件夹
frame_count = numel(frame_dirs); % 获取现有子文件夹的数量
new_frame_dir = fullfile(parent_dir, sprintf('frames_%d', frame_count + 1)); % 创建新的子文件夹名称
mkdir(new_frame_dir); % 创建新文件夹

%% 动画仿真
frame_counter = 1; % 用于保存帧
legend_handle = [];
for step = 1:MAX_ITERATIONS
    clf; % 清除当前绘图
    plot(x, y, 'color', [96, 96, 96]/255, 'LineWidth', 1.5, 'DisplayName', '目标圆'); % 重绘目标圆
    hold on;

    all_converged = true; % 检查是否所有无人机收敛

    % 动态计算目标位置（确保均匀分布）
    for i = 1:NUM_UAV
        angle = 2 * pi * (i - 1) / NUM_UAV;
        target_position = CENTER_POSITION + CENTER_RADIUS * [cos(angle), sin(angle)];

        % 领导者逻辑
        if i == 1
            attract_force = LEADER_ATTRACT * (target_position - position{i});
            velocity(i, :) = velocity(i, :) + attract_force * TIME_STEP;
            speed = norm(velocity(i, :));
            if speed > MAX_VELOCITY_LEADER
                velocity(i, :) = velocity(i, :) * (MAX_VELOCITY_LEADER / speed);
            end
        else
            % 跟随者吸引力
            attract_force = FOLLOWER_ATTRACT * (target_position - position{i});
            % 避碰斥力
            repulse_force = [0, 0];
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
            speed = norm(velocity(i, :));
            if speed > MAX_VELOCITY_FOLLOWER
                velocity(i, :) = velocity(i, :) * (MAX_VELOCITY_FOLLOWER / speed);
            end
        end

        % 更新位置
        position{i} = position{i} + velocity(i, :) * TIME_STEP;
        trajectories{i} = [trajectories{i}; position{i}]; % 记录轨迹

        % 判断是否收敛
        if norm(position{i} - target_position) > POSITION_THRESHOLD
            all_converged = false;
        end

        % 绘制当前 UAV
        if i == 1
            plot(position{i}(1), position{i}(2), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r','DisplayName', 'Leader');
        else
            if i == 2
                plot(position{i}(1), position{i}(2), 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'b','DisplayName','Follower');
            else 
                plot(position{i}(1), position{i}(2), 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'b','HandleVisibility','off');
            end
        end

        % 绘制轨迹
        traj = trajectories{i};
        if i == 1
            plot(traj(:, 1), traj(:, 2), 'r-', 'LineWidth', 1.0, 'HandleVisibility','off'); % 领导者轨迹
        else
            plot(traj(:, 1), traj(:, 2), 'b-', 'LineWidth', 0.5, 'HandleVisibility','off'); % 跟随者轨迹
        end
    end
    
    % 手动更新图例
    legend_handle = legend('show','AutoUpdate','off'); % 仅显示 Leader 和 Follower
    set(legend_handle, 'Location', 'northeast', 'FontSize', 12); % 调整图例位置

    
    % 控制显示区域
    axis equal;
    xlim([CENTER_POSITION(1) - MAP_SIZE / 2, CENTER_POSITION(1) + MAP_SIZE / 2]);
    ylim([CENTER_POSITION(2) - MAP_SIZE / 2, CENTER_POSITION(2) + MAP_SIZE / 2]);
    grid on;
    xlabel('x/m');
    ylabel('y/m');
    title(sprintf('2D 环形编队仿真: Step %d', step));

    % 保存当前帧为 GIF
    frame = getframe(gcf);
    img = frame2im(frame);
    [imind, cm] = rgb2ind(img, 256);
    if step == 1
        imwrite(imind, cm, GIF_FILENAME, 'gif', 'Loopcount', inf, 'DelayTime', PAUSE_TIME);
    else
        imwrite(imind, cm, GIF_FILENAME, 'gif', 'WriteMode', 'append', 'DelayTime', PAUSE_TIME);
    end

    % 保存每一帧为图片文件
    frame_filename = fullfile(new_frame_dir, sprintf('frame_%04d.png', step));
    saveas(gcf, frame_filename);

    frame_counter = frame_counter + 1; % 更新帧计数器

    % 动画显示控制
    pause(PAUSE_TIME);

    % 如果所有无人机都收敛，结束仿真
    if all_converged
        disp('所有无人机已形成环形编队！');
        break;
    end
end

% 最终绘制完成的环形编队
for i = 1:NUM_UAV
    if i == 1
        plot(position{i}(1), position{i}(2), 'rx', 'MarkerSize', 10, 'LineWidth', 1.5);
    else
        plot(position{i}(1), position{i}(2), 'bx', 'MarkerSize', 10, 'LineWidth', 1.5);
    end
end

% 手动添加 legend，仅保留 Leader 和 Follower
plot(NaN, NaN, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', 'Leader UAV');
plot(NaN, NaN, 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'b', 'DisplayName', 'Follower UAV');
legend('Location', 'best'); % 仅显示指定的图例
hold off;
