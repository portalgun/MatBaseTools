function n=Num.nSigDec(x)
% number of non-integer significicant figures
% e.i. like subtracting the integer then computing sig digits
n=Num.nSig(x);
intg=floor(log10(abs(x))+1);

n=n-intg;
n(n < 0)=0;
