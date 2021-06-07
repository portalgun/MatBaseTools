function [] = dimCombine(A1,A2,dim1,dim2)
a1=dimSliceSelect(A1,dim1,1:size(A1,dim1));
a2=dimSliceSelect(A2,dim2,1:size(A2,dim2));
