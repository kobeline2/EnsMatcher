filePath = "\\10.244.3.104\homes\アンサンブル予測\Result\kaisekiNash_meanAccuracy_euclid.dat";
data = readmatrix(filePath);
figure
hold on
% for i = 1:length(data)
%     if data(i,1) < 0
%         scatter(data(i,1),data(i,2),72,'d','MarkerEdgeColor','r','MarkerFaceColor','r')
%     else
%         scatter(data(i,1),data(i,2),72,'d','MarkerEdgeColor','k','MarkerFaceColor','k')
%     end
% end
xline(0,'k--')
scatter(data(:,1),data(:,2),72,'d','MarkerEdgeColor','k','MarkerFaceColor','k')
hold off
xlim([-0.6,0.6])
xticks(-0.6:0.2:0.6)
ylim([0,0.4])
yticks(0:0.1:0.4)
fontsize(14,"points")
fontname("Arial")