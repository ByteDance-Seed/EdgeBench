struct Data{
	unsigned short x1,x2,x3,x4;
	void add(const Data &a,const Data &b);
	void sub(const Data &a,const Data &b);
	void clr();
};
void solve(
	int n,
	int xy[][2],
	Data d[],
	int m,
	int abc[][3],
	int q,
	int lr[][2],
	Data ans[]);
