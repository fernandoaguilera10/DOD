function [points] = make_ABR_Template(t,abr, template_name)
% Plot a line
t = t';

figure;
plot(t, abr, 'k-', 'LineWidth', 2);
hold on;

% Prompt the user to select 10 points
points = zeros(10, 3);
point_names = {'P1', 'N1', 'P2', 'N2', 'P3', 'N3', 'P4', 'N4', 'P5', 'N5'};
for i = 1:10
    title(['Choose ', point_names{i}]);
    [x_i, y_i] = ginput(1); % Get the coordinates from user input
    [~, index] = min(abs(t - x_i) + abs(abr - y_i));
    x_i = t(index);
    y_i = abr(index);
    plot(x_i, y_i, 'ro', 'MarkerSize', 8); % Plot the selected point
    points(i, :) = [x_i, y_i, index]; % Store the point in the matrix
    text(x_i, y_i, point_names{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right'); % Label the point
end

hold off;

% % Display the matrix of points
% disp('Points:');
% disp(points);

% Save the points to a file
save(template_name, 'points','t','abr');

end

