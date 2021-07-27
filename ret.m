function val=ret(ptr)
    if isa(ptr,'lib.pointer')
        val=get(ptr);
        val=ptr.Value;
    else
        val=ptr;
    end
end
