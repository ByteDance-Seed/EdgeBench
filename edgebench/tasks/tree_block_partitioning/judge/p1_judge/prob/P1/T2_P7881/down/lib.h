struct Data{
	unsigned short a,b,c,d;
	void operator*=(const Data &x);
	void clr();
};
void update(int x,int dim,Data d1,Data d2);
Data query(int x,int y);

