function make_placeholder(parent, title_txt, msg_txt)
%MAKE_PLACEHOLDER  Centered empty-state card shown in a Results panel before
%   any figures have been embedded: a full-size white panel (Tag
%   'placeholder', normalized units — follows the panel's size) holding a
%   grid that keeps the card centred.
ph = uipanel(parent,'Tag','placeholder','BorderType','none','BackgroundColor',[1 1 1], ...
    'Units','normalized','Position',[0 0 1 1]);
g = uigridlayout(ph, 'RowHeight',{'1x', 120, '1x'}, 'ColumnWidth',{'1x', 520, '1x'}, ...
    'Padding',[20 0 20 0], 'RowSpacing',0, 'ColumnSpacing',0, 'BackgroundColor',[1 1 1]);
card = uipanel(g,'BorderType','line','BackgroundColor',[0.93 0.91 0.87]);
card.Layout.Row = 2;  card.Layout.Column = 2;
if isprop(card,'BorderColor'), card.BorderColor = [0.81 0.73 0.57]; end
cg = uigridlayout(card, 'RowHeight',{6, 34, '1x'}, 'ColumnWidth',{'1x'}, ...
    'Padding',[0 8 0 0], 'RowSpacing',8, 'ColumnSpacing',0, 'BackgroundColor',[0.93 0.91 0.87]);
bar = uipanel(cg,'BorderType','none','BackgroundColor',[0.81 0.73 0.57]);
bar.Layout.Row = 1;  bar.Layout.Column = 1;
t = uilabel(cg,'Text',title_txt,'FontSize',20,'FontWeight','bold', ...
    'FontColor',[0.08 0.08 0.08],'HorizontalAlignment','center');
t.Layout.Row = 2;  t.Layout.Column = 1;
m = uilabel(cg,'Text',msg_txt,'FontSize',14,'FontColor',[0.45 0.45 0.45], ...
    'HorizontalAlignment','center','WordWrap','on','VerticalAlignment','top');
m.Layout.Row = 3;  m.Layout.Column = 1;
end
