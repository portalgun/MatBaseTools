function img=vecs2img(PszXY,X,Y,Z)
gridVals=Set.distribute(1:PszXY(1),1:PszXY(2));
missing=~ismember(gridVals,[X,Y],'rows');
img=nan(fliplr(PszXY));
for i = 1:length(Z)
    img(Y(i),X(i))=Z(i);
end
